`timescale 1ns / 1ps
module l1mmu(
    input sys_clk,
    input rst_n,
    
    input l1_mmu_req_read,
    input l1_mmu_req_write,
    input [31:0] l1_mmu_req_addr,
    input [255:0] l1_mmu_write_data,

    output reg mmu_l1_read_done,
    output reg mmu_l1_write_done,
    output reg [255:0] mmu_l1_read_data,

    output mmu_mmio_write,
    output mmu_mmio_read,
    output [31:0] mmu_mmio_addr,
    input  mmu_mmio_hit,
    input  [31:0] mmu_mmio_data
);
    wire l1_addr_mmio;
    // Whether this address is MMIO address
    mmio_addr mmio_addr_l1addr(
        .addr(l1_mmu_req_addr),
        .is_mmio(l1_addr_mmio)
    );
    
endmodule
