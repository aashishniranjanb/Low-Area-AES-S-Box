`timescale 1ns/1ps

module tb_ping_pong();

    reg clk, rst_n, swap;
    reg write_en, read_en;
    reg [3:0] write_addr, read_addr;
    reg [7:0] write_data;
    wire [7:0] read_data;
    wire current_wr_bank;

    ping_pong_controller #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) dut (
        .clk(clk), .rst_n(rst_n), .swap(swap), .current_wr_bank(current_wr_bank),
        .write_en(write_en), .write_addr(write_addr), .write_data(write_data),
        .read_en(read_en), .read_addr(read_addr), .read_data(read_data)
    );

    always #5 clk = ~clk; // 100MHz clock

    integer i;

    initial begin
        $dumpfile("ping_pong_transition.vcd");
        $dumpvars(0, tb_ping_pong);

        // Initialize
        clk = 0; rst_n = 0; swap = 0;
        write_en = 0; read_en = 0;
        write_addr = 0; read_addr = 0; write_data = 0;

        #20 rst_n = 1;

        // --- CYCLE 1: Producer fills Bank 0 ---
        write_en = 1;
        for (i = 0; i < 16; i = i + 1) begin
            write_addr = i;
            write_data = 8'hA0 + i; // A0, A1, A2...
            #10;
        end
        
        // --- THE TRANSITION (The Screenshot Moment) ---
        // Trigger swap. Producer moves to Bank 1, Consumer starts reading Bank 0
        swap = 1; 
        #10 swap = 0;
        
        // --- CYCLE 2: Simultaneous Read/Write (Zero Stalls) ---
        read_en = 1;
        for (i = 0; i < 16; i = i + 1) begin
            // Producer writes to Bank 1
            write_addr = i;
            write_data = 8'hB0 + i; // B0, B1, B2...
            
            // Consumer reads from Bank 0
            read_addr = i;
            #10;
        end

        // Trigger swap again to prove continuous flow
        swap = 1;
        #10 swap = 0;
        
        // --- CYCLE 3: Consumer reads Bank 1 ---
        write_en = 0; // Stop writing, just read out the B-data
        for (i = 0; i < 16; i = i + 1) begin
            read_addr = i;
            #10;
        end

        #20 $finish;
    end
endmodule
