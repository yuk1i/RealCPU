`timescale 1ns/1ps

module mem_wb(
    input sys_clk,
    input rst_n,
    input mem_wb_stall,

    // from ex_mem
    input [5:0]     mi_opcode,
    input           mi_mem_to_reg,
    input [31:0]    mi_ex_result,
    input           mi_reg_write,
    input [4:0]     mi_reg_dst_id,

    // from mem
    input [31:0]    mi_mem_read_data,

    // output, to wb
    output          wbo_reg_write,
    output [4:0]    wbo_reg_dst_id,
    output [31:0]   wbo_reg_wdata,

    // forwarding, to id/ex and ex/mem
    output          fwd_mem_reg_write,
    output [4:0]    fwd_mem_reg_dst_id,
    output [31:0]   fwd_mem_result
);

    reg [5:0]       reg_opcode;
    reg             reg_mem_to_reg;
    reg [31:0]      reg_ex_result;
    reg             reg_reg_write;
    reg [4:0]       reg_reg_dst_id;
    reg [31:0]      reg_mem_read_data;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            reg_opcode          <= 0;
            reg_mem_to_reg      <= 0;
            reg_ex_result       <= 0;
            reg_reg_write       <= 0;
            reg_reg_dst_id      <= 0;
            reg_mem_read_data   <= 0;
        end else begin
            if (mem_wb_stall) begin
                reg_opcode          <= reg_opcode       ;
                reg_mem_to_reg      <= reg_mem_to_reg   ;
                reg_ex_result       <= reg_ex_result    ;
                reg_reg_write       <= reg_reg_write    ;
                reg_reg_dst_id      <= reg_reg_dst_id   ;
                reg_mem_read_data   <= reg_mem_read_data;
            end else begin
                reg_opcode          <= mi_opcode       ;
                reg_mem_to_reg      <= mi_mem_to_reg   ;
                reg_ex_result       <= mi_ex_result    ;
                reg_reg_write       <= mi_reg_write    ;
                reg_reg_dst_id      <= mi_reg_dst_id   ;
                reg_mem_read_data   <= mi_mem_read_data;
            end
        end
    end

    // output to wb
    assign wbo_reg_write    = reg_reg_write;
    assign wbo_reg_dst_id   = reg_reg_dst_id;
    assign wbo_reg_wdata    = reg_mem_to_reg ? wb_ext_data : reg_ex_result;

    // forwarding to id/ex
    assign fwd_mem_reg_write    = reg_reg_write;
    assign fwd_mem_reg_dst_id   = reg_reg_dst_id;
    assign fwd_mem_result       = wbo_reg_wdata;

    // Write Back, for [lh,lhu,lb,lbu], do sign or zero extension 
    reg [31:0] wb_ext_data;    
    wire [7:0] wb_byte_extra = reg_mem_read_data[reg_ex_result[1:0] * 8+:8];
    wire [15:0] wb_hw_extra = reg_mem_read_data[reg_ex_result[1] * 16+:16];
    always @* begin
        case(reg_opcode[2:0])
            3'b000: wb_ext_data = {{24{wb_byte_extra[7]}}, wb_byte_extra[7:0]};     // lb
            3'b001: wb_ext_data = {{16{wb_hw_extra[15]}}, wb_hw_extra[15:0]};       // lh
            3'b011: wb_ext_data = reg_mem_read_data;                                       // lw
            3'b100: wb_ext_data = {24'b0, wb_byte_extra[7:0]};                      // lbu
            3'b101: wb_ext_data = {16'b0, wb_hw_extra[15:0]};                       // lhu
            default:wb_ext_data = reg_mem_read_data;
        endcase
    end
endmodule