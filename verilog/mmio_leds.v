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
    output reg [31:0] mmio_read_data,

    // IO Pins
    output [23:0] leds_pin 
);
    // 24 switches
    // Address: 0xFFFF0080 - 0xFFFF00FF, 32 words, 128 bytes, last 7 bits, last 2 bits ignored
    //          0b1_0000000
    wire [4:0] _addr = mmio_addr[6:2];
    assign mmio_work = mmio_addr[31:16] == 16'HFFFF && mmio_addr[15:7] == 9'b00000000_1;
    
    reg [31:0] _leds_reg;

    assign leds_pin = _leds_reg[23:0];

    always @(posedge sys_clk,negedge rst_n) begin
        if (!rst_n) begin
            _leds_reg <= 0;
        end else begin
            _leds_reg <= _leds_reg;
            if (mmio_work && mmio_write && !mmio_done)
                _leds_reg[_addr] <= mmio_write_data[0];
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
                mmio_read_data <= {31'b0, _leds_reg[_addr]};
            end else begin
                mmio_done <= mmio_done;
                mmio_read_data <= 0;
            end
        end
    end

endmodule
