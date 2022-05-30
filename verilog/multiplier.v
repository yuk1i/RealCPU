`timescale 1ns / 1ps

module multiplier(
    input sys_clk,
    input rst_n,
    input enable,
    input is_unsign,
    input mul_low,
    input[31:0] a,
    input[31:0] b,
    output[31:0] result,
    output reg done
);
    wire [63:0] re_unsign;
    wire [63:0] re_sign;

    mult_sign mu_sign(
        .CLK(sys_clk),
        .A(a),
        .B(b),
        .P(re_sign),
        .CE(enable)
    );
    
    mult_unsign mu_unsign(
        .CLK(sys_clk),
        .A(a),
        .B(b),
        .P(re_unsign),
        .CE(enable)
    );
    
    assign result = is_unsign ? (mul_low ? re_unsign[31:0] : re_unsign[63:32]) : (mul_low ? re_sign[31:0] : re_sign[63:32]);

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            done <= 0;
        end else begin
            done <= enable && !done;
        end
    end
endmodule
