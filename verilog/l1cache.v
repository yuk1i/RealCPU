`timescale 1ns / 1ps

module l1cache(
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

    input mmu_l1_read_done,
    input mmu_l1_write_done,
    input [255:0] mmu_l1_read_data
);
    parameter SIZE=511;
    wire c_work = l1_read || l1_write;
    
    wire        addr_mmio;
    wire [16:0] addr_tag    = l1_addr[31:15];
    wire [9:0]  addr_idx    = l1_addr[14:5];
    wire [2:0]  addr_w_off  = l1_addr[4:2];  // word offset
    wire [1:0]  addr_b_off  = l1_addr[1:0];  // byte offset
    // cache addr: [tag 17b][idx 10b][3'b000][2'b00]

    // L1 Cache, 1024 * 32B = 32KB
    // [dirty 1b][valid 1b][tag 17b]
    reg [18:0]  cache_wd;
    reg cache_w;
    wire [18:0] c_o;
    l1c_dismem dismem(
        .clk(~sys_clk),
        .a(addr_idx),
        .d(cache_wd),
        .we(cache_w),

        .spo(c_o)
    );

    wire [255:0] c_o_data;
    reg bram_w;
    reg [255:0] nw_cache_line;

    cache_bram cb(
        .clka(~sys_clk),
        .addra(addr_idx),
        .dina(nw_cache_line),
        .wea(bram_w),

        .clkb(sys_clk),
        .addrb({addr_idx, addr_w_off}),
        .doutb(c_o_data)
    );

    wire         c_o_dirty    = c_o[18];
    wire         c_o_valid    = c_o[17];
    wire [16:0]  c_o_tag      = c_o[16:0];
    
    wire c_hit                = c_o_valid && c_o_tag == addr_tag;
    wire c_need_flush_dirty   = c_o_dirty && c_o_valid && c_o_tag != addr_tag;
    // need to write back cache line first, then read out new cache line

    // Whether this address is MMIO address
    mmio_addr mmio_addr_1(
        .addr(l1_addr),
        .is_mmio(addr_mmio)
    );

    wire [255:0] write_src = c_hit ? c_o_data : mmu_l1_read_data;
    // when hit, use local cache to write

    wire [31:0] current_word = write_src[addr_w_off*32+:32];

    reg [31:0] nw_word; // only valid when cache is hit
    always @* begin
        casex ({l1_write_type, addr_b_off})
            4'b11xx : nw_word = l1_write_data;                              // sw
            4'b010x : nw_word = {current_word[31:16], l1_write_data[15:0]};     // sh, lower 0
            4'b011x : nw_word = {l1_write_data[15:0], current_word[15:0]};     // sh, lower 1
            4'b0000 : nw_word = {current_word[31:8],    l1_write_data[7:0]};
            4'b0001 : nw_word = {current_word[31:16],   l1_write_data[7:0], current_word[7:0]};
            4'b0010 : nw_word = {current_word[31:24],   l1_write_data[7:0], current_word[15:0]};
            4'b0011 : nw_word = {l1_write_data[7:0], current_word[23:0]};
            4'b10xx : nw_word = 32'b0;
        endcase
    end
    always @* begin
        case(addr_w_off)
            3'b000 : nw_cache_line = {write_src[255:32], nw_word};
            3'b001 : nw_cache_line = {write_src[255:1*32+32], nw_word, write_src[1*32-1:0]};
            3'b010 : nw_cache_line = {write_src[255:2*32+32], nw_word, write_src[2*32-1:0]};
            3'b011 : nw_cache_line = {write_src[255:3*32+32], nw_word, write_src[3*32-1:0]};
            3'b100 : nw_cache_line = {write_src[255:4*32+32], nw_word, write_src[4*32-1:0]};
            3'b101 : nw_cache_line = {write_src[255:5*32+32], nw_word, write_src[5*32-1:0]};
            3'b110 : nw_cache_line = {write_src[255:6*32+32], nw_word, write_src[6*32-1:0]};
            3'b111 : nw_cache_line = {nw_word, write_src[223:0]};
        endcase
    end

    parameter   STATUS_IDLE                 = 2'b00,
                STATUS_WAIT_READ            = 2'b01,
                STATUS_WAIT_WRITE           = 2'b10,
                STATUS_WAIT_READ_THEN_WRITE = 2'b11;

    reg [1:0] status;
    reg [31:0] mmio_ret;

    always @(negedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            mmio_ret <= 32'b0;
        end else begin
            if (addr_mmio && mmu_l1_read_done)
                mmio_ret <= mmu_l1_read_data[31:0];
            else
                mmio_ret <= mmio_ret;
        end
    end
    reg read_then_write;
    always @(negedge sys_clk, negedge rst_n) begin
        if (!rst_n) read_then_write = 0;
        else begin 
            if (l1_write) read_then_write <= 1;
            else read_then_write <= 0;
        end
    end
    // Driven 
    always @(posedge sys_clk) begin
        if (addr_mmio || !c_work)
            bram_w = 0;
        else begin
            if (c_hit) begin
                bram_w = read_then_write;
            end else begin
                if (c_need_flush_dirty) bram_w = 0;
                else bram_w = mmu_l1_read_done;
            end
        end
    end
    always @(posedge sys_clk) begin
        if (addr_mmio || !c_work) begin
            cache_wd = 19'b0;
            cache_w = 0;
        end else begin
            if (c_hit && l1_write) begin 
                cache_wd = {1'b1, c_o[17:0]};
                cache_w = 1;
            end else if (status == STATUS_WAIT_READ && mmu_l1_read_done) begin
                cache_wd = {1'b0, 1'b1, addr_tag};
                cache_w = 1;
            end else if (status == STATUS_WAIT_WRITE && mmu_l1_write_done) begin
                cache_wd = {1'b1, c_o[17:0]};
                cache_w = 1;
            end else begin
                cache_wd = 19'b0;
                cache_w = 0;
            end
        end
    end

    // L1 Interfaces
    assign stall = (!c_hit || (addr_mmio && !mmu_l1_read_done)) && c_work ;
    // if requesting mmu, stall the pipeline
    assign l1_data_o = c_hit ? c_o_data[addr_w_off*32+:32] : mmio_ret;
    
    // MMU Interfaces
    assign l1_mmu_req_read      = c_work && !c_hit && !c_need_flush_dirty || (addr_mmio && l1_read);
    assign l1_mmu_req_write     = c_work && !c_hit &&  c_need_flush_dirty || (addr_mmio && l1_write);
    assign l1_mmu_req_addr      = (!addr_mmio && c_need_flush_dirty && status != STATUS_WAIT_READ) ? {c_o_tag, addr_idx, 5'b00000} : l1_addr;
    assign l1_mmu_write_data    = addr_mmio ? {224'b0, l1_write_data}: c_o_data;

    integer i;
    always @(negedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            status <= STATUS_IDLE;
            // cache_wd <= 19'b0;
            // cache_w <= 0;
        end else begin
            if (addr_mmio) begin
                status <= STATUS_IDLE;
                // cache_wd <= cache_wd;
                // cache_w <= 0;
            end else begin
                if (status == STATUS_IDLE) begin
                    // IDLE
                    if (c_work) begin
                        if (!c_hit) begin
                            // working and cache not hit
                            if (c_need_flush_dirty) begin
                                // write data first, dirty data is already in c_o_data
                                status <= STATUS_WAIT_WRITE;
                                // cache_wd <= cache_wd;
                                // cache_w <= 0;
                            end else begin
                                // no need write dirty, just read from mmu
                                status <= STATUS_WAIT_READ;
                                // cache_wd <= cache_wd;
                                // cache_w <= 0;
                            end
                        end else begin
                            status <= STATUS_IDLE;
                            // working, cache hit
                            if (l1_write) begin
                                // write, set dirty to 1
                                // cache_wd <= {1'b1, c_o[17:0]};
                                // cache_w <= 1;
                            end else begin 
                                // cache_wd <= cache_wd;
                                // cache_w <= 0;
                            end
                        end
                    end else begin
                        // IDLE, not working
                        status <= status;
                        // cache_wd <= cache_wd;
                        // cache_w <= 0;
                    end
                end else if (status == STATUS_WAIT_READ) begin
                    // read from mmu
                    if (mmu_l1_read_done) begin
                        status <= STATUS_IDLE;
                        // cache it
                        // cache_wd <= {1'b0, 1'b1, addr_tag};
                        // cache_w <= 1;
                    end else begin
                        status <= status;
                        // cache_wd <= c_o;
                        // cache_w <= 0;
                    end
                end else if (status == STATUS_WAIT_WRITE) begin
                    if (mmu_l1_write_done) begin
                        status <= STATUS_WAIT_READ;
                        // make it not dirty
                        // cache_wd <= {1'b1, c_o[17:0]};
                        // cache_w <= 1;
                    end else begin
                        status <= status;
                        // cache_wd <= c_o;
                        // cache_w <= 0;
                    end
                end
            end
        end
    end

endmodule
