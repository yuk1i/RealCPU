`timescale 1ns / 1ps

module l1dcache(
    input sys_clk,
    input rst_n,
    
    // L1 Interface
    input l1_read,
    input l1_write,
    input [31:0] l1_addr,
    input [1:0] l1_write_type, // 00: sb, 01: sh, 10: undefined, 11: sw
    input [31:0] l1_write_data,

    output [31:0] l1_data_o,
    output stall,

    // MMU Interface
    output l1_mmu_req_read,
    output l1_mmu_req_write,
    output [31:0] l1_mmu_req_addr,      // the lower 5bit is ignored if cached
    output [255:0] l1_mmu_write_data,

    input mmu_l1_done,
    input [255:0] mmu_l1_read_data
);
    wire c_work = l1_read || l1_write;
    
    wire        addr_is_mmio;
    wire [16:0] addr_tag    = l1_addr[31:15];
    wire [9:0]  addr_idx    = l1_addr[14:5];
    wire [2:0]  addr_w_off  = l1_addr[4:2];  // word offset
    wire [1:0]  addr_b_off  = l1_addr[1:0];  // byte offset
    wire        addr_h_bram = l1_addr[4];
    // cache addr: [tag 17b][idx 10b][3'b000][2'b00]

    // L1 Cache, 1024 * 32B = 32KB
    // [dirty 1b][valid 1b][tag 17b]
    wire [16:0] c_wd_tag        = c_flush_dirty ? 17'b0 : addr_tag;
    wire [1:0]  c_wd_st         = c_flush_dirty ? 2'b00 : (!c_hit ? 2'b01 : 2'b11); 
    wire [18:0] cache_wd        = {c_wd_st, c_wd_tag};
    wire        cache_w;
    wire [18:0] c_o;
    l1c_dismem dismem(
        .clk(~sys_clk),
        .a(addr_idx),
        .d(cache_wd),
        .we(cache_w),
        .spo(c_o));
    reg [3:0]   _bram_wt;
    reg [31:0]  _bram_wd;
    wire        bram_w_a;
    wire        bram_w_b;
    wire [15:0] _bram_w_a_ext   = {16{bram_w_a}};
    wire [3:0]  _bram_w_bh_ext  = bram_w_b &&  addr_h_bram ? _bram_wt : 4'b0;
    wire [3:0]  _bram_w_bl_ext  = bram_w_b && !addr_h_bram ? _bram_wt : 4'b0;
    wire [31:0] bram_h_out;
    wire [31:0] bram_l_out;
    wire [255:0] bram_cl_out;
    dcache_bram cb_high(
        .clka(~sys_clk),
        .addra(addr_idx),
        .dina(mmu_l1_read_data[255:128]),
        .douta(bram_cl_out[255:128]),
        .wea(_bram_w_a_ext),

        .clkb(~sys_clk),
        .addrb({addr_idx, addr_w_off[1:0]}),
        .dinb(_bram_wd),
        .doutb(bram_h_out),
        .web(_bram_w_bh_ext));
    dcache_bram cb_low(
        .clka(~sys_clk),
        .addra(addr_idx),
        .dina(mmu_l1_read_data[127:0]),
        .douta(bram_cl_out[127:0]),
        .wea(_bram_w_a_ext),

        .clkb(~sys_clk),
        .addrb({addr_idx, addr_w_off[1:0]}),
        .dinb(_bram_wd),
        .doutb(bram_l_out),
        .web(_bram_w_bl_ext));

    wire [31:0] bram_out        = addr_h_bram ? bram_h_out : bram_l_out;
    wire        c_o_dirty       = c_o[18];
    wire        c_o_valid       = c_o[17];
    wire [16:0] c_o_tag         = c_o[16:0];
    wire        c_hit           = c_o_valid && c_o_tag == addr_tag;
    wire        c_flush_dirty   = c_o_dirty && c_o_valid && c_o_tag != addr_tag;
    // need to write back cache line first, then read out new cache line

    reg c_flush_dirty_delayed;
    always @(posedge sys_clk) c_flush_dirty_delayed <= c_flush_dirty;
    wire c_flush_dirty_set_mmu_write = c_flush_dirty_delayed && c_flush_dirty;

    // Whether this address is MMIO address
    mmio_addr mmio_addr_1(
        .addr(l1_addr),
        .is_mmio(addr_is_mmio)
    );

    assign bram_w_a = !addr_is_mmio && c_work && !c_hit && !c_flush_dirty && mmu_l1_done;
    // Retrive new cache line, flush bram at negedge after mmu_done at posedge
    
    assign bram_w_b = c_work && c_hit && l1_write;
    // write to cache line, 

    assign cache_w = !addr_is_mmio && c_work && (c_hit && l1_write || !c_hit && mmu_l1_done);
    // write to cache metadata, 1. after 

    parameter   STATUS_IDLE     = 1'b0,
                STATUS_WAITING  = 1'b1; 
    
    // wire   read_target_done       = !c_flush_dirty && mmu_l1_done;
    wire   write_after_mmu_read   = c_work && !addr_is_mmio && l1_write && !c_hit;
    reg    write_after_mmu_read_alg;
    always @(posedge sys_clk)  write_after_mmu_read_alg <= write_after_mmu_read;
    // L1 Interfaces
    // stall : read not hit          :  down immd after mmu_read_done
    //       : write not hit         :  (write after mmu) down 1 clk delayed after mmu_read_done
    //       : read not hit && dirty :  down immd after mmu_read_done
    assign stall                = c_work && ((!addr_is_mmio && !c_hit && (c_flush_dirty_delayed || !mmu_l1_done) || write_after_mmu_read_alg) || (addr_is_mmio && !mmu_l1_done));
    assign l1_data_o            = addr_is_mmio ? mmu_l1_read_data[31:0] : bram_out;
    
    // MMU Interfaces
    assign l1_mmu_req_read      = !addr_is_mmio && c_work && !c_hit && !c_flush_dirty || (addr_is_mmio && l1_read);
    assign l1_mmu_req_write     = !addr_is_mmio && c_work && !c_hit &&  c_flush_dirty_set_mmu_write || (addr_is_mmio && l1_write);
    assign l1_mmu_req_addr      = (!addr_is_mmio && c_flush_dirty) ? {c_o_tag, addr_idx, 5'b00000} : l1_addr;
    assign l1_mmu_write_data    = addr_is_mmio ? {224'b0, l1_write_data}: bram_cl_out;

    always @* begin
        // 00: sb, 01: sh, 10: undefined, 11: sw
        casex ({l1_write_type, l1_addr[1:0]})
            4'b0000 : _bram_wt = 4'b0001;
            4'b0001 : _bram_wt = 4'b0010;
            4'b0010 : _bram_wt = 4'b0100;
            4'b0011 : _bram_wt = 4'b1000;
            4'b010x : _bram_wt = 4'b0011;
            4'b011x : _bram_wt = 4'b1100;
            4'b10xx : _bram_wt = 4'b0000;
            4'b11xx : _bram_wt = 4'b1111;
            default : _bram_wt = 4'b0000;
        endcase
        casex ({l1_write_type, l1_addr[1:0]})
            4'b0000 : _bram_wd = {24'b0, l1_write_data[7:0]};
            4'b0001 : _bram_wd = {16'b0, l1_write_data[7:0], 8'b0};
            4'b0010 : _bram_wd = {8'b0, l1_write_data[7:0], 16'b0};
            4'b0011 : _bram_wd = {l1_write_data[7:0], 24'b0};
            4'b010x : _bram_wd = {16'b0, l1_write_data[15:0]};
            4'b011x : _bram_wd = {l1_write_data[15:0], 16'b0};
            4'b10xx : _bram_wd = 32'b0;
            4'b11xx : _bram_wd = l1_write_data;
            default : _bram_wd = 32'b0;
        endcase
    end

endmodule
