`timescale 1ns / 1ps
module mmio_devs(
    input sys_clk,
    input rst_n,
    
    input mmio_read,
    input mmio_write,
    input [31:0] mmio_addr,
    input [31:0] mmio_write_data,

    output mmio_done,
    output [31:0] mmio_read_data
);
    wire l1_addr_mmio;
    // Whether this address is MMIO address
    mmio_addr mmio_addr_l1addr(
        .addr(mmio_addr),
        .is_mmio(l1_addr_mmio)
    );

    assign mmio_done = 1;
    assign mmio_read_data = 32'h00FFA012;
    

endmodule
