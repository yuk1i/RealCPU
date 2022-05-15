`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/13 23:23:16
// Design Name: 
// Module Name: multiplexer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module multiplexer(
input clk,
input rst_n,
input enable,
input is_unsign,
input[31:0] a,
input[31:0] b,
output[63:0] result,
output done
    );
    
    reg start;
    reg [2:0] counter;
    wire [63:0] re_unsign;
    wire [63:0] re_sign;
    assign done = counter == 6 ? 1'b1 : 1'b0;
    // short for ifetch design 6 --> 5
    mult_sign uut(
        .CLK(~clk),
        .A(a),
        .B(b),
        .P(re_sign),
        .CE(start)
    );
    
    mult_unsign neko(
        .CLK(~clk),
        .A(a),
        .B(b),
        .P(re_unsign),
        .CE(start)
    );
    
    assign result = is_unsign ? re_unsign : re_sign;

    
    always @* begin
        if (!rst_n) start = 0;
        else if (!start && enable == 1 && !done)
            start = 1;
        else if (start && !done) start = 1;
        else start = 0;
    end
    
    always @(negedge clk, negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'b0;
        end else begin
            if (start) begin
                if (done)
                    counter <= 0;
                else 
                    counter <= counter + 1;
            end else counter <= 0;
        end
    end
endmodule
