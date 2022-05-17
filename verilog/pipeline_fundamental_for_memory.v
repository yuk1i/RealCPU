`timescale 1ns / 1ps

module pipeline_fundamental_for_memory(
    input sys_clk; 
    input rst_n; 

    input l1_read,
    input l1_write,
    input [31:0] l1_addr,
    input [1:0] l1_write_type, // 00: sb, 01: sh, 10: undefined, 11: sw
    input [31:0] l1_write_data,

    output reg p_l1_read; 
    output reg p_l1_write; 
    output reg [31: 0] p_l1_addr; 
    output reg [1: 0] p_l1_write_type; 
    output reg [31: 0] p_l1_write_data; 
);

always @(negedge sys_clk) begin
    p_l1_read <= l1_read; 
    p_l1_write <= l1_write; 
    p_l1_addr <= l1_addr; 
    p_l1_write_type <= l1_write_type; 
    p_l1_write_data <= l1_write_data; 
end

endmodule
