`timescale 1ns / 1ps
module mmio_devs(
    input sys_clk,
    input rst_n,
    
    input mmio_read,
    input mmio_write,
    input [31:0] mmio_addr,
    input [31:0] mmio_write_data,

    output reg mmio_done,
    output reg [31:0] mmio_read_data,

    // **** IO Pins ***** //
    // 1. Switches
    input [23:0] switches_pin,
    // 2. LEDs
    output [23:0] leds_pin,
    // 3. Seg 7
    output [7:0] seg7_bits_pin, 
    output [7:0] seg7_led_pin,
    input bank_sys_clk

);
    wire addr_is_mmio;
    // Whether this address is MMIO address
    mmio_addr mmio_addr_l1addr(
        .addr(mmio_addr),
        .is_mmio(addr_is_mmio)
    );

    wire        sw_work;
    wire        sw_done;
    wire [31:0] sw_rdata;
    mmio_switch mmio_sw(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        
        .mmio_read(mmio_read),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),

        .mmio_work(sw_work),
        .mmio_done(sw_done),
        .mmio_read_data(sw_rdata),

        .switches_pin(switches_pin)
    );

    wire        rom_work;
    wire        rom_done;
    wire [31:0] rom_rdata;
    mmio_rom mmio_rom1(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        
        .mmio_read(mmio_read),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),

        .mmio_work(rom_work),
        .mmio_done(rom_done),
        .mmio_read_data(rom_rdata)
    );

    wire        led_work;
    wire        led_done;
    wire [31:0] led_rdata;
    mmio_leds mmio_led(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        
        .mmio_read(mmio_read),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),

        .mmio_work(led_work),
        .mmio_done(led_done),
        .mmio_read_data(led_rdata),

        .leds_pin(leds_pin)
    );
    
    wire        seg7_work;
    wire        seg7_done;
    wire [31:0] seg7_rdata;
    mmio_seg7 mmio_seg7_ins(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        
        .mmio_read(mmio_read),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),

        .mmio_work(seg7_work),
        .mmio_done(seg7_done),
        .mmio_read_data(seg7_rdata),

        .seg7_bits_pin(seg7_bits_pin),
        .seg7_led_pin(seg7_led_pin),
        .bank_sys_clk(bank_sys_clk)
    );

    always @* begin
        if (addr_is_mmio) begin
            if (sw_work) begin
                mmio_done = sw_done;
                mmio_read_data = sw_rdata;
            end else if (rom_work) begin
                mmio_done = rom_done;
                mmio_read_data = rom_rdata;
            end else if (led_work) begin
                mmio_done = led_done;
                mmio_read_data = led_rdata;
            end else if (seg7_work) begin
                mmio_done = seg7_done;
                mmio_read_data = seg7_rdata;
            end else begin
                mmio_done = 0;
                mmio_read_data = 0;
            end
        end else begin
            mmio_done = 0;
            mmio_read_data = 0;
        end
    end

    // Switches: 0xFFFF0000 - 0xFFFF007F, 32 words, 128 bytes, last 7 bits, last 2 bits remain 0
    // LEDs:     0xFFFF0080 - 0xFFFF00FF, 32 words, 128 bytes, last 7 bits, last 2 bits ignored
    // SEG7      0xFFFF0100 - 0xFFFF0120, 8  words, 32 bytes
    // ROM:      
endmodule
