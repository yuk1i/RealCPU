`timescale 1ns / 1ps

module seg7 (
    
    input clk,
    input rst_n,
    input[63:0] numbers,
    output reg[7:0] LED_BITS,
    output reg[7:0] LED
);

    reg [2:0] LED_activating_counter;

    reg [13:0] cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end

    wire div_clk = cnt[13] == 1;
    reg  div_clk_d0;
    always @(posedge clk) div_clk_d0 <= div_clk;
    wire div_clk_posedge = div_clk && !div_clk_d0;

    always @(posedge clk) begin
        if(!rst_n) begin
            LED_activating_counter <= 0;
            LED_BITS <= 8'b0000_0001;
            LED <= 0;
        end else begin
            if (div_clk_posedge) begin
                LED_activating_counter = LED_activating_counter + 1;
                LED_BITS <= ~(1 << LED_activating_counter);
                LED <= ~numbers[LED_activating_counter*8+:8];        
            end else begin
                LED_activating_counter <= LED_activating_counter;
                LED_BITS <= LED_BITS;
                LED <= LED;
            end
        end
    end


endmodule
