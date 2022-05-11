`timescale 1ns / 1ps

module l1cache(
    input sys_clk,
    input rst_n,
    
    // L1 Interface
    input l1_read,
    input l1_write,
    input [31:0] l1_addr,
    input [1:0] l1_write_type, // 00: sw, 01: sh, 10: sb, 11: undefined
    input [31:0] l1_write_data,

    output [31:0] l1_data_o,
    output stall,

    // MMU Interface
    output l1_mmu_req_read,
    output l1_mmu_req_write,
    output reg [31:0] l1_mmu_req_addr,      // the lower 5bit is ignored if cached
    output reg [255:0] l1_mmu_write_data,

    input mmu_l1_read_done,
    input mmu_l1_write_done,
    input [255:0] mmu_l1_read_data
);
    parameter SIZE=1023;
    wire c_work = l1_read || l1_write;

    // L1 Cache, 1024 * 32B = 32KB
    // [dirty 1b][valid 1b][tag 17b][data 256b]
    reg [274:0] cache [0:SIZE];

    wire [16:0] addr_tag    = l1_addr[31:15];
    wire [9:0]  addr_idx    = l1_addr[14:5];
    wire [2:0]  addr_w_off  = l1_addr[4:2];  // word offset
    wire [1:0]  addr_b_off  = l1_addr[1:0];  // byte offset
    // cache addr: [tag 17b][idx 10b][3'b000][2'b00]

    wire [274:0] c_o          = cache[addr_idx];
    wire         c_o_dirty    = c_o[274];
    wire         c_o_valid    = c_o[273];
    wire [16:0]  c_o_tag      = c_o[272:256];
    wire [255:0] c_o_data     = c_o[255:0];
    
    wire c_hit                = c_o_valid && c_o_tag == addr_tag;
    wire c_need_flush_dirty   = c_o_dirty && c_o_valid && c_o_tag != addr_tag;
    // need to write back cache line first, then read out new cache line

    wire addr_mmio;
    // Whether this address is MMIO address
    mmio_addr mmio_addr_1(
        .addr(l1_addr),
        .is_mmio(addr_mmio)
    );

    wire [255:0] write_src = c_hit ? c_o_data : mmu_l1_read_data;
    // when hit, use local cache to write

    wire [31:0] write_src_word = write_src[addr_w_off*32+:32];

    reg [31:0] nw_word; // only valid when cache is hit
    always @* begin
        casex ({l1_write_type, addr_b_off})
            4'b00xx : nw_word = l1_write_data;                              // sw
            4'b010x : nw_word = {write_src_word[31:16], l1_write_data[15:0]};     // sh, lower 0
            4'b011x : nw_word = {l1_write_data[15:0], write_src_word[15:0]};     // sh, lower 1
            4'b1000 : nw_word = {write_src_word[31:8],    l1_write_data[7:0]};
            4'b1001 : nw_word = {write_src_word[31:16],   l1_write_data[7:0], write_src_word[7:0]};
            4'b1010 : nw_word = {write_src_word[31:24],   l1_write_data[7:0], write_src_word[15:0]};
            4'b1011 : nw_word = {l1_write_data[7:0], write_src_word[23:0]};
            4'b11xx : nw_word = 32'b0;
        endcase
    end
    reg [255:0] nw_cache_line;
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

    // L1 Interfaces
    assign stall = status != STATUS_IDLE;
    // if requesting mmu, stall the pipeline
    assign l1_data_o = c_hit ? c_o_data : mmio_ret;
    

    // MMU Interfaces
    assign l1_mmu_req_read  = status == STATUS_WAIT_READ || status == STATUS_WAIT_READ_THEN_WRITE;
    assign l1_mmu_req_write = status == STATUS_WAIT_WRITE;

    integer i;
    always @(negedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            status <= STATUS_IDLE;
            l1_mmu_req_addr <= 32'b0;
            l1_mmu_write_data <= 32'b0;
            mmio_ret <= 32'b0;
            for (i=0;i<=SIZE;i=i+1)
                cache[i] <= 275'b0;
        end else begin
            if (status == STATUS_IDLE) begin
                // IDLE
                if (c_work) begin
                    if (addr_mmio) begin
                        if (l1_read) begin
                            // read action
                            status <= STATUS_WAIT_READ;
                            l1_mmu_req_addr <= {l1_addr[31:2], 2'b00};
                            l1_mmu_write_data <= 255'b0;
                            mmio_ret <= 32'b0;
                            for (i=0; i<=SIZE; i=i+1)
                                cache[i] <= cache[i];
                        end else begin
                            // write action
                            status <= STATUS_WAIT_WRITE;
                            l1_mmu_req_addr <= {l1_addr[31:2], 2'b00};
                            l1_mmu_write_data <= {223'b0, l1_write_data};
                            mmio_ret <= 32'b0;
                            for (i=0; i<=SIZE; i=i+1)
                                cache[i] <= cache[i];
                        end
                    end else if (!c_hit) begin
                        // working and cache not hit
                        if (c_need_flush_dirty) begin
                            // read out data first, then flush dirty cache line
                            status <= STATUS_WAIT_READ_THEN_WRITE;
                            l1_mmu_req_addr <= {l1_addr[31:2], 2'b00};
                            l1_mmu_write_data <= 255'b0;
                            mmio_ret <= 32'b0;
                            for (i=0; i<=SIZE; i=i+1)
                                cache[i] <= cache[i];
                        end else begin
                            // no need write dirty, just read from mmu
                            status <= STATUS_WAIT_READ;
                            l1_mmu_req_addr <= {l1_addr[31:2], 2'b00};
                            l1_mmu_write_data <= 255'b0;
                            mmio_ret <= 32'b0;
                            for (i=0; i<=SIZE; i=i+1)
                                cache[i] <= cache[i];
                        end
                    end else begin
                        status <= STATUS_IDLE;
                        l1_mmu_req_addr <= 32'b0;
                        l1_mmu_write_data <= 255'b0;
                        mmio_ret <= 32'b0;
                        // working, cache hit
                        if (l1_write) begin
                            // simple write
                            for (i=0; i<=SIZE; i=i+1) begin
                                if (i == addr_idx)
                                    cache[i] <= {1'b1, c_o_valid, c_o_tag, nw_cache_line};
                                else
                                    cache[i] <= cache[i];
                            end
                        end else begin
                            for (i=0; i<=SIZE; i=i+1)
                                cache[i] <= cache[i];
                        end
                    end
                end else begin
                    // IDLE, not working
                    status <= STATUS_IDLE;
                    l1_mmu_req_addr <= 32'b0;
                    l1_mmu_write_data <= 255'b0;
                    mmio_ret <= 32'b0;
                    for (i=0; i<=SIZE; i=i+1)
                        cache[i] <= cache[i];
                end
            end else if (status == STATUS_WAIT_READ_THEN_WRITE) begin
                if (mmu_l1_read_done) begin
                    // cache not hit, not MMIO addr, target read done, return data and flush dirty cache line.
                    // write dirty back
                    status <= STATUS_WAIT_WRITE;
                    l1_mmu_req_addr <= {c_o_tag, addr_idx, 5'b0};
                    l1_mmu_write_data <= c_o_data;
                    mmio_ret <= 32'b0;
                    if (l1_write) begin
                        // if request write
                        for (i=0; i<=SIZE; i=i+1) begin
                            if (i == addr_idx)
                                cache[i] <= {1'b1, 1'b1, addr_tag, nw_cache_line};
                            else
                                cache[i] <= cache[i];
                        end
                    end else begin
                        // if request read
                        for (i=0; i<=SIZE; i=i+1) begin
                            if (i == addr_idx)
                                cache[i] <= {1'b0, 1'b1, addr_tag, mmu_l1_read_data};
                            else
                                cache[i] <= cache[i];
                        end
                    end
                end else begin
                    // read not done
                    status <= status;
                    l1_mmu_req_addr <= l1_mmu_req_addr;
                    l1_mmu_write_data <= l1_mmu_write_data;
                    mmio_ret <= 32'b0;
                    for (i=0; i<=SIZE; i=i+1)
                        cache[i] <= cache[i];
                end
            end else if (status == STATUS_WAIT_READ) begin
                // read from mmu
                if (mmu_l1_read_done) begin
                    status <= STATUS_IDLE;
                    l1_mmu_req_addr <= 32'b0;
                    l1_mmu_write_data <= 255'b0;
                    if (addr_mmio) begin
                        mmio_ret <= mmu_l1_read_data[31:0];
                        for (i=0; i<=SIZE; i=i+1)
                            cache[i] <= cache[i];
                    end else begin
                        // cache it
                        mmio_ret <= 32'b0;
                        for (i=0; i<=SIZE; i=i+1) begin
                            if (i == addr_idx)
                                cache[i] <= {1'b0, 1'b1, addr_tag, mmu_l1_read_data};
                            else
                                cache[i] <= cache[i];
                        end
                    end
                end else begin
                    status <= status;
                    l1_mmu_req_addr <= l1_mmu_req_addr;
                    l1_mmu_write_data <= l1_mmu_write_data;
                    mmio_ret <= 32'b0;
                    for (i=0; i<=SIZE; i=i+1)
                        cache[i] <= cache[i];
                end
            end else if (status == STATUS_WAIT_WRITE) begin
                if (mmu_l1_write_done) begin
                    status <= STATUS_IDLE;
                    l1_mmu_req_addr <= 32'b0;
                    l1_mmu_write_data <= 255'b0;
                end else begin
                    status <= status;
                    l1_mmu_req_addr <= l1_mmu_req_addr;
                    l1_mmu_write_data <= l1_mmu_write_data;
                end
                for (i=0; i<=SIZE; i=i+1)
                    cache[i] <= cache[i];
            end
        end
    end

endmodule
