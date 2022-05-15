`timescale 1ns / 1ps
module l1mmu(
    input sys_clk,
    input rst_n,
    
    input l1_mmu_req_read,
    input l1_mmu_req_write,
    input [31:0] l1_mmu_req_addr,
    input [255:0] l1_mmu_write_data,

    output mmu_l1_done,
    output [255:0] mmu_l1_read_data,

    output mmu_mmio_read,
    output mmu_mmio_write,
    output [31:0] mmu_mmio_addr,
    output [31:0] mmu_mmio_write_data,
    input  mmu_mmio_done,
    input  [31:0] mmu_mmio_read_data
);
    wire addr_is_mmio;
    // Whether this address is MMIO address
    mmio_addr mmio_addr_l1addr(
        .addr(l1_mmu_req_addr),
        .is_mmio(addr_is_mmio)
    );

    assign mmu_mmio_read = addr_is_mmio && l1_mmu_req_read;
    assign mmu_mmio_write = addr_is_mmio && l1_mmu_req_write;
    assign mmu_mmio_addr = {l1_mmu_req_addr[31:2], 2'b00};
    assign mmu_mmio_write_data = l1_mmu_write_data[31:0];
    
    reg [1:0] status;
    localparam  STATUS_IDLE     = 2'b00,
                STATUS_ACC_HI   = 2'b01,
                STATUS_DONE     = 2'b10;

    wire acc_hi = status == STATUS_ACC_HI || status == STATUS_DONE;
    reg [127:0] stage;
    wire [31:0] _req_addr = !addr_is_mmio ? {4'b0, l1_mmu_req_addr[31:5], acc_hi} : 32'b0;
    wire [127:0] _dout;
    wire [127:0] _wr_data = acc_hi ? l1_mmu_write_data[255:128] : l1_mmu_write_data[127:0];
    wire mig_write = !addr_is_mmio && l1_mmu_req_write;

    assign mmu_l1_done = addr_is_mmio ? mmu_mmio_done : status == STATUS_DONE;
    assign mmu_l1_read_data = addr_is_mmio ? {244'b0, mmu_mmio_read_data} : {_dout, stage};

    mem_fake_mig fake_mig(
        .clka(~sys_clk),
        .addra(_req_addr),
        .douta(_dout),
        .dina(_wr_data),
        .wea(mig_write)
    );

    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            stage <= 128'b0;
        end else begin
            if (addr_is_mmio) begin
                stage <= 128'b0;
            end else begin
                // read mem
                if (status == STATUS_IDLE && l1_mmu_req_read) begin
                    stage <= _dout;
                end else begin
                    stage <= stage;
                end
            end
        end
    end

    // STATE MACHINE
    always @(posedge sys_clk, negedge rst_n) begin
        if (~rst_n) begin
            status <= STATUS_IDLE;
        end else begin
            if (addr_is_mmio && (l1_mmu_req_read || l1_mmu_req_write)) begin
                // MMIO Requests
                status <= STATUS_IDLE;
            end else begin
                if (l1_mmu_req_read || l1_mmu_req_write) begin
                    if (status == STATUS_IDLE) begin
                        // and first stage r/w doen
                        status <= STATUS_ACC_HI;
                    end else if (status == STATUS_ACC_HI) begin
                        // and second stage r/w done
                        status <= STATUS_DONE;
                    end else if (status == STATUS_DONE) begin
                        status <= STATUS_IDLE;
                    end else begin
                        status <= status;
                    end
                end else begin
                    status <= STATUS_IDLE;
                end
            end
        end
    end
    
endmodule
