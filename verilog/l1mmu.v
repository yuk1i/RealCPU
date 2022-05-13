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
    output [31:0] mmu_mmio_write_data,
    input  mmu_mmio_done,
    input  [31:0] mmu_mmio_read_data
);
    wire l1_addr_mmio;
    // Whether this address is MMIO address
    mmio_addr mmio_addr_l1addr(
        .addr(l1_mmu_req_addr),
        .is_mmio(l1_addr_mmio)
    );

    assign mmu_mmio_read = l1_addr_mmio && l1_mmu_req_read;
    assign mmu_mmio_write = l1_addr_mmio && l1_mmu_req_write;
    assign mmu_mmio_addr = {l1_mmu_req_addr[31:2], 2'b00};
    assign mmu_mmio_write_data = l1_mmu_write_data[31:0];
    
    reg acc_hi;
    reg [127:0] tmp_low;
    wire [31:0] _req_addr = !l1_addr_mmio ? {l1_mmu_req_addr[31:5], acc_hi, 4'b0} : 32'b0;
    wire [127:0] _dout;
    wire [127:0] _wr_data = acc_hi ? l1_mmu_write_data[255:128] : l1_mmu_write_data[127:0];
    wire mig_write = !l1_addr_mmio && l1_mmu_req_write;

    mem_fake_mig fake_mig(
        .clka(sys_clk),
        .addra(_req_addr),
        .douta(_dout),
        .dina(_wr_data),
        .wea(mig_write)
    );

    reg status;

    localparam  STATUS_IDLE = 1'b0,
                STATUS_WAIT = 1'b1;

    always @(negedge sys_clk, negedge rst_n) begin
        if (~rst_n) begin
            acc_hi <= 0;
            status <= STATUS_IDLE;
            tmp_low <= 128'b0;
            mmu_l1_read_done <= 0;
            mmu_l1_write_done <= 0;
            mmu_l1_read_data <= 256'b0;
        end else begin
            if (l1_addr_mmio) begin
                // MMIO Requests
                status <= STATUS_IDLE;
                tmp_low <= 0;
                acc_hi <= 0;
                mmu_l1_read_done <= mmu_mmio_done;
                mmu_l1_write_done <= mmu_mmio_done;
                mmu_l1_read_data <= {224'b0, mmu_mmio_read_data};
            end else begin
                if (l1_mmu_req_read) begin
                    if (status==STATUS_IDLE && !mmu_l1_read_done) begin
                        // the low read is already done
                        status <= STATUS_WAIT;
                        tmp_low <= _dout;
                        acc_hi <= 1;
                        mmu_l1_read_done <= 0;
                        mmu_l1_write_done <= 0;
                        mmu_l1_read_data <= 256'b0;
                    end else if (status == STATUS_WAIT) begin
                        // the low is in `tmp_low`, the high is in _dout
                        status <= STATUS_IDLE;
                        tmp_low <= 128'b0;
                        acc_hi <= 0;
                        mmu_l1_read_done <= 1;
                        mmu_l1_write_done <= 0;
                        mmu_l1_read_data <= {_dout, tmp_low};
                    end
                end else if (l1_mmu_req_write) begin
                    if (status==STATUS_IDLE && !mmu_l1_write_done) begin
                        // the low write is already done
                        status <= STATUS_WAIT;
                        tmp_low <= 128'b0;
                        acc_hi <= 1;
                        mmu_l1_read_done <= 0;
                        mmu_l1_write_done <= 0;
                        mmu_l1_read_data <= 256'b0;
                    end else if (status == STATUS_WAIT) begin
                        // the low is in `tmp_low`, the high is in _dout
                        status <= STATUS_IDLE;
                        tmp_low <= 128'b0;
                        acc_hi <= 0;
                        mmu_l1_read_done <= 0;
                        mmu_l1_write_done <= 1;
                        mmu_l1_read_data <= 256'b0;
                    end
                end else begin
                    acc_hi <= 0;
                    status <= STATUS_IDLE;
                    tmp_low <= 128'b0;
                    mmu_l1_read_done <= 0;
                    mmu_l1_write_done <= 0;
                    mmu_l1_read_data <= 256'b0;
                end
            end
        end
    end
    
endmodule
