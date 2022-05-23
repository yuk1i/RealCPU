`timescale 1ns / 1ps
module mmio_rom(
    input sys_clk,
    input rst_n,
    
    input mmio_read,
    input mmio_write,
    input [31:0] mmio_addr,
    input [31:0] mmio_write_data,

    output mmio_work,
    output reg mmio_done,
    output [31:0] mmio_read_data
);
    // ROM
    // Address: 0xFFFFE000 - 0xFFFFFFFF, 
    wire [10:0] _addr = mmio_addr[12:2];
    assign mmio_work = mmio_addr[31:16] == 16'HFFFF && mmio_addr[15:13] == 3'b111;

    wire [31:0] rom_dout;
    mmio_ROM rom(
        .clka(sys_clk),
        .addra(_addr),
        .douta(rom_dout)
    );
    assign mmio_read_data = mmio_done ? rom_dout : 32'b0;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            mmio_done <= 0;
        end else begin
            mmio_done <= (mmio_read || mmio_write) && !mmio_done && mmio_work;
            // if (mmio_done) begin
            //     mmio_done <= 0;
            // end else if (mmio_write) begin
            //     mmio_done <= 1; // do not support write
            // end else if(mmio_read) begin
            //     mmio_done <= 1;
            // end else begin
            //     mmio_done <= mmio_done;
            // end
        end
    end

endmodule
