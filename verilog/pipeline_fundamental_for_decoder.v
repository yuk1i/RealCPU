`timescale 1ns / 1ps

module pipeline_fundamental_for_decoder(
    input sys_clk; 
    input rst_n; 

    input [31: 0] in_ins_i,
    input in_is_stalling,

    // From WB
    // input in_reg_write_i,
    // input [4: 0] in_reg_write_id_i,
    // input [31: 0] in_reg_write_data_i,

    output reg [31: 0] ins_i; 
    output reg is_stalling, 

    // output reg reg_write_i; 
    // output reg [4: 0] reg_write_id_i; 
    // output reg [31: 0] reg_write_data_i; 
);

always @(negedge sys_clk, negedge rst_n) begin
    if (!rst_n) begin
        ins_i <= 32'b0; 
        is_stalling <= 0; 
        // reg_write_i <= 0;         
        // reg_write_id_i <= in_reg_write_id_i; 
        // reg_write_data_i <= in_reg_rwite_data_i; 
    end else begin
        ins_i <= in_ins_i; 
        is_stalling <= in_is_stalling;
    end
end


endmodule
