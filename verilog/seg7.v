`timescale 1ns / 1ps

module seg7 (
    
    input clk,
    input rst_n,
    input[63:0] numbers,
    output reg[7:0] LED_BITS,
    output reg[7:0] LED
);

    reg [2:0] LED_activating_counter;

    reg [12:0] cnt;
    wire div_clk = cnt[12] == 1;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end    

    always @(posedge div_clk) begin
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
