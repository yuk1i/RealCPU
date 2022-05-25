`timescale 1ns/1ps

module id_ex(
    input sys_clk,
    input rst_n,
    // from stall controller
    input id_ex_stall,
    // from bubble controller
    input id_ex_bubble,

    // from idecoder
    input [31:0]    di_pc,
    input [31:0]    di_next_pc,
    input [31:0]    di_ins,
    input [31:0]    di_ext_immd,
    input           di_is_link,
    input           di_is_jump,
    input           di_is_branch,
    input           di_is_sync,
    input [31:0]    di_reg_read1,
    input [31:0]    di_reg_read2,

    // from idecoder-controller
    input           di_mem_to_reg,
    input           di_mem_write,
    input           di_alu_src,
    input           di_reg_write,
    input [4:0]     di_reg_dst_id,

    // to ex
    output [31:0]   eo_ins,
    output [31:0]   eo_reg1,
    output [31:0]   eo_reg2,
    output [31:0]   eo_immd,
    output [31:0]   eo_next_pc,
    output          eo_alu_src,
    output          eo_is_link,
    output          eo_is_jump,
    output          eo_is_branch,
    output          eo_is_load_store,

    // to mem,wb
    output          eo_mem_to_reg,
    output          eo_mem_write,
    output          eo_reg_write,
    output [4:0]    eo_reg_dst_id,
    output          eo_is_sync,

    // forwarding from ex/mem
    input           fwd_ex_reg_write,
    input [4:0]     fwd_ex_reg_dst_id,
    input [31:0]    fwd_ex_result,
    // forwarding from mem/wb
    input           fwd_mem_reg_write,
    input [4:0]     fwd_mem_reg_dst_id,
    input [31:0]    fwd_mem_result
);

    // from idecoder
    reg   [31:0]    reg_pc;
    reg   [31:0]    reg_next_pc;
    reg   [31:0]    reg_ins;
    reg   [31:0]    reg_ext_immd;
    reg             reg_is_sync;
    reg             reg_is_link;
    reg             reg_is_jump;
    reg             reg_is_branch;
    reg   [31:0]    reg_reg_read1;
    reg   [31:0]    reg_reg_read2;
    // from controller
    reg             reg_mem_to_reg;
    reg             reg_mem_write;
    reg             reg_alu_src;
    reg             reg_reg_write;
    reg   [4:0]     reg_reg_dst_id;


    always @(posedge sys_clk) begin
        if (!rst_n || id_ex_bubble) begin
            reg_pc <= 0;
            reg_next_pc <= 0;
            reg_ins <= 0;
            reg_ext_immd <= 0;
            reg_is_sync <= 0;
            reg_is_link <= 0;
            reg_is_jump <= 0;
            reg_is_branch <= 0;
            reg_reg_read1 <= 0;
            reg_reg_read2 <= 0;
            reg_mem_to_reg <= 0;
            reg_mem_write <= 0;
            reg_alu_src <= 0;
            reg_reg_write <= 0;
            reg_reg_dst_id <= 0;
        end else begin
            if (id_ex_stall) begin 
                reg_pc          <= reg_pc        ;
                reg_next_pc     <= reg_next_pc   ;
                reg_ins         <= reg_ins       ;
                reg_ext_immd    <= reg_ext_immd  ;
                reg_is_sync     <= reg_is_sync   ;
                reg_is_link     <= reg_is_link   ;
                reg_is_jump     <= reg_is_jump   ;
                reg_is_branch   <= reg_is_branch ;
                reg_reg_read1   <= reg_reg_read1 ;
                reg_reg_read2   <= reg_reg_read2 ;
                reg_mem_to_reg  <= reg_mem_to_reg;
                reg_mem_write   <= reg_mem_write ;
                reg_alu_src     <= reg_alu_src   ;
                reg_reg_write   <= reg_reg_write ;
                reg_reg_dst_id  <= reg_reg_dst_id;
            end else begin
                reg_pc          <= di_pc;
                reg_next_pc     <= di_next_pc;
                reg_ins         <= di_ins;
                reg_ext_immd    <= di_ext_immd;
                reg_is_sync     <= di_is_sync;
                reg_is_link     <= di_is_link;
                reg_is_jump     <= di_is_jump   ;
                reg_is_branch   <= di_is_branch ;
                reg_reg_read1   <= di_reg_read1;
                reg_reg_read2   <= di_reg_read2;
                reg_mem_to_reg  <= di_mem_to_reg;
                reg_mem_write   <= di_mem_write;
                reg_alu_src     <= di_alu_src;
                reg_reg_write   <= di_reg_write;
                reg_reg_dst_id  <= di_reg_dst_id;
            end
        end
    end

    // to execute
    assign eo_ins    = reg_ins;
    assign eo_reg1   = forward_a_ex ? fwd_ex_result : { forward_a_mem ? fwd_mem_result : reg_reg_read1};
    assign eo_reg2   = forward_b_ex ? fwd_ex_result : { forward_b_mem ? fwd_mem_result : reg_reg_read2};
    assign eo_immd   = reg_ext_immd;
    // assign eo_pc     = reg_pc;
    assign eo_next_pc     = reg_next_pc;
    assign eo_is_link = reg_is_link;
    assign eo_is_jump = reg_is_jump;
    assign eo_is_branch = reg_is_branch;
    assign eo_is_load_store = reg_mem_to_reg || reg_mem_write; // lw, sw

    // to mem/wb
    assign eo_mem_to_reg    = reg_mem_to_reg;
    assign eo_mem_write     = reg_mem_write ;
    assign eo_alu_src       = reg_alu_src   ;
    assign eo_reg_write     = reg_reg_write ;
    assign eo_reg_dst_id    = reg_reg_dst_id;
    assign eo_is_sync       = reg_is_sync   ;

    // forwarding logic
    wire [4:0] rs_id = reg_ins[25:21];
    wire forward_a_ex = fwd_ex_reg_write 
                            && fwd_ex_reg_dst_id != 5'b0 
                            && rs_id == fwd_ex_reg_dst_id;

    wire forward_a_mem = fwd_mem_reg_write
                            && fwd_mem_reg_dst_id != 5'b0
                            && rs_id == fwd_mem_reg_dst_id;

    wire [4:0] rt_id = reg_ins[20:16];
    wire forward_b_ex = fwd_ex_reg_write 
                            && fwd_ex_reg_dst_id != 5'b0 
                            && rt_id == fwd_ex_reg_dst_id;

    wire forward_b_mem = fwd_mem_reg_write
                            && fwd_mem_reg_dst_id != 5'b0
                            && rt_id == fwd_mem_reg_dst_id;

endmodule