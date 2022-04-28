`timescale 1ns / 1ps
module mmu(
    input sys_clk,
    input rst_n,
    
    input mem_read,
    input [31:0] mem_addr,
    input mem_write,
    input [31:0] mem_wd,

    output [31:0] mem_data_o,
    output reg stall
);
    wire sys_clk_n = ~sys_clk;
    wire [31:0] ram_out;
    wire [13:0] ram_addr = mem_read ? mem_addr[15:2] : 14'b0;
    RAM ram(
        .clka(sys_clk_n),
        .addra(ram_addr),
        .douta(ram_out),
        .dina(mem_wd),
        .wea(mem_write)
    );
    assign mem_data_o = mem_read ? ram_out : 32'b0;
    
    always @* begin
        if (!rst_n) begin
            stall = 0;
        end else begin
            // if (stall == 0 && mem_read && !end_stall)
            //     stall = 1;
            // else stall = 0;
            stall = 0;
        end
    end
    reg end_stall;
    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            end_stall = 0;
        end else begin
            if (stall) begin
                end_stall = 1;
            end else begin
                end_stall = 0;
            end
        end
    end

endmodule
