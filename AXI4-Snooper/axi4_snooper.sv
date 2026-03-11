module axi4_snooper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n,

    // AXI4 Write Address Channel (AW)
    input logic                  awvalid,
    input logic                  awready,
    input logic [ADDR_WIDTH-1:0] awaddr,
    input logic [7:0]            awlen,
    input logic [2:0]            awsize,
    input logic [1:0]            awburst,

    // AXI4 Write Data Channel (W)
    input logic                  wvalid,
    input logic                  wready,
    input logic                  wlast,

    // Dedicated Error-Assertion Output Ports 
    output logic                 err_aw_handshake,
    output logic                 err_w_handshake,
    output logic                 err_4kb_boundary,
    output logic                 err_wlast_mismatch
);

    // =========================================================
    // RULE 1: HANDSHAKE VIOLATIONS (No dropped VALID signals)
    // =========================================================
    logic past_awvalid, past_awready;
    logic past_wvalid,  past_wready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            past_awvalid <= 0; past_awready <= 0;
            past_wvalid  <= 0; past_wready  <= 0;
        end else begin
            past_awvalid <= awvalid; past_awready <= awready;
            past_wvalid  <= wvalid;  past_wready  <= wready;
        end
    end

    // Error if VALID was high, READY was low, and VALID drops on the next cycle
    assign err_aw_handshake = (past_awvalid && !past_awready && !awvalid);
    assign err_w_handshake  = (past_wvalid  && !past_wready  && !wvalid);


    // =========================================================
    // RULE 2: 4KB BOUNDARY VIOLATION (Combinational Check)
    // =========================================================
    // AXI specifies bursts cannot cross a 4KB (0x1000) boundary.
    // Start Address + (Number of Beats * Bytes per Beat)
    logic [ADDR_WIDTH-1:0] total_burst_bytes;
    logic [ADDR_WIDTH-1:0] end_address;
    
    // awlen is number of beats - 1. awsize is bytes per beat (log2)
    assign total_burst_bytes = (awlen + 1) << awsize;
    assign end_address       = awaddr + total_burst_bytes;

    // If the 12th bit (4KB boundary) of the start address differs from the end address
    assign err_4kb_boundary = awvalid && (awaddr[12+:ADDR_WIDTH-12] != end_address[12+:ADDR_WIDTH-12]);


    // =========================================================
    // RULE 3: WLAST MISMATCH (Tracking outstanding bursts)
    // =========================================================
    logic [7:0] beat_counter;
    logic       write_in_progress;
    logic [7:0] expected_beats;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beat_counter      <= 0;
            write_in_progress <= 0;
            expected_beats    <= 0;
        end else begin
            // Track the AW request
            if (awvalid && awready) begin
                write_in_progress <= 1;
                expected_beats    <= awlen;
                beat_counter      <= 0;
            end
            
            // Track the W handshakes
            if (wvalid && wready && write_in_progress) begin
                if (beat_counter == expected_beats) begin
                    write_in_progress <= 0; // Burst complete
                end else begin
                    beat_counter <= beat_counter + 1;
                end
            end
        end
    end

    // Error if WLAST asserts too early or doesn't assert on the final beat
    assign err_wlast_mismatch = (wvalid && wready && write_in_progress) && 
                                ((wlast && (beat_counter != expected_beats)) || 
                                (!wlast && (beat_counter == expected_beats)));

    // =========================================================
    // SYSTEMVERILOG ASSERTIONS (SVA) - The V:5 Winning Move
    // =========================================================
    // SVA 1: AW Handshake Rule (VALID must not drop until READY)
    property p_aw_handshake;
        @(posedge clk) disable iff (!rst_n)
        (awvalid && !awready) |=> awvalid;
    endproperty
    ASSERT_AW_HANDSHAKE: assert property (p_aw_handshake)
        else $error("SVA VIOLATION: AWVALID dropped before AWREADY!");

    // SVA 2: W Handshake Rule
    property p_w_handshake;
        @(posedge clk) disable iff (!rst_n)
        (wvalid && !wready) |=> wvalid;
    endproperty
    ASSERT_W_HANDSHAKE: assert property (p_w_handshake)
        else $error("SVA VIOLATION: WVALID dropped before WREADY!");

    // SVA 3: 4KB Boundary Rule (Checks instantly on valid address)
    property p_4kb_boundary;
        @(posedge clk) disable iff (!rst_n)
        awvalid |-> (awaddr[12+:ADDR_WIDTH-12] == end_address[12+:ADDR_WIDTH-12]);
    endproperty
    ASSERT_4KB_BOUNDARY: assert property (p_4kb_boundary)
        else $error("SVA VIOLATION: Burst crosses 4KB boundary!");

endmodule
