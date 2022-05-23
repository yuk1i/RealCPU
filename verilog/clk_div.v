`timescale 1ns / 1ps

module clk_div(
    input clk,
    input rst_n,
    input[31:0] cnt,
    output reg clk_out
);
    reg[31:0] counter;
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end
        else begin
            if(counter == cnt) begin
                clk_out <= 1;
                counter <= 0;
            end else begin
                clk_out <= 0;
                counter <= counter + 1;
            end
        end
    end
endmodule
