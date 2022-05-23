`timescale 1ns / 1ps

module l1icache(
    input sys_clk,
    input rst_n,
    
    // L1 Interface
    input l1_read,
    input [31:0] l1_addr,
    output [31:0] l1_data_o,
    output miss_stall,
    output invalid_stall,

    input out_req_stall,          
    // li1cache should hold instruction from MMIO if out_req_stall

    // MMU Interface
    output l1_mmu_req_read,
    output [31:0] l1_mmu_req_addr,      // the lower 5bit is ignored if cached
    
    input mmu_l1_done,
    input [255:0] mmu_l1_read_data,

    input is_sync_ins,
    input [4:0] sync_type
);
    wire c_work = l1_read;
    
    wire        addr_is_mmio;
    wire [16:0] addr_tag    = l1_addr[31:15];
    wire [9:0]  addr_idx    = !invalid_cache ? l1_addr[14:5] : inv_cnt;
    wire [2:0]  addr_w_off  = l1_addr[4:2];  // word offset
    wire [1:0]  addr_b_off  = l1_addr[1:0];  // byte offset
    // cache addr: [tag 17b][idx 10b][3'b000][2'b00]

    // L1 Cache, 1024 * 32B = 32KB
    // [dirty 1b][valid 1b][tag 17b]
    wire [18:0]  c_o;
    wire         c_o_dirty  = c_o[18];
    wire         c_o_valid  = c_o[17];
    wire [16:0]  c_o_tag    = c_o[16:0];
    wire         c_hit      = c_o_valid && c_o_tag == addr_tag;
    wire [31:0]  c_o_data;

    wire [18:0]  cache_wd   = !invalid_cache ? {1'b0, 1'b1, addr_tag} : 19'b0;
    wire         cache_w    = invalid_cache || c_work && !c_hit && mmu_l1_done && !addr_is_mmio;

    // invalid cache
    wire invalid_ins = is_sync_ins && sync_type == 5'b00001;
    wire invalid_cache = status == STATUS_WORK;
    reg [1:0] status;
    reg [9:0] inv_cnt;
    localparam  STATUS_IDLE = 2'b00,
                STATUS_WORK = 2'b01,
                STATUS_DONE = 2'b10;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            status <= STATUS_IDLE;
            inv_cnt <= 10'b0;
        end else begin
            case (status)
                STATUS_IDLE: begin
                    if (invalid_ins)
                        status <= STATUS_WORK;
                    else 
                        status <= status;
                    inv_cnt <= 0;
                end
                STATUS_WORK: begin
                    inv_cnt <= inv_cnt + 1;
                    if (inv_cnt == 10'd1023)
                        status <= STATUS_DONE;
                    else
                        status <= status;
                end
                STATUS_DONE: begin
                    inv_cnt <= 0;
                    status <= STATUS_IDLE;
                end
                default: begin
                    inv_cnt <= 0;
                    status <= STATUS_IDLE;
                end
            endcase
        end
    end
    assign invalid_stall = invalid_ins && status != STATUS_DONE;

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
    reg [31:0] _mmio_ins_addr;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            _mmio_ins_buf <= 32'b0;
            _mmio_ins_addr <= 32'b0;
            _mmio_done <= 1'b0;
        end else begin
            if ((out_req_stall || invalid_stall) && addr_is_mmio) begin
                // MMIO ins should be held when outside requests stall or l1i is invaliding 
                _mmio_ins_buf <= _mmio_ins_buf;
                _mmio_done <= _mmio_done;
                _mmio_ins_addr <= _mmio_ins_addr;
            end else begin
                _mmio_ins_buf <= mmu_l1_read_data[31:0];
                _mmio_done <= mmu_l1_done && addr_is_mmio;
                _mmio_ins_addr <= l1_addr;
            end
        end
    end
    reg _mmio_done_neg;
    always @(negedge sys_clk) begin
        if (!rst_n) 
            _mmio_done_neg <= 0;
        else
            _mmio_done_neg <= mmu_l1_done && addr_is_mmio;
    end
    wire _mmio_available = _mmio_done_neg || _mmio_done && l1_addr == _mmio_ins_addr;

    // L1 Interfaces
    // miss stall should be sync to negedge when l1_addr changed
    assign miss_stall = (c_work && ((!addr_is_mmio && !c_hit) || (addr_is_mmio && !_mmio_available)));
    // if requesting mmu, stall the pipeline
    assign l1_data_o = _mmio_done ? _mmio_ins_buf : c_o_data;
    
    // MMU Interfaces
    wire mmu_req_read_cache     = !c_hit && l1_read && !addr_is_mmio;
    // assign l1_mmu_req_write     = c_work && !c_hit &&  c_need_flush_dirty || (addr_is_mmio && l1_write);
    assign l1_mmu_req_addr      = l1_addr;
    // assign l1_mmu_write_data    = addr_is_mmio ? {224'b0, l1_write_data}: c_o_data;

    reg mmu_rcache_pos_sync;
    always @(posedge sys_clk) mmu_rcache_pos_sync <= mmu_req_read_cache;
    // mmu_req_read_cache is changed at negedge, so sync it to posedge

    assign l1_mmu_req_read = (mmu_rcache_pos_sync && !addr_is_mmio) || (addr_is_mmio && mmio_read_pos);

    reg mmio_read_pos;
    always @(posedge sys_clk) begin
        mmio_read_pos <= addr_is_mmio && l1_read && !_mmio_available;
    end
endmodule
