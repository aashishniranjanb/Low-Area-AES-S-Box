module tb_axi4_snooper();

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    logic clk;
    logic rst_n;

    // AXI4 Write Address Channel (AW)
    logic                  awvalid;
    logic                  awready;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0]            awlen;
    logic [2:0]            awsize;
    logic [1:0]            awburst;

    // AXI4 Write Data Channel (W)
    logic                  wvalid;
    logic                  wready;
    logic                  wlast;

    // Dedicated Error-Assertion Output Ports 
    logic                 err_aw_handshake;
    logic                 err_w_handshake;
    logic                 err_4kb_boundary;
    logic                 err_wlast_mismatch;

    axi4_snooper #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .awvalid(awvalid),
        .awready(awready),
        .awaddr(awaddr),
        .awlen(awlen),
        .awsize(awsize),
        .awburst(awburst),
        .wvalid(wvalid),
        .wready(wready),
        .wlast(wlast),
        .err_aw_handshake(err_aw_handshake),
        .err_w_handshake(err_w_handshake),
        .err_4kb_boundary(err_4kb_boundary),
        .err_wlast_mismatch(err_wlast_mismatch)
    );

    always #5 clk = ~clk;

    // =========================================================
    // HELPER TASK: Clock Cycle Delay
    // =========================================================
    task wait_cycles(input int cycles);
        repeat(cycles) @(posedge clk);
    endtask

    // =========================================================
    // TASK 1: The "Golden" Burst (Baseline - No Errors)
    // =========================================================
    task test_golden_burst();
        $display("--- RUNNING: Golden Burst (Expect 0 Errors) ---");
        
        // Phase 1: Valid Address Handshake
        awvalid = 1; awready = 1;
        awaddr  = 32'h0000_1000; // Safe address, no 4KB crossing
        awlen   = 8'd3;          // 4 data beats total (AWLEN = N-1)
        awsize  = 3'd2;          // 4 bytes per beat
        awburst = 2'b01;         // INCR burst
        wait_cycles(1);
        awvalid = 0; awready = 0;
        
        // Phase 2: Valid Data Handshakes
        wvalid = 1; wready = 1; wlast = 0;
        wait_cycles(3); // First 3 beats
        
        wlast = 1;      // Final beat matches awlen
        wait_cycles(1);
        wvalid = 0; wready = 0; wlast = 0;
        
        wait_cycles(2);
    endtask

    // =========================================================
    // TASK 2: The Handshake Drop (Illegal VALID Deassertion)
    // =========================================================
    task test_handshake_drop();
        $display("--- RUNNING: Handshake Drop Injection ---");
        
        awvalid = 1; awready = 0; // Master asserts, Slave not ready
        wait_cycles(1);
        
        awvalid = 0; // ILLEGAL: Master drops VALID before READY
        wait_cycles(1);
        
        if (err_aw_handshake) $display("  [PASS] Caught AW Handshake Drop!");
        else $display("  [FAIL] Missed AW Handshake Drop!");
        
        wait_cycles(2);
    endtask

    // =========================================================
    // TASK 3: The 4KB Boundary Crash
    // =========================================================
    task test_4kb_crash();
        $display("--- RUNNING: 4KB Boundary Crash Injection ---");
        
        awvalid = 1; awready = 1;
        awaddr  = 32'h0000_0FF0; // 16 bytes away from 0x1000 boundary
        awlen   = 8'd7;          // 8 beats * 4 bytes = 32 bytes (CROSSES BOUNDARY!)
        awsize  = 3'd2;          
        wait_cycles(1);
        awvalid = 0; awready = 0;
        
        // The error is purely combinational, so it should flag immediately on awvalid
        if (err_4kb_boundary) $display("  [PASS] Caught 4KB Boundary Crossing!");
        else $display("  [FAIL] Missed 4KB Boundary Crossing!");
        
        wait_cycles(2);
    endtask

    // =========================================================
    // TASK 4: The Premature WLAST
    // =========================================================
    task test_premature_wlast();
        $display("--- RUNNING: Premature WLAST Injection ---");
        
        // Phase 1: Address Handshake
        awvalid = 1; awready = 1;
        awaddr  = 32'h0000_2000;
        awlen   = 8'd3;          // Expecting 4 beats
        awsize  = 3'd2;          
        wait_cycles(1);
        awvalid = 0; awready = 0;
        
        // Phase 2: Illegal Data Handshake
        wvalid = 1; wready = 1; wlast = 0;
        wait_cycles(1); // Beat 1
        
        wlast = 1;      // ILLEGAL: WLAST on Beat 2 (Expected on Beat 4)
        wait_cycles(1);
        
        if (err_wlast_mismatch) $display("  [PASS] Caught Premature WLAST!");
        else $display("  [FAIL] Missed Premature WLAST!");
        
        wvalid = 0; wready = 0; wlast = 0;
        wait_cycles(2);
    endtask

    initial begin
        // 1. Initialize all inputs to 0
        clk = 0; rst_n = 0;
        awvalid = 0; awready = 0; awaddr = 0; awlen = 0; awsize = 0; awburst = 0;
        wvalid = 0; wready = 0; wlast = 0;
        
        // 2. Dump Waves for visual proof
        $dumpfile("axi4_snooper_waves.vcd");
        $dumpvars(0, tb_axi4_snooper);
        
        // 3. Release Reset
        wait_cycles(2);
        rst_n = 1;
        wait_cycles(2);
        
        // 4. Run the Verification Suite
        $display("========================================");
        $display("  AXI4 PROTOCOL CHECKER VERIFICATION");
        $display("========================================");
        
        test_golden_burst();
        test_handshake_drop();
        test_4kb_crash();
        test_premature_wlast();
        
        $display("========================================");
        $display("  VERIFICATION COMPLETE");
        $display("========================================");
        
        $finish;
    end

endmodule
