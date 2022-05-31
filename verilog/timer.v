`timescale 1ns/1ps

module timer(
    input sys_clk,
    input rst_n,

    input [31:0] counter,
    input        enable,

    output [31:0] current,
    output       done
);

    // state machine: counting -> done -> counting -> done
    localparam  COUNTING = 1'b0,
                DONE     = 1'b1;

    reg         status;
    reg [31:0]  cnt;
    assign current  = cnt;
    assign done     = status == DONE;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            status <= DONE;
            cnt <= 32'b0;
        end else begin
            case (status)
                DONE : begin
                    if (enable) status <= COUNTING;
                    else status <= status;
                    cnt <= 32'b0;
                end 
                COUNTING : begin
                    if (cnt == counter) begin
                        status <= DONE;
                        cnt <= 32'b0;
                    end else begin
                        status <= status;
                        cnt <= cnt + 1;
                    end
                end 
            endcase
        end
    end

endmodule