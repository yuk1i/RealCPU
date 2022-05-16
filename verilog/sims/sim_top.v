`timescale 1ns / 1ps

module sim_top();
    reg sys_clk;
    reg rst_n;
    reg [23:0] switches_pin;

    initial begin 
        sys_clk = 0;
        rst_n = 0;
        switches_pin = 0;
        #11 rst_n = 1;

        #100 switches_pin = 24'b00000000_00000000_00000001;
        #100 switches_pin = 24'b00000000_00000000_00000011;
        #100 switches_pin = 24'b00000000_00000000_00000111;
    end

    always #5 sys_clk = ~sys_clk;
    
    top ttop(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .switches_pin(switches_pin)
    );
endmodule
