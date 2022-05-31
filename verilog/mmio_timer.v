`timescale 1ns / 1ps
module mmio_leds(
    input sys_clk,
    input rst_n,
    
    input mmio_read,
    input mmio_write,
    input [31:0] mmio_addr,
    input [31:0] mmio_write_data,

    output mmio_work,
    output reg mmio_done,
    output reg [31:0] mmio_read_data
);
    // Timer
    // Address: 0xFFFF0140 - 0xFFFF015F, 8  words, 32  bytes , 5 bits, last 2 bits ignored
    //       0b1010 000 00 - 0b1010 111 11
    
    // Timer 0
    // Enabled : 0xFFFF0280
    // Done    : 0xFFFF0284
    // Count Target : 0xFFFF0288
    // Current : 0xFFFF028C
    wire       timer = mmio_addr[4];
    wire [1:0] _addr = mmio_addr[3:2];
    assign mmio_work = mmio_addr[31:16] == 16'HFFFF && mmio_addr[15:5] == 11'b00000010_010 && (mmio_read || mmio_write);
    
    wire acc_enable  = mmio_work && _addr == 2'b00;
    wire acc_done    = mmio_work && _addr == 2'b01;
    wire acc_target  = mmio_work && _addr == 2'b10;
    wire acc_current = mmio_work && _addr == 2'b11;

    reg  [31:0] counter [0:1];
    wire        done    [0:1];
    wire [31:0]  

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            counter[0] <= counter[0];
            counter[1] <= counter[1];
        end else begin
            counter[0] <= counter[0];
            counter[1] <= counter[1];
            if (mmio_write && !mmio_done && acc_target)
                counter[timer] <= mmio_write_data;
        end
    end
    
    // The first clk: mmio_write==1, done==0
    // the second clk: mmio_write==1, done==1

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            mmio_done <= 0;
        end else begin
            mmio_done <= mmio_work && !mmio_done;
        end
    end
    
    always @* begin
        if (acc_enable)         mmio_read_data = {31'b0, !rx_fifo_empty};
        else if (acc_done)      mmio_read_data = {24'b0, rx_fifo_r_dout};
        else if (acc_target)    mmio_read_data = {31'b0, !tx_fifo_empty};
        else if (acc_current)   mmio_read_data = {31'b0, tx_fifo_full};
        else mmio_read_data = 32'b0;
    end

endmodule
