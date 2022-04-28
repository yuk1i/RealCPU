`timescale 1ns / 1ps

module sim_top();
    reg sys_clk;
    reg rst_n;
    
    initial begin 
        sys_clk = 0;
        rst_n = 0;
        #11 rst_n = 1;
    end

    always #5 sys_clk = ~sys_clk;
    
    top ttop(
        .sys_clk(sys_clk),
        .rst_n(rst_n)
    );
endmodule
