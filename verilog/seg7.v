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

    // function [7:0] display;
    //     input[3:0] data;
    //     begin
    //     case(data)
    //             //ABCDEFG_DP
    //             0  : display = 8'B11111100;
    //             1  : display = 8'B01100000;
    //             2  : display = 8'B11011010;
    //             3  : display = 8'B11110010;
    //             4  : display = 8'B01100110;
    //             5  : display = 8'B10110110;
    //             6  : display = 8'B10111110;
    //             7  : display = 8'B11100000;
    //             8  : display = 8'B11111110;
    //             9  : display = 8'B11100110;
    //             10 : display = 8'B11101110;
    //             11 : display = 8'B00111110;
    //             12 : display = 8'B00011010;
    //             13 : display = 8'B01111010;
    //             14 : display = 8'B10011110;
    //             15 : display = 8'B10001110;
    //         endcase
    //      end
    // endfunction
endmodule
