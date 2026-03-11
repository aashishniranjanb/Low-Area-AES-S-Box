`timescale 1ns/1ps
`default_nettype none

module tb_systolic_array;

    /* -----------------------------------------
       Parameters
    ----------------------------------------- */

    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;

    /* -----------------------------------------
       Clock / Reset
    ----------------------------------------- */

    reg clk;
    reg rst;
    reg start;

    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz clock

    /* -----------------------------------------
       DUT Inputs
    ----------------------------------------- */

    reg signed [DATA_WIDTH*4-1:0] activation_bus;
    reg signed [DATA_WIDTH*4-1:0] weight_bus;

    wire signed [ACC_WIDTH*4-1:0] result_bus;
    wire done;

    /* -----------------------------------------
       Memory for Test Data
    ----------------------------------------- */

    reg signed [DATA_WIDTH-1:0] activations [0:15];
    reg signed [DATA_WIDTH-1:0] weights     [0:15];
    reg signed [ACC_WIDTH-1:0]  golden      [0:15];

    /* -----------------------------------------
       Result Storage
    ----------------------------------------- */

    reg signed [ACC_WIDTH-1:0] result [0:3];

    integer i;

    /* -----------------------------------------
       DUT Instantiation
    ----------------------------------------- */

    systolic_array_4x4_pro dut (

        .clk(clk),
        .rst(rst),
        .start(start),

        .activation_in(activation_bus),
        .weight_in(weight_bus),

        .result_out(result_bus),

        .done(done)

    );

    /* -----------------------------------------
       Testbench Initialization
    ----------------------------------------- */

    initial begin

        $display("\n==== Loading Test Data ====\n");

        $readmemh("data/activations.hex", activations);
        $readmemh("data/weights.hex", weights);
        $readmemh("data/golden.hex", golden);

        rst   = 1;
        start = 0;

        #20
        rst = 0;

        /* pack activations into bus */

        activation_bus = {
            activations[3],
            activations[2],
            activations[1],
            activations[0]
        };

        /* pack weights into bus */

        weight_bus = {
            weights[3],
            weights[2],
            weights[1],
            weights[0]
        };

        #10
        start = 1;

        #10
        start = 0;

    end

    /* -----------------------------------------
       Wait for Completion
    ----------------------------------------- */

    initial begin

        wait(done);

        #50;

        /* unpack results */

        result[0] = result_bus[ACC_WIDTH*1-1:ACC_WIDTH*0];
        result[1] = result_bus[ACC_WIDTH*2-1:ACC_WIDTH*1];
        result[2] = result_bus[ACC_WIDTH*3-1:ACC_WIDTH*2];
        result[3] = result_bus[ACC_WIDTH*4-1:ACC_WIDTH*3];

        $display("\n==== Result Comparison ====\n");

        for(i=0;i<4;i=i+1) begin

            if(result[i] == golden[i])
                $display("Row %0d PASS  Result=%0d  Golden=%0d",
                        i,result[i],golden[i]);

            else
                $display("Row %0d FAIL  Result=%0d  Golden=%0d",
                        i,result[i],golden[i]);

        end

        $display("\n==== Simulation Finished ====\n");

        $finish;

    end

    /* -----------------------------------------
       Waveform Dump
    ----------------------------------------- */

    initial begin
        $dumpfile("waves/systolic.vcd");
        $dumpvars(0,tb_systolic_array);
    end

endmodule

`default_nettype wire
