`timescale 1ns / 1ps
module mmio_switch(
    input sys_clk,
    input rst_n,
    
    input mmio_read,
    input mmio_write,
    input [31:0] mmio_addr,
    input [31:0] mmio_write_data,

    output mmio_work,
    output reg mmio_done,
    output reg [31:0] mmio_read_data,

    // IO Pins
    input [23:0] switches_pin 
);
    // 24 switches
    // Address: 0xFFFF0000 - 0xFFFF007F, 32 words, 128 bytes, last 7 bits, last 2 bits remain 0
    wire [4:0] _addr = mmio_addr[6:2];
    assign mmio_work = mmio_addr[31:16] == 16'HFFFF && mmio_addr[15:7] == 9'b0;
    
    reg [23:0] sw_reg;
    always @(posedge sys_clk) sw_reg <= switches_pin;

    wire [31:0] _ext = {8'b0, sw_reg};

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            mmio_done <= 0;
            mmio_read_data <= 0;
        end else begin
            if (mmio_done) begin
                mmio_done <= 0;
                mmio_read_data <= 0;
            end else if (mmio_write) begin
                mmio_done <= 1; // do not support write
                mmio_read_data <= 0;
            end else if(mmio_read) begin
                mmio_done <= 1;
                mmio_read_data <= {31'b0, _ext[_addr]};
            end else begin
                mmio_done <= mmio_done;
                mmio_read_data <= 0;
            end
        end
    end

endmodule
