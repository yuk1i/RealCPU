`timescale 1ns / 1ps


module sim_ifetch();
    reg sys_clk;
    reg rst_n;
    wire [31:0] ins_out;
    wire [31:0] pc_out;
    initial begin 
        sys_clk = 0;
        rst_n = 0;
        #8 rst_n = 1;
    end

    always #5 sys_clk = ~sys_clk;

    ifetch fetch(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .ins_out(ins_out),
        .pc_out(pc_out)
        );

endmodule
