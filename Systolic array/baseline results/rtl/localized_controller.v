`timescale 1ns/1ps
`default_nettype none

module localized_controller #(
    parameter SIZE = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    output reg  weight_load,
    output reg  acc_clear,
    output reg  valid_in,
    output reg  done
);

    /* -----------------------------------------
       Derived Timing Parameters
    ----------------------------------------- */

    localparam LOAD_CYCLES   = SIZE;
    localparam COMPUTE_CYCLES = SIZE;
    localparam FLUSH_CYCLES  = SIZE;

    /* -----------------------------------------
       FSM States
    ----------------------------------------- */

    localparam IDLE        = 3'b000;
    localparam LOAD_WEIGHT = 3'b001;
    localparam COMPUTE     = 3'b010;
    localparam FLUSH       = 3'b011;
    localparam FINISH      = 3'b100;

    reg [2:0] state;
    reg [2:0] next_state;

    /* -----------------------------------------
       Cycle Counter
    ----------------------------------------- */

    reg [7:0] counter;

    /* -----------------------------------------
       State Register
    ----------------------------------------- */

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    /* -----------------------------------------
       Next State Logic
    ----------------------------------------- */

    always @(*) begin

        next_state = state;

        case(state)

            IDLE:
                if(start)
                    next_state = LOAD_WEIGHT;

            LOAD_WEIGHT:
                if(counter == LOAD_CYCLES-1)
                    next_state = COMPUTE;

            COMPUTE:
                if(counter == COMPUTE_CYCLES-1)
                    next_state = FLUSH;

            FLUSH:
                if(counter == FLUSH_CYCLES-1)
                    next_state = FINISH;

            FINISH:
                next_state = IDLE;

        endcase

    end

    /* -----------------------------------------
       Counter Logic
    ----------------------------------------- */

    always @(posedge clk) begin

        if(rst)
            counter <= 0;

        else if(state != next_state)
            counter <= 0;

        else
            counter <= counter + 1;

    end

    /* -----------------------------------------
       Output Logic
    ----------------------------------------- */

    always @(posedge clk) begin

        if(rst) begin

            weight_load <= 0;
            valid_in    <= 0;
            acc_clear   <= 0;
            done        <= 0;

        end
        else begin

            /* default outputs */

            weight_load <= 0;
            valid_in    <= 0;
            acc_clear   <= 0;
            done        <= 0;

            case(state)

                IDLE: begin
                    acc_clear <= 1;
                end

                LOAD_WEIGHT: begin
                    weight_load <= 1;
                end

                COMPUTE: begin
                    valid_in <= 1;
                end

                FLUSH: begin
                    valid_in <= 0;
                end

                FINISH: begin
                    done <= 1;
                end

            endcase

        end

    end

endmodule

`default_nettype wire
