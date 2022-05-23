`timescale 1ns / 1ps

module seg7 (
    
    input clk,
    input rst_n,
    input[63:0] numbers,
    output reg[7:0] LED_BITS,
    output reg[7:0] LED
);

    reg [2:0] LED_activating_counter;
    

    always @(posedge clk) begin
        if(!rst_n) begin
            LED_activating_counter <= 0;
            LED_BITS <= 8'b0000_0001;
            LED <= 0;
        end else begin
            LED_activating_counter = LED_activating_counter + 1;
            LED_BITS <= ~(1 << LED_activating_counter);
            LED <= ~numbers[LED_activating_counter*8+:8];
        end
    end


endmodule
