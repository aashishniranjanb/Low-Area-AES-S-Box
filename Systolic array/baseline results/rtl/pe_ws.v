`timescale 1ns/1ps
`default_nettype none

module pe_ws #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                         clk,
    input  wire                         rst,

    /* control */
    input  wire                         weight_load,
    input  wire                         acc_clear,
    input  wire                         valid_in,

    /* data inputs */
    input  wire signed [DATA_WIDTH-1:0] activation_in,
    input  wire signed [DATA_WIDTH-1:0] weight_in,
    input  wire signed [ACC_WIDTH-1:0]  psum_in,

    /* data outputs */
    output reg  signed [DATA_WIDTH-1:0] activation_out,
    output reg  signed [ACC_WIDTH-1:0]  psum_out,

    /* pipeline control */
    output reg                          valid_out
);

    /* -------------------------------------------
       Internal Registers
    ------------------------------------------- */
    reg signed [DATA_WIDTH-1:0] weight_reg;
    reg signed [ACC_WIDTH-1:0]  acc_reg;

    /* -------------------------------------------
       1. TRUE OPERAND ISOLATION
    ------------------------------------------- */
    wire is_active = valid_in && (activation_in != 0) && (weight_reg != 0);

    wire signed [DATA_WIDTH-1:0] mult_a = is_active ? activation_in : {DATA_WIDTH{1'b0}};
    wire signed [DATA_WIDTH-1:0] mult_b = is_active ? weight_reg : {DATA_WIDTH{1'b0}};

    /* -------------------------------------------
       2. PIPELINED MAC STAGE
    ------------------------------------------- */
    reg signed [ACC_WIDTH-1:0] pipe_mult_reg;
    reg signed [ACC_WIDTH-1:0] pipe_psum_reg;
    reg pipe_valid_reg;

    always @(posedge clk) begin
        if (rst) begin
            pipe_mult_reg  <= 0;
            pipe_psum_reg  <= 0;
            pipe_valid_reg <= 0;
        end else begin
            pipe_mult_reg  <= mult_a * mult_b;
            pipe_psum_reg  <= psum_in;
            pipe_valid_reg <= valid_in;
        end
    end

    /* -------------------------------------------
       3. Weight Stationary Register (FIXED)
    ------------------------------------------- */
    always @(posedge clk) begin
        if (rst)
            weight_reg <= 8'd0;
        else if (weight_load)
            weight_reg <= weight_in;
    end

    /* -------------------------------------------
       4. Accumulator (MAC)
    ------------------------------------------- */
    always @(posedge clk) begin
        if (rst)
            acc_reg <= 32'd0;
        else if (acc_clear)
            acc_reg <= 32'd0;
        else if (pipe_valid_reg)
            acc_reg <= pipe_psum_reg + pipe_mult_reg;
    end

    /* -------------------------------------------
       5. Data Propagation (East and South)
    ------------------------------------------- */
    always @(posedge clk) begin
        if (rst) begin
            activation_out <= 8'd0;
            psum_out       <= 32'd0;
            valid_out      <= 1'b0;
        end else begin
            activation_out <= activation_in;
            psum_out       <= acc_reg;
            valid_out      <= valid_in;
        end
    end

endmodule
`default_nettype wire
