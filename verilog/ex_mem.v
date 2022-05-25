`timescale 1ns/1ps

module ex_mem(
    input sys_clk, 
    input rst_n,
    input ex_mem_stall,

    // from ex
    input [31:0]    ei_result,

    // from id_ex
    input [31:0]    ei_ins,
    input           ei_is_sync      ,
    input [31:0]    ei_reg_read2    ,
    input           ei_mem_to_reg   ,   // load 
    input           ei_mem_write    ,   // store
    input           ei_reg_write    ,
    input [4:0]     ei_reg_dst_id   ,
    
    // output, to mem
    output          mo_mem_read      ,  // mem_to_reg
    output          mo_mem_write     ,
    output [31:0]   mo_ex_result     ,  // addr, or route to data
    output [31:0]   mo_mem_write_data,
    output [1:0]    mo_mem_write_type,
    output          mo_is_sync_ins   ,
    output [4:0]    mo_sync_type     ,

    // output, to mem/wb
    output [5:0]    mo_opcode       ,
    output          mo_reg_write    ,
    output [4:0]    mo_reg_dst_id   ,

    // forwarding, to id/ex
    output          fwd_ex_reg_write,
    output [4:0]    fwd_ex_reg_dst_id,
    output [31:0]   fwd_ex_result,

    // forwarding from mem/wb
    input           fwd_mem_reg_write,
    input [4:0]     fwd_mem_reg_dst_id,
    input [31:0]    fwd_mem_result
);

    wire [5:0]  ins_opcode      = ei_ins[31:26];
    wire [4:0]  ins_sync_type   = ei_ins[10:6];
    wire [4:0]  ins_rt_id       = ei_ins[20:16];

    reg [5:0]   reg_opcode      ;
    reg [4:0]   reg_rt_id       ;
    reg [31:0]  reg_result      ;
    reg [31:0]  reg_reg_read2   ;
    reg         reg_mem_to_reg  ;
    reg         reg_mem_write   ;
    reg         reg_reg_write   ;
    reg [4:0]   reg_reg_dst_id  ;
    reg         reg_is_sync     ;
    reg [4:0]   reg_sync_type   ;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            reg_opcode     <= 0;
            reg_rt_id       <= 0;
            reg_result     <= 0;
            reg_reg_read2  <= 0;
            reg_mem_to_reg <= 0;
            reg_mem_write  <= 0;
            reg_reg_write  <= 0;
            reg_reg_dst_id <= 0;
            reg_is_sync    <= 0;
            reg_sync_type  <= 0;
        end else begin
            if (ex_mem_stall) begin
                reg_opcode     <= reg_opcode     ;
                reg_rt_id      <= reg_rt_id      ;
                reg_result     <= reg_result     ;
                reg_reg_read2  <= reg_reg_read2  ;
                reg_mem_to_reg <= reg_mem_to_reg ;
                reg_mem_write  <= reg_mem_write  ;
                reg_reg_write  <= reg_reg_write  ;
                reg_reg_dst_id <= reg_reg_dst_id ;
                reg_is_sync    <= reg_is_sync   ;
                reg_sync_type  <= reg_sync_type;
            end else begin
                reg_opcode     <= ins_opcode    ;
                reg_rt_id      <= ins_rt_id     ;
                reg_result     <= ei_result     ;
                reg_reg_read2  <= ei_reg_read2  ;
                reg_mem_to_reg <= ei_mem_to_reg ;
                reg_mem_write  <= ei_mem_write  ;
                reg_reg_write  <= ei_reg_write  ;
                reg_reg_dst_id <= ei_reg_dst_id ;
                reg_is_sync    <= ei_is_sync    ;
                reg_sync_type  <= ins_sync_type ;
            end
        end
    end

    // to mem
    assign mo_mem_read      = reg_mem_to_reg;
    assign mo_mem_write     = reg_mem_write;
    assign mo_ex_result     = reg_result;
    assign mo_mem_write_data = foward_mem ? fwd_mem_result : reg_reg_read2;
    assign mo_mem_write_type = reg_opcode[1:0];

    assign mo_is_sync_ins   = reg_is_sync;
    assign mo_sync_type     = reg_sync_type;

    // to mem/wb
    assign mo_opcode        = reg_opcode;
    assign mo_reg_write     = reg_reg_write;
    assign mo_reg_dst_id    = reg_reg_dst_id;

    // forwarding, to id/ex
    assign fwd_ex_reg_write = reg_reg_write;
    assign fwd_ex_reg_dst_id = reg_reg_dst_id;
    assign fwd_ex_result    = reg_result;

    // forwarding, mem-ex, in sw after lw case, last command result is stored in current 
    assign foward_mem = fwd_mem_reg_write
                        && fwd_mem_reg_dst_id != 5'b0
                        && reg_rt_id == fwd_mem_reg_dst_id
                        && reg_mem_write;

endmodule