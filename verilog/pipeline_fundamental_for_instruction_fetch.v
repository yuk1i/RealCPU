`timescale 1ns / 1ps

module pipeline_fundamental_for_instruction_fetch(
    input sys_clk; 
    input rst_n; 

    input in_do_jump; 
    input [31: 0] in_jump_addr; 
    input in_stall; 

    output reg do_jump; 
    output reg [31: 0] jump_addr; 

    output reg stall; 
);

always @(negedge sys_clk, negedge rst_n) begin
    if (!rst_n) begin
        do_jump <= 0; 
        jump_addr <= 32'b0; 
    end
    else begin
        do_jump <= in_do_jump; 
        jump_addr <= in_jump_addr; 
    end
end


endmodule
