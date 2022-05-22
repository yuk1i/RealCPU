`timescale 1ns / 1ps

module seg7 (
    
    input clk,
    input rst_n,
    input[63:0] numbers,
    output reg[7:0] LED_BITS,
    output reg[7:0] LED
);
    wire refresh_clk;
    reg [2:0] LED_activating_counter;
    
    clk_div refresh_clk_div(
        .clk(clk),
        .rst_n(rst_n),
        .cnt(2_00000),
        .clk_out(refresh_clk)
    );

    always @(posedge refresh_clk) begin
        if(!rst_n) begin
            LED_activating_counter <= 0;
            LED_BITS <= 1;
            LED <= 0;
        end else begin
            LED_activating_counter = LED_activating_counter + 1;
            LED_BITS <= ~(1 << LED_activating_counter);
            LED <= ~numbers[LED_activating_counter*8+:8];
        end
    end


endmodule
