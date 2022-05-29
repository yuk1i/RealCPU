`timescale 1ns / 1ps

module multiplier(
    input clk,
    input rst_n,
    input enable,
    input is_unsign,
    input[31:0] a,
    input[31:0] b,
    output[63:0] result,
    output done
);
    
    reg [2:0] counter;
    wire [63:0] re_unsign;
    wire [63:0] re_sign;
    wire _done = counter == 1 ? 1'b1 : 1'b0;
    reg _done_delay;
    always @(posedge clk) _done_delay <= _done;

    assign done = _done_delay || _done;

    // short for ifetch design 6 --> 5
    mult_sign uut(
        .CLK(clk),
        .A(a),
        .B(b),
        .P(re_sign),
        .CE(enable)
    );
    
    mult_unsign neko(
        .CLK(clk),
        .A(a),
        .B(b),
        .P(re_unsign),
        .CE(enable)
    );
    
    assign result = is_unsign ? re_unsign : re_sign;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 3'b0;
        end else begin
            if (enable) begin
                counter <= counter + 1;
            end 
                else counter <= 0;
        end
    end
endmodule
