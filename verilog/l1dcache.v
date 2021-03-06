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
    input  out_stall,

    input is_sync_ins,
    input [4:0] sync_type,

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
    wire        addr_h_word = l1_addr[2];    // access high word
    // cache addr: [tag 17b][idx 10b][3'b000][2'b00]

    reg write_through;
    always @(posedge sys_clk) begin
        if (!rst_n) write_through <= 1;
        else begin
            if (is_sync_ins && sync_type == 5'b10000)        // disable write through mode
                write_through <= 0;
            else if (is_sync_ins && sync_type == 5'b10001)   // enable write through mode
                write_through <= 1;
            else
                write_through <= write_through;
        end
    end

    // L1 Cache, 1024 * 32B = 32KB
    // [dirty 1b][valid 1b][tag 17b]
    wire [16:0] c_wd_tag        = c_flush_dirty ? 17'b0 : addr_tag;                                     // tag
    wire [1:0]  c_wd_st         = c_flush_dirty ? 2'b00 : (!c_hit ? 2'b01 : {!write_through, 1'b1});    // status bits. when write_through, never mark dirty
    wire [18:0] cache_wd        = {c_wd_st, c_wd_tag};  // Distributed RAM write data: cache status + tag
    wire        cache_w;                                // Distributed RAM write control signal
    wire [18:0] c_o;
    l1c_dismem dismem(
        .clk(sys_clk),
        .a(addr_idx),
        .d(cache_wd),
        .we(cache_w),
        .spo(c_o));
    reg [3:0]   bram_w_type;                                    // byte write enable 
    reg [31:0]  bram_w_word;                                    // the word write into cache
    wire [63:0] bram_w_dword = {bram_w_word, bram_w_word};      // simply duplicate it, control write through wea
    wire        bram_w_port_a;                                  // Port A write enable
    wire        bram_w_port_b;                                  // Port B write enable
    wire [31:0] bram_w_port_a_ext   = {32{bram_w_port_a}};
    wire [7:0]  bram_w_port_b_ext  = bram_w_port_b ? (addr_h_word ? {bram_w_type, 4'b0} : {4'b0, bram_w_type}) : 8'b0;
    wire [63:0] bram_dout;                                      // Port B read out
    wire [255:0] bram_cl_out;                                   // Port A read out
    dcache_bram cb(
        .clka(sys_clk),
        .addra(addr_idx),
        .dina(mmu_l1_read_data),
        .douta(bram_cl_out),
        .wea(bram_w_port_a_ext),

        .clkb(sys_clk),
        .addrb({addr_idx, addr_w_off[2:1]}),
        .dinb(bram_w_dword),
        .doutb(bram_dout),
        .web(bram_w_port_b_ext)
    );

    wire [31:0] bram_out        = addr_h_word ? bram_dout[63:32] : bram_dout[31:0];
    wire        c_o_dirty       = c_o[18];
    wire        c_o_valid       = c_o[17];
    wire [16:0] c_o_tag         = c_o[16:0];
    wire        c_hit           = c_o_valid && c_o_tag == addr_tag;
    wire        c_flush_dirty   = c_o_dirty && c_o_valid && c_o_tag != addr_tag;
    // need to write back the dirty cache line first, then read out the new cache line

    wire        c_write_through = c_work && c_hit && write_through && l1_write && !mmu_l1_done;
    reg         c_write_through_d0;
    always @(posedge sys_clk) c_write_through_d0 <= c_write_through;
    // Wait one clock to write into cache and read out

    wire need_flush_dirty = c_flush_dirty && c_work;
    reg flush_dirty_delayed;
    always @(posedge sys_clk) flush_dirty_delayed <= need_flush_dirty;
    wire flush_dirty_set_mmu_write = flush_dirty_delayed && need_flush_dirty;
    // Delay a clk to set MMU Write. A clk is needed to read out the cache line from Port A

    // Whether this address is MMIO address
    mmio_addr mmio_addr_1(
        .addr(l1_addr),
        .is_mmio(addr_is_mmio)
    );

    wire can_read = !addr_is_mmio && c_work && c_hit && l1_read && !can_read_d0;
    reg can_read_d0;
    always @(posedge sys_clk) can_read_d0 <= can_read;
    wire read_stall = can_read && !can_read_d0;
    // Read Operation needs two clock, A clk is needed to read out data from Port B
    // TODO: Make BRAM works at negedge, to optimize read latency

    wire disable_write_cache_wt = write_through && c_write_through_d0;
    // disable write to bram from port B during flush cache line under write through mode

    assign bram_w_port_a = !addr_is_mmio && c_work && !c_hit && !c_flush_dirty && mmu_l1_done;
    // Retrive new cache line, flush bram at posedge after next clock to posedge mmu_done
    
    assign bram_w_port_b = !addr_is_mmio && c_work && c_hit && l1_write && !disable_write_cache_wt;
    // write to cache line from Port B, when write hit

    assign cache_w = !addr_is_mmio && c_work && (c_hit && l1_write || !c_hit && mmu_l1_done) && !disable_write_cache_wt;
    // write to cache metadata, 1. after hit & write, 2. after unhit & read done
    
    wire   write_after_mmu_read = c_work && !addr_is_mmio && l1_write && !c_hit;

    // Stage MMIO data
    reg        mmio_done;
    reg [31:0] mmio_data;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            mmio_done <= 0;
            mmio_data <= 32'b0;
        end else begin
            if (addr_is_mmio && (l1_read || l1_write)) begin
                if (!mmio_done) begin
                    mmio_done <= mmu_l1_done;
                    mmio_data <= mmu_l1_read_data[31:0];
                end else begin
                    if (out_stall) begin
                        mmio_done <= mmio_done;
                        mmio_data <= mmio_data;
                    end else begin
                        mmio_done <= 0;
                        mmio_data <= 32'b0;
                    end
                end
            end else begin
                mmio_done <= 0;
                mmio_data <= 32'b0;
            end
        end
    end

    // L1 Interfaces
    // stall : read not hit          :  down immd after mmu_read_done, but contains read_stall
    //       : write not hit         :  down immd after mmu_read_done
    //       : read not hit && dirty :  down immd after mmu_read_done, but contains read_stall
    assign stall                = c_work && (
                                                (!addr_is_mmio && (
                                                    !c_hit
                                                    || (c_write_through && !mmu_l1_done) 
                                                    || write_after_mmu_read
                                                    || read_stall
                                                ))
                                             || (addr_is_mmio && !mmio_done));
    assign l1_data_o            = addr_is_mmio ? mmio_data : bram_out;
    
    // MMU Interfaces
    assign l1_mmu_req_read      = !addr_is_mmio && c_work && !c_hit && !c_flush_dirty || (addr_is_mmio && l1_read && !mmio_done);
    assign l1_mmu_req_write     = !addr_is_mmio && c_work && ((!c_hit && flush_dirty_set_mmu_write) || (c_write_through_d0)) || (addr_is_mmio && l1_write && !mmio_done);
    assign l1_mmu_req_addr      = (!addr_is_mmio && (c_flush_dirty || c_write_through_d0)) ? {c_o_tag, addr_idx, 5'b00000} : l1_addr;
    assign l1_mmu_write_data    = addr_is_mmio ? {224'b0, l1_write_data}: bram_cl_out;

    always @* begin
        // 00: sb, 01: sh, 10: undefined, 11: sw
        casex ({l1_write_type, l1_addr[1:0]})
            4'b0000 : bram_w_type = 4'b0001;
            4'b0001 : bram_w_type = 4'b0010;
            4'b0010 : bram_w_type = 4'b0100;
            4'b0011 : bram_w_type = 4'b1000;
            4'b010x : bram_w_type = 4'b0011;
            4'b011x : bram_w_type = 4'b1100;
            4'b10xx : bram_w_type = 4'b0000;
            4'b11xx : bram_w_type = 4'b1111;
            default : bram_w_type = 4'b0000;
        endcase
        casex ({l1_write_type, l1_addr[1:0]})
            4'b0000 : bram_w_word = {24'b0, l1_write_data[7:0]};
            4'b0001 : bram_w_word = {16'b0, l1_write_data[7:0], 8'b0};
            4'b0010 : bram_w_word = {8'b0, l1_write_data[7:0], 16'b0};
            4'b0011 : bram_w_word = {l1_write_data[7:0], 24'b0};
            // TODO: Optimize it to 4'b00xx : bram_w_word = {l1_write_data[7:0], l1_write_data[7:0], l1_write_data[7:0], l1_write_data[7:0]};
            4'b010x : bram_w_word = {16'b0, l1_write_data[15:0]};
            4'b011x : bram_w_word = {l1_write_data[15:0], 16'b0};
            // TODO: Optimize it to 4'b01xx : bram_w_word = {l1_write_data[15:0], l1_write_data[15:0]};
            4'b10xx : bram_w_word = 32'b0;
            4'b11xx : bram_w_word = l1_write_data;
            default : bram_w_word = 32'b0;
        endcase
    end

endmodule
