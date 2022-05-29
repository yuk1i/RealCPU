`timescale 1ns / 1ps
module mmio_btn(
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
    input [4:0] button_pins 
);
    // 5 switches
    // Address:     // Button  : 0xFFFF0200 - 0xFFFF027F 32 words, 128 bytes
    // 0b1111111111111111 000000100 00000 00
    // 0b1111111111111111 000000100 11111 11
    wire [4:0] _addr = mmio_addr[6:2];
    assign mmio_work = mmio_addr[31:16] == 16'HFFFF && mmio_addr[15:7] == 9'b000000100;
    
    wire [31:0] button_status;

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
                mmio_read_data <= {31'b0, button_status[_addr]};
            end else begin
                mmio_done <= mmio_done;
                mmio_read_data <= 0;
            end
        end
    end

    debounce d0(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .btn_input(button_pins[0]),
        .status(button_status[0])
    );
    debounce d1(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .btn_input(button_pins[1]),
        .status(button_status[1])
    );
    debounce d2(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .btn_input(button_pins[2]),
        .status(button_status[2])
    );
    debounce d3(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .btn_input(button_pins[3]),
        .status(button_status[3])
    );
    debounce d4(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .btn_input(button_pins[4]),
        .status(button_status[4])
    );


endmodule
