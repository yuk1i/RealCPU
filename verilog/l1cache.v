`timescale 1ns / 1ps

module l1cache
#( parameter SIZE = 1023 )
(
    input sys_clk,
    input rst_n,
    
    // L1 Interface
    input l1_read,
    input [31:0] l1_addr,
    input l1_write,
    input [1:0] l1_write_type, // 00: sw, 01: sh, 10: sb, 11: undefined
    input [31:0] l1_write_data,

    output [31:0] l1_data_o,
    output stall,

    // MMU Interface
    output l1_mmu_req,
    output l1_mmu_req_read,
    output l1_mmu_req_write,
    output reg [31:0] l1_mmu_req_addr,
    output reg [31:0] l1_mmu_write_data,

    input mmu_l1_read_done,
    input mmu_l1_write_done,
    input [31:0] mmu_l1_read_data
);
    wire c_work = l1_read || l1_write;

    // L1 Cache, 1024 * 4B = 4K
    // [dirty 1b][valid 1b][tag 20b][data 32b]
    reg [53:0] cache [0:SIZE];

    wire [19:0] addr_tag = l1_addr[15:12];
    wire [9:0] addr_idx = l1_addr[11:2];
    // cache addr: [tag 20b][idx 10b][2'b00]
    
    wire [53:0] c_o        = cache[addr_idx];
    wire        c_o_dirty  = c_o[53];
    wire        c_o_valid  = c_o[52];
    wire [19:0] c_o_tag    = c_o[51:32];
    wire [31:0] c_o_data   = c_o[31:0];
    
    wire c_hit = c_o_valid && c_o_tag == addr_tag;
    wire c_need_flush_dirty = c_o_dirty && c_o_valid && c_o_tag != addr_tag;
    // need to write back cache line first, then read out new cache line

    reg [31:0] need_write_data; // only valid when cache is hit
    always @* begin
        casex ({l1_write_type, l1_addr[1:0]})
            4'b00xx : need_write_data = l1_write_data;                              // sw
            4'b010x : need_write_data = {c_o_data[31:16], l1_write_data[15:0]};     // sh, lower 0
            4'b011x : need_write_data = {l1_write_data[15:0], c_o_data[15:0]};     // sh, lower 1
            4'b1000 : need_write_data = {c_o_data[31:8],    l1_write_data[7:0]};
            4'b1001 : need_write_data = {c_o_data[31:16],   l1_write_data[7:0], c_o_data[7:0]};
            4'b1010 : need_write_data = {c_o_data[31:24],   l1_write_data[7:0], c_o_data[15:0]};
            4'b1011 : need_write_data = {l1_write_data[7:0], c_o_data[23:0]};
            4'b11xx : need_write_data = 32'b0;
        endcase
    end


    parameter   STATUS_IDLE=2'b00,
                STATUS_WAIT_READ=2'b10,
                STATUS_WAIT_WRITE=2'b11;

    reg [1:0] status;

    // IDLE -- not hit --- need_write_dirty:Y --- WAIT_WRITE --- write_done --- WAIT_READ --- read_done --- IDLE 
    //                                  \---N --- WAIT_READ  --- read_done  --- IDLE

    // L1 Interfaces
    assign stall = status != STATUS_IDLE;
    // if requesting mmu, stall the pipeline
    assign l1_data_o = l1_read && c_hit ? c_o_data : 32'b0;

    // MMU Interfaces
    assign l1_mmu_req_read  = status == STATUS_WAIT_READ;
    assign l1_mmu_req_write = status == STATUS_WAIT_WRITE;
    assign l1_mmu_req       = l1_mmu_req_read || l1_mmu_req_write;

    integer i;
    always @(negedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            status <= STATUS_IDLE;
            l1_mmu_req_addr <= 32'b0;
            l1_mmu_write_data <= 32'b0;
            for (i=0;i<=SIZE;i=i+1)
                cache[i] <= 54'b0;
        end else begin
            if (status == STATUS_IDLE) begin
                // IDLE
                if (c_work && !c_hit) begin 
                    // working and cache not hit
                    if (c_need_flush_dirty) begin
                        // flush dirty cache line first
                        status <= STATUS_WAIT_WRITE;
                        l1_mmu_req_addr <= {c_o_tag, addr_idx, 2'b00};
                        l1_mmu_write_data <= c_o_data;
                    end else begin
                        // not hit, just read from mmu
                        status <= STATUS_WAIT_READ;
                        l1_mmu_req_addr <= {l1_addr[31:2], 2'b00};
                        l1_mmu_write_data <= 32'b0;
                    end
                end else begin
                    if (c_work && c_hit && l1_write) begin
                        cache[addr_idx] <= {1'b1, cache[addr_idx][52:32], need_write_data};
                    end
                    status <= STATUS_IDLE;
                    l1_mmu_req_addr <= 32'b0;
                    l1_mmu_write_data <= 32'b0;
                end
            end else if (status == STATUS_WAIT_WRITE) begin
                // waiting write result
                if (mmu_l1_write_done) begin
                    // write done, start a read
                    status <= STATUS_WAIT_READ;
                    l1_mmu_req_addr <= {l1_addr[31:1], 2'b00};
                    l1_mmu_write_data <= 32'b0;
                end else begin
                    status <= status;
                    l1_mmu_req_addr <= l1_mmu_req_addr;
                    l1_mmu_write_data <= l1_mmu_write_data;
                end
            end else if (status == STATUS_WAIT_READ) begin
                // waiting read result
                if (mmu_l1_read_done) begin
                    status <= STATUS_IDLE;
                    l1_mmu_req_addr <= 32'b0;
                    l1_mmu_write_data <= 32'b0;
                    // read done, write it to cache
                    cache[addr_idx] <= {1'b0, 1'b1, addr_tag, mmu_l1_read_data};
                end else begin
                    status <= status;
                    l1_mmu_req_addr <= l1_mmu_req_addr;
                    l1_mmu_write_data <= l1_mmu_write_data;
                end
            end
        end
    end

endmodule
