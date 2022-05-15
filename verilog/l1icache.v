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
    output reg l1_mmu_req_read,
    output [31:0] l1_mmu_req_addr,      // the lower 5bit is ignored if cached
    
    input mmu_l1_done,
    input [255:0] mmu_l1_read_data
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

    localparam  STATUS_IDLE                 = 1'b0,
                STATUS_WAITING              = 1'b1;

    reg status;

    reg _mmio_done;
    reg [31:0] _mmio_data;
    always @(negedge sys_clk, negedge rst_n, negedge addr_is_mmio, negedge c_work) begin
        if (!rst_n || !addr_is_mmio || !c_work) begin
            _mmio_done <= 0;
            _mmio_data <= 0;
        end else begin
            if (mmu_l1_done) begin
                _mmio_done <= 1;
                _mmio_data <= mmu_l1_read_data[31:0];
            end else begin
                _mmio_done <= _mmio_done;
                _mmio_data <= _mmio_data;
            end
        end
    end
    // _mmio_done signal should aligned to negedge of sys_clk, to make stall signal alignment

    // L1 Interfaces
    assign stall = c_work && ((!addr_is_mmio && !c_hit) || (addr_is_mmio && !_mmio_done));
    // if requesting mmu, stall the pipeline
    assign l1_data_o = !addr_is_mmio ? c_o_data : _mmio_data;
    assign hit = c_hit;
    
    // MMU Interfaces
    wire mmu_req_read      = (!c_hit || addr_is_mmio) && l1_read;
    // assign l1_mmu_req_write     = c_work && !c_hit &&  c_need_flush_dirty || (addr_is_mmio && l1_write);
    assign l1_mmu_req_addr      = l1_addr;
    // assign l1_mmu_write_data    = addr_is_mmio ? {224'b0, l1_write_data}: c_o_data;
    always @(posedge sys_clk)
        l1_mmu_req_read <= mmu_req_read;

    integer i;
    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n || addr_is_mmio) begin
            status <= STATUS_IDLE;
        end else begin
            if (status == STATUS_IDLE) begin
                // IDLE
                if (c_work && !c_hit) begin
                    status <= STATUS_WAITING;
                end else begin
                    // IDLE, not working
                    status <= status;
                    // cache_wd <= cache_wd;
                    // cache_w <= 0;
                end
            end else if (status == STATUS_WAITING) begin
                // read from mmu
                if (mmu_l1_done) begin
                    status <= STATUS_IDLE;
                    // cache it
                    // cache_wd <= {1'b0, 1'b1, addr_tag};
                    // cache_w <= 1;
                end else begin
                    status <= status;
                    // cache_wd <= c_o;
                    // cache_w <= 0;
                end
            end 
        end
    end

endmodule
