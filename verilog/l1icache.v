`timescale 1ns / 1ps

module l1icache(
    input sys_clk,
    input rst_n,
    
    // L1 Interface
    input l1_read,
    input [31:0] l1_addr,
    output [31:0] l1_data_o,
    output hit,
    output stall,

    // MMU Interface
    output l1_mmu_req_read,
    output [31:0] l1_mmu_req_addr,      // the lower 5bit is ignored if cached
    
    input mmu_l1_done,
    input [255:0] mmu_l1_read_data,

    input sync
);
    wire c_work = l1_read;
    
    wire        addr_is_mmio;
    wire [16:0] addr_tag    = l1_addr[31:15];
    wire [9:0]  addr_idx    = l1_addr[14:5];
    wire [2:0]  addr_w_off  = l1_addr[4:2];  // word offset
    wire [1:0]  addr_b_off  = l1_addr[1:0];  // byte offset
    // cache addr: [tag 17b][idx 10b][3'b000][2'b00]

    // L1 Cache, 1024 * 32B = 32KB
    // [dirty 1b][valid 1b][tag 17b]
    wire [18:0]  c_o;
    wire         c_o_dirty    = c_o[18];
    wire         c_o_valid    = c_o[17];
    wire [16:0]  c_o_tag      = c_o[16:0];
    wire         c_hit        = c_o_valid && c_o_tag == addr_tag;
    wire [31:0]  c_o_data;

    wire [18:0]  cache_wd = {1'b0, 1'b1, addr_tag};
    wire         cache_w = c_work && !c_hit && mmu_l1_done && !addr_is_mmio;

    l1c_dismem dismem(
        .clk(~sys_clk),
        .a(addr_idx),
        .d(cache_wd),
        .we(cache_w),

        .spo(c_o)
    );
    cache_bram cb(
        .clka(~sys_clk),
        .addra(addr_idx),
        .dina(mmu_l1_read_data),
        .wea(cache_w),

        .clkb(sys_clk),
        .addrb({addr_idx, addr_w_off}),
        .doutb(c_o_data)
    );

    // Whether this address is MMIO address
    mmio_addr mmio_addr_1(
        .addr(l1_addr),
        .is_mmio(addr_is_mmio)
    );
    reg _mmio_done;
    reg [31:0] _mmio_ins_buf;
    always @(posedge sys_clk) begin
        _mmio_ins_buf <= mmu_l1_read_data[31:0];
        _mmio_done <= mmu_l1_done && addr_is_mmio;
    end
    reg _mmio_done_neg;
    always @(negedge sys_clk) _mmio_done_neg <= mmu_l1_done && addr_is_mmio;
    wire _mmio_available = _mmio_done_neg || _mmio_done;

    // L1 Interfaces
    // stall here should be sync to negedge
    assign stall = c_work && ((!addr_is_mmio && !c_hit) || (addr_is_mmio && !_mmio_available));
    // if requesting mmu, stall the pipeline
    assign l1_data_o = _mmio_done ? _mmio_ins_buf : c_o_data;
    assign hit = c_hit;
    
    // MMU Interfaces
    wire mmu_req_read_cache     = !c_hit && l1_read && !addr_is_mmio;
    // assign l1_mmu_req_write     = c_work && !c_hit &&  c_need_flush_dirty || (addr_is_mmio && l1_write);
    assign l1_mmu_req_addr      = l1_addr;
    // assign l1_mmu_write_data    = addr_is_mmio ? {224'b0, l1_write_data}: c_o_data;

    reg mmu_rcache_pos_sync;
    always @(posedge sys_clk) mmu_rcache_pos_sync <= mmu_req_read_cache;
    // mmu_req_read_cache is changed at negedge, so sync it to posedge

    assign l1_mmu_req_read = mmu_rcache_pos_sync && !addr_is_mmio || (addr_is_mmio && l1_read && !_mmio_done);
endmodule
