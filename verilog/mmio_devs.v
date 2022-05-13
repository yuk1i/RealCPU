`timescale 1ns / 1ps
module mmio_devs(
    input sys_clk,
    input rst_n,
    
    input l1_mmu_req_read,
    input l1_mmu_req_write,
    input [31:0] l1_mmu_req_addr,
    input [31:0] l1_mmu_write_data,

    output mmu_l1_read_done,
    output mmu_l1_write_done,
    output [31:0] mmu_l1_read_data
);
    wire l1_addr_mmio;
    // Whether this address is MMIO address
    mmio_addr mmio_addr_l1addr(
        .addr(l1_mmu_req_addr),
        .is_mmio(l1_addr_mmio)
    );
    

endmodule
