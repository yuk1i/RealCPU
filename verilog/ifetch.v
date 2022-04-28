`timescale 1ns / 1ps

module ifetch(
    input sys_clk,
    input rst_n,

    // From execute:
    input do_jump,
    input [31:0] jump_addr,

    // From mem: stall if read mem
    input stall,

    output [31:0] ins_out,
    output reg [31:0] pc_out,
    output reg [31:0] next_pc_out
);
    reg [31:0] pc;
    reg [31:0] next_pc;

    // reg [7:0] ins_mem [0:4095];
    // 4K Instruction Cache

    ROM ins_rom(
        .clka(sys_clk),
        .addra(pc[15:2]),
        .douta(ins_out)
    );

    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 0;
            next_pc_out <= 0;
        end else begin
            pc_out <= pc;
            next_pc_out <= next_pc;
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
            pc <= 32'b0;
        end else begin
            if (pc == 31'h1000) begin
                pc <= pc;
            end else begin
                if (stall) 
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