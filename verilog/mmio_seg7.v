`timescale 1ns / 1ps
module mmio_seg7(
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
    output [7:0] seg7_bits_pin, 
    output [7:0] seg7_led_pin,
    input bank_sys_clk
);
    // 8 seg
    // Address: 0xFFFF0100 - 0xFFFF0120, 8 words, 32 bytes
    //          0b1000_00000, 0b1001_00000
    wire [2:0] _addr = mmio_addr[4:2];
    assign mmio_work = mmio_addr[31:16] == 16'HFFFF && mmio_addr[15:5] == 11'b00000001_000;
    
    reg [7:0] seg7_regs [0:7];

    integer i;
    always @(posedge sys_clk,negedge rst_n) begin
        if (!rst_n) begin
            for (i=0;i<8;i=i+1) begin
                seg7_regs[i] <= 0;
            end
        end else begin
            for (i=0;i<8;i=i+1)
                seg7_regs[i] <= seg7_regs[i];
            if (mmio_work && mmio_write && !mmio_done)
                seg7_regs[_addr] <= mmio_write_data[7:0];
        end
    end
    
    // The first clk: mmio_write==1, done==0
    // the second clk: mmio_write==1, done==1

    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            mmio_done <= 0;
            mmio_read_data <= 0;
        end else begin
            if (mmio_done) begin
                mmio_done <= 0;
                mmio_read_data <= 0;
            end else if (mmio_work) begin
                mmio_done <= 1;
                mmio_read_data <= {31'b0, seg7_regs[_addr]};
            end else begin
                mmio_done <= mmio_done;
                mmio_read_data <= 0;
            end
        end
    end

    // seg7 module

    seg7 seg7_ins(
        .clk(bank_sys_clk),
        .rst_n(rst_n),
        .numbers({seg7_regs[7],seg7_regs[6],seg7_regs[5],seg7_regs[4],seg7_regs[3],seg7_regs[2],seg7_regs[1],seg7_regs[0]}),
        .LED_BITS(seg7_bits_pin),
        .LED(seg7_led_pin)
    );

endmodule
