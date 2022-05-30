`timescale 1ns/1ps

module mdivider (
    input sys_clk,
    input rst_n,

    input [31:0] divisor,
    input [31:0] dividend,

    input enable,
    input unsign,
    input mod,

    output [31:0] result,
    output done
);
    wire [63:0] dout;
    assign result = mod ? dout[31:0] : dout[63:32];
    
    divider ipdiv(
        .aclk(sys_clk),
        .aclken(enable),
        .aresetn(rst_n),

        .s_axis_divisor_tdata(divisor),
        .s_axis_divisor_tvalid(enable),
        .s_axis_dividend_tdata(dividend),
        .s_axis_dividend_tvalid(enable),

        .m_axis_dout_tdata(dout),
        .m_axis_dout_tvalid(done)
    );

endmodule