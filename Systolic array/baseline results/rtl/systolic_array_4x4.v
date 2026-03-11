`timescale 1ns/1ps
`default_nettype none

module systolic_array_4x4 #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    /* flattened activation inputs */
    input  wire signed [DATA_WIDTH*4-1:0] activation_in,

    /* flattened weight inputs */
    input  wire signed [DATA_WIDTH*4-1:0] weight_in,

    /* result outputs */
    output wire signed [ACC_WIDTH*4-1:0] result_out,

    output wire done
);

    /* --------------------------------------
       Control Signals
    -------------------------------------- */

    wire weight_load;
    wire valid_in;
    wire acc_clear;

    localized_controller controller (
        .clk(clk),
        .rst(rst),
        .start(start),
        .weight_load(weight_load),
        .valid_in(valid_in),
        .acc_clear(acc_clear),
        .done(done)
    );

    /* --------------------------------------
       Internal Wires
    -------------------------------------- */

    wire signed [DATA_WIDTH-1:0] act0, act1, act2, act3;
    wire signed [DATA_WIDTH-1:0] w0, w1, w2, w3;

    assign act0 = activation_in[DATA_WIDTH*1-1:DATA_WIDTH*0];
    assign act1 = activation_in[DATA_WIDTH*2-1:DATA_WIDTH*1];
    assign act2 = activation_in[DATA_WIDTH*3-1:DATA_WIDTH*2];
    assign act3 = activation_in[DATA_WIDTH*4-1:DATA_WIDTH*3];

    assign w0 = weight_in[DATA_WIDTH*1-1:DATA_WIDTH*0];
    assign w1 = weight_in[DATA_WIDTH*2-1:DATA_WIDTH*1];
    assign w2 = weight_in[DATA_WIDTH*3-1:DATA_WIDTH*2];
    assign w3 = weight_in[DATA_WIDTH*4-1:DATA_WIDTH*3];

    /* --------------------------------------
       Activation Flow Wires
    -------------------------------------- */

    wire signed [DATA_WIDTH-1:0] a00,a01,a02,a03;
    wire signed [DATA_WIDTH-1:0] a10,a11,a12,a13;
    wire signed [DATA_WIDTH-1:0] a20,a21,a22,a23;
    wire signed [DATA_WIDTH-1:0] a30,a31,a32,a33;

    /* --------------------------------------
       Partial Sum Wires
    -------------------------------------- */

    wire signed [ACC_WIDTH-1:0] ps00,ps01,ps02,ps03;
    wire signed [ACC_WIDTH-1:0] ps10,ps11,ps12,ps13;
    wire signed [ACC_WIDTH-1:0] ps20,ps21,ps22,ps23;
    wire signed [ACC_WIDTH-1:0] ps30,ps31,ps32,ps33;

    /* --------------------------------------
       Row 0
    -------------------------------------- */

    pe_ws pe00(clk,rst,weight_load,acc_clear,valid_in,
                   act0,w0,0,
                   a00,ps00,);

    pe_ws pe01(clk,rst,weight_load,acc_clear,valid_in,
                   a00,w1,0,
                   a01,ps01,);

    pe_ws pe02(clk,rst,weight_load,acc_clear,valid_in,
                   a01,w2,0,
                   a02,ps02,);

    pe_ws pe03(clk,rst,weight_load,acc_clear,valid_in,
                   a02,w3,0,
                   a03,ps03,);

    /* --------------------------------------
       Row 1
    -------------------------------------- */

    pe_ws pe10(clk,rst,weight_load,acc_clear,valid_in,
                   act1,w0,ps00,
                   a10,ps10,);

    pe_ws pe11(clk,rst,weight_load,acc_clear,valid_in,
                   a10,w1,ps01,
                   a11,ps11,);

    pe_ws pe12(clk,rst,weight_load,acc_clear,valid_in,
                   a11,w2,ps02,
                   a12,ps12,);

    pe_ws pe13(clk,rst,weight_load,acc_clear,valid_in,
                   a12,w3,ps03,
                   a13,ps13,);

    /* --------------------------------------
       Row 2
    -------------------------------------- */

    pe_ws pe20(clk,rst,weight_load,acc_clear,valid_in,
                   act2,w0,ps10,
                   a20,ps20,);

    pe_ws pe21(clk,rst,weight_load,acc_clear,valid_in,
                   a20,w1,ps11,
                   a21,ps21,);

    pe_ws pe22(clk,rst,weight_load,acc_clear,valid_in,
                   a21,w2,ps12,
                   a22,ps22,);

    pe_ws pe23(clk,rst,weight_load,acc_clear,valid_in,
                   a22,w3,ps13,
                   a23,ps23,);

    /* --------------------------------------
       Row 3
    -------------------------------------- */

    pe_ws pe30(clk,rst,weight_load,acc_clear,valid_in,
                   act3,w0,ps20,
                   a30,ps30,);

    pe_ws pe31(clk,rst,weight_load,acc_clear,valid_in,
                   a30,w1,ps21,
                   a31,ps31,);

    pe_ws pe32(clk,rst,weight_load,acc_clear,valid_in,
                   a31,w2,ps22,
                   a32,ps32,);

    pe_ws pe33(clk,rst,weight_load,acc_clear,valid_in,
                   a32,w3,ps23,
                   a33,ps33,);

    /* --------------------------------------
       Final Outputs
    -------------------------------------- */

    assign result_out[ACC_WIDTH*1-1:ACC_WIDTH*0] = ps30;
    assign result_out[ACC_WIDTH*2-1:ACC_WIDTH*1] = ps31;
    assign result_out[ACC_WIDTH*3-1:ACC_WIDTH*2] = ps32;
    assign result_out[ACC_WIDTH*4-1:ACC_WIDTH*3] = ps33;

endmodule

`default_nettype wire
