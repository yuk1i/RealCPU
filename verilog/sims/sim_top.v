`timescale 1ns / 1ps

module sim_top();
    reg bank_sys_clk;
    reg bank_rst;
    reg [23:0] switches_pin;

    initial begin 
        bank_sys_clk = 0;
        bank_rst = 1;
        switches_pin = 0;
        #11 bank_rst = 0;

        #100 switches_pin = 24'b00000000_00000000_00000001;
        #100 switches_pin = 24'b00000000_00000000_00000011;
        #100 switches_pin = 24'b00000000_00000000_00000111;
    end

    always #5 bank_sys_clk = ~bank_sys_clk;
    
    top ttop(
        .bank_sys_clk(bank_sys_clk),
        .bank_rst(bank_rst),
        .switches_pin(switches_pin)
    );
endmodule
