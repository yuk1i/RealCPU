`timescale 1ns / 1ps

module pipeline_fundamental_for_execute(
    input sys_clk; 
    input rst_n; 

    input [31:0] reg1,  // rs
    input [31:0] reg2,  // rt
    input [31:0] immd,
    input [31:0] next_pc,
    input alu_src, // 0: reg2, 1: immd
    input allow_exp, // ignored

    // From Decoder
    input [5:0] opcode,
    input [5:0] func,
    input [4:0] ins_shamt,
    input R_op,
    input [25:0] ins_j_addr,
    input is_jump,
    input is_branch,
    input is_regimm_op,
    input rt_id,
    input is_jal,
    input is_jr,
    input is_load_store,
    input alu_bypass,
    input [31:0] bypass_immd,

    output reg [31: 0] reg1_o; 
    output reg [31: 0] reg2_o; 
    output reg [31: 0] immd_o; 
    output reg [31: 0] next_pc_o; 
    output reg alu_src_o; 
    output reg allow_exp_o; 

    output reg [5: 0] opcode_o; 
    output reg [5: 0] func_o; 
    output reg [4: 0] ins_shamt_o; 
    output reg R_op_o; 
    output reg [25: 0] ins_j_addr_o; 
    output reg is_jump_o; 
    output reg is_branch_o; 
    output reg is_regimm_op_o; 
    output reg rt_id_o; 
    output reg is_jal_o; 
    output reg is_jr_o; 
    output reg is_load_store_o; 
    output reg alu_bypass_o; 
    output reg [31: 0] bypass_immd_o; 
);

always @(negedge sys_clk) begin
    reg1_o <= reg1; 
    reg2_o <= reg2; 
    immd_o <= immd; 
    next_pc_o <= next_pc; 
    alu_src_o <= alu_src; 
    allow_exp_o <= allow_exp; 
    opcode_o <= opcode; 
    func_o <= func; 
    ins_shamt_o <= ins_shamt; 
    R_op_o <= R_op; 
    ins_j_addr_o <= ins_j_addr; 
    is_jump_o <= is_jump; 
    is_branch_o <= is_branch; 
    is_regimm_op_o <= is_regimm_op; 
    rt_id_o <= rt_id; 
    is_jal_o <= is_jal; 
    is_jr_o <= is_jr; 
    is_load_store_o <= is_load_store; 
    alu_bypass_o <= alu_bypass;
    bypass_immd_o <= bypass_immd; 

    in_do_jump_o <= in_do_jump; 
    in_jump_addr_o <= in_jump_addr; 
    install_o <= install; 
end

endmodule
