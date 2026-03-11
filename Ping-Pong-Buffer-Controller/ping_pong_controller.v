module ping_pong_controller #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4 // 16-deep buffer per bank
)(
    input  wire clk,
    input  wire rst_n,
    
    // Swap Control
    input  wire swap,            // Pulses high to swap banks
    output wire current_wr_bank, // Swap-status signaling
    
    // Producer Interface (Write)
    input  wire write_en,
    input  wire [ADDR_WIDTH-1:0] write_addr,
    input  wire [DATA_WIDTH-1:0] write_data,
    
    // Consumer Interface (Read)
    input  wire read_en,
    input  wire [ADDR_WIDTH-1:0] read_addr,
    output reg  [DATA_WIDTH-1:0] read_data
);

    // Swap-Status Register
    reg active_wr_bank; 
    assign current_wr_bank = active_wr_bank;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            active_wr_bank <= 1'b0; // Start writing to Bank 0
        else if (swap) 
            active_wr_bank <= ~active_wr_bank; // Toggle banks instantly
    end

    // The Dual Memory Banks (Inferred as standard registers or SRAM)
    reg [DATA_WIDTH-1:0] bank0 [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] bank1 [0:(1<<ADDR_WIDTH)-1];

    // Bank Arbitration & Address Mapping
    wire we_0 = (active_wr_bank == 1'b0) ? write_en : 1'b0;
    wire we_1 = (active_wr_bank == 1'b1) ? write_en : 1'b0;

    // Bank 0 Write Logic
    always @(posedge clk) begin
        if (we_0) bank0[write_addr] <= write_data;
    end

    // Bank 1 Write Logic
    always @(posedge clk) begin
        if (we_1) bank1[write_addr] <= write_data;
    end

    // Continuous Read Routing (Consumer always reads the OPPOSITE bank)
    always @(posedge clk) begin
        if (read_en) begin
            if (active_wr_bank == 1'b1) 
                read_data <= bank0[read_addr]; // If writing 1, read 0
            else 
                read_data <= bank1[read_addr]; // If writing 0, read 1
        end
    end

endmodule
