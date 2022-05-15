`timescale 1ns / 1ps

module ifetch(
    input sys_clk,
    input rst_n,

    // From execute:
    input do_jump,
    input [31:0] jump_addr,

    // From mem and execute: stall if read mem
    input stall,
    output reg global_stall,

    output [31:0] ins_out,
    output reg [31:0] pc_out,
    output reg [31:0] next_pc_out,

    // L1 ICache
    output immu_read,
    output [31:0] immu_addr,

    input immu_done,
    input [255:0] immu_read_data
);
    reg [31:0] pc;
    reg [31:0] next_pc;
    reg working;
    wire [31:0] il1_ins_out;
    wire il1_stall;

    l1icache il1(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .l1_read(working),
        .l1_addr(pc),

        .l1_data_o(ins_out),
        .stall(il1_stall),

        .l1_mmu_req_read(immu_read),
        .l1_mmu_req_addr(immu_addr),

        .mmu_l1_done(immu_done),
        .mmu_l1_read_data(immu_read_data)
    );
    
    wire fecth_stall = stall || il1_stall;
    
    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            // ins_out <= 0;
            pc_out <= 0;
            next_pc_out <= 0;
            global_stall <= 0;
            working <= 0;
        end else begin
            // ins_out <= fecth_stall ? ins_out : il1_ins_out;
            pc_out <= pc;
            next_pc_out <= next_pc;
            global_stall <= fecth_stall;
            working <= 1;
        end
    end

    always @* begin
        if (!rst_n) begin
            next_pc = 32'b0;
        end else begin
            next_pc = pc + 4;
        end
    end

    always @(negedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h00001000;
        end else begin
            if (pc == 31'h00008000) begin
                pc <= pc;
            end else begin
                if (fecth_stall) 
                    pc <= pc;
                else if (do_jump) 
                    pc <= jump_addr;
                else
                    pc <= next_pc;
                // ins_out = ins_dout;
            end
        end
    end
    // always @(ins_dout or rst_n) begin 
    //     if (!rst_n) begin
    //         ins_out = 32'b0;
    //     end else begin
    //         // ins_out <= {ins_mem[pc+3],ins_mem[pc+2],ins_mem[pc+1],ins_mem[pc]};
    //         ins_out = ins_dout;
    //     end
    // end

endmodule