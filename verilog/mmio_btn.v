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
    input  [4:0]    button_pins,
    output [3:0]    keypad_scan_pins,
    input  [3:0]    keypad_detect_pins
);
    // 5 switches
    // Address:     // Button  : 0xFFFF0200 - 0xFFFF027F 32 words, 128 bytes
    // 0b1111111111111111 000000100 00000 00
    // 0b1111111111111111 000000100 11111 11
    // Address: 0xFFFF0240

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
        .can_count(1),
        .btn_input(button_pins[0]),
        .status(button_status[0])
    );
    debounce d1(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(1),
        .btn_input(button_pins[1]),
        .status(button_status[1])
    );
    debounce d2(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(1),
        .btn_input(button_pins[2]),
        .status(button_status[2])
    );
    debounce d3(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(1),
        .btn_input(button_pins[3]),
        .status(button_status[3])
    );
    debounce d4(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(1),
        .btn_input(button_pins[4]),
        .status(button_status[4])
    );

    wire [15:0] keypad;
    assign button_status[31:16] = keypad;
    assign button_status[15:5]  = 11'b0;

    reg [3:0]   keypad_scan;        // connect to row scan, 1 is valid, KP4..KP1
    wire [3:0]  keypad_detect;      // connect from column detectt, 1 is valid, KP8..KP5

    assign      keypad_scan_pins = ~keypad_scan;
    assign      keypad_detect    = ~keypad_detect_pins;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            keypad_scan <= 4'b0001;
        end else begin
            keypad_scan <= {keypad_scan[2:0], keypad_scan[3]};
        end
    end

    wire key_scan_row0 = keypad_scan[0];
    debounce key1(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row0),
        .btn_input(keypad_detect[0]),
        .status(keypad[1])
    );
    debounce key2(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row0),
        .btn_input(keypad_detect[1]),
        .status(keypad[2])
    );
    debounce key3(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row0),
        .btn_input(keypad_detect[2]),
        .status(keypad[3])
    );
    debounce keyA(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row0),
        .btn_input(keypad_detect[3]),
        .status(keypad[10])
    );

    wire key_scan_row1 = keypad_scan[1];
    debounce key4(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row1),
        .btn_input(keypad_detect[0]),
        .status(keypad[4])
    );
    debounce key5(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row1),
        .btn_input(keypad_detect[1]),
        .status(keypad[5])
    );
    debounce key6(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row1),
        .btn_input(keypad_detect[2]),
        .status(keypad[6])
    );
    debounce keyB(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row1),
        .btn_input(keypad_detect[3]),
        .status(keypad[11])
    );

    wire key_scan_row2 = keypad_scan[2];
    debounce key7(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row2),
        .btn_input(keypad_detect[0]),
        .status(keypad[7])
    );
    debounce key8(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row2),
        .btn_input(keypad_detect[1]),
        .status(keypad[8])
    );
    debounce key9(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row2),
        .btn_input(keypad_detect[2]),
        .status(keypad[9])
    );
    debounce keyC(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row2),
        .btn_input(keypad_detect[3]),
        .status(keypad[12])
    );

    wire key_scan_row3 = keypad_scan[3];
    debounce keyE(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row3),
        .btn_input(keypad_detect[0]),
        .status(keypad[14])
    );
    debounce key0(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row3),
        .btn_input(keypad_detect[1]),
        .status(keypad[0])
    );
    debounce keyF(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row3),
        .btn_input(keypad_detect[2]),
        .status(keypad[15])
    );
    debounce keyD(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .can_count(key_scan_row3),
        .btn_input(keypad_detect[3]),
        .status(keypad[13])
    );

endmodule
