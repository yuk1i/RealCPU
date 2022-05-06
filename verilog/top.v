`timescale 1ns / 1ps

module top(
    input sys_clk,
    input rst_n
    
    // input sw_clk,
    // input sw_pc_ins,

    // wire [7:0] seg7_led,
    // wire [7:0] seg7_select
);

    wire [31:0] f_ins;
    wire [31:0] f_pc;
    wire [31:0] f_next_pc;

    wire [5:0] d_opcode;
    wire [4:0] d_shift_amt;
    wire [5:0] d_func;
    wire d_R_op;

    wire [31:0] d_ext_immd;
    wire [25:0] d_j_addr;
    wire d_is_jump;       
    wire d_is_jal;
    wire d_is_jr;
    wire d_is_branch;
    wire d_is_load_store;

    wire [4:0] d_rs_id;
    wire [4:0] d_rt_id;
    wire [4:0] d_rd_id;

    wire [31:0] d_reg_read1;
    wire [31:0] d_reg_read2;

    wire d_mem_to_reg;
    wire d_mem_write;
    wire d_alu_src;
    wire d_reg_write;
    wire d_reg_dst;
    wire d_alu_bypass;
    wire [31:0] d_bypass_immd;

    wire [31:0] e_result;
    wire e_do_jump;
    wire [31:0] e_j_addr;

    wire [31:0] m_mem_data;
    wire m_stall;

    /*** Write Back ***/ 
    wire wb_reg_write = d_reg_write;
    wire [4:0] wb_reg_write_id = d_reg_dst ? d_rd_id : d_rt_id;
    wire [31:0] wb_data = d_mem_to_reg ? m_mem_data : e_result;
    
    ifetch fetch(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .do_jump(e_do_jump),
        .jump_addr(e_j_addr),

        .stall(m_stall),

        .ins_out(f_ins),
        .pc_out(f_pc),
        .next_pc_out(f_next_pc)
    );

    idecoder decoder(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .ins_i(f_ins),

        .reg_write_i(wb_reg_write),
        .reg_write_id_i(wb_reg_write_id),
        .reg_write_data_i(wb_data),
        
        .opcode(d_opcode),
        .shift_amt(d_shift_amt),
        .func(d_func),
        .R_op(d_R_op),
        .ext_immd(d_ext_immd),
        .j_addr(d_j_addr),
        .is_jump(d_is_jump),
        .is_jal(d_is_jal),
        .is_jr(d_is_jr),
        .is_branch(d_is_branch),
        .is_load_store(d_is_load_store),

        .rs_id(d_rs_id),
        .rt_id(d_rt_id),
        .rd_id(d_rd_id),

        .reg_read1(d_reg_read1),
        .reg_read2(d_reg_read2),

        .mem_to_reg(d_mem_to_reg),
        .mem_write(d_mem_write),
        .alu_src(d_alu_src),
        .reg_write(d_reg_write),
        .reg_dst(d_reg_dst),
        .alu_bypass(d_alu_bypass),
        .bypass_immd(d_bypass_immd)

    );

    execute ex(
        .reg1(d_reg_read1),
        .reg2(d_reg_read2),
        .immd(d_ext_immd),
        .next_pc(f_next_pc),
        .alu_src(d_alu_src),
        .alu_bypass(d_alu_bypass),
        .bypass_immd(d_bypass_immd),
        .allow_exp(0),      // TODO: Exception support

        .opcode(d_opcode),
        .func(d_func),
        .ins_shamt(d_shift_amt),
        .R_op(d_R_op),
        .ins_j_addr(d_j_addr),
        .is_jump(d_is_jump),
        .is_branch(d_is_branch),
        .is_jal(d_is_jal),
        .is_jr(d_is_jr),
        .is_load_store(d_is_load_store),
        
        .result(e_result),
        .do_jump(e_do_jump),
        .j_addr(e_j_addr)
    );

    mmu mmud(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .mem_read(d_mem_to_reg),
        .mem_addr(e_result),
        .mem_write(d_mem_write),
        .mem_wd(d_reg_read2),

        .mem_data_o(m_mem_data),
        .stall(m_stall)
    );

    // wire [31:0] dis;
    // assign dis = sw_pc_ins ? pc : ins;
	// seg7 seg_left(
	// 		.clk(sys_clk),
	// 		.rst_n(rst_n),
	// 		.numbers(dis),
	// 		.LED_BITS(seg7_select),
	// 		.LED(seg7_led)
	// );
endmodule
