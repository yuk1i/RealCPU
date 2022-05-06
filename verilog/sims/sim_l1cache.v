`timescale 1ns / 1ps


module sim_l1cache();
    reg sys_clk;
    reg rst_n;
    
    always #5 sys_clk = ~sys_clk;

    reg l1_read;
    reg [31:0] l1_addr;
    reg l1_write;
    reg [1:0] l1_write_type;
    reg [31:0] l1_write_data;

    wire [31:0] l1_data_o;
    wire stall;

    wire l1_mmu_req;
    wire l1_mmu_req_read;
    wire l1_mmu_req_write;
    wire [31:0] l1_mmu_req_addr;
    wire [31:0] l1_mmu_write_data;

    reg mmu_l1_read_done;
    reg mmu_l1_write_done;
    reg mmu_l1_volatile;
    reg [31:0] mmu_l1_read_data;
    
    initial begin 
        sys_clk = 0;
        rst_n = 0;
        l1_read = 0;
        l1_addr = 32'b0;
        l1_write = 0;
        l1_write_type = 2'b0;
        l1_write_data = 32'b0;

        mmu_l1_read_done = 0;
        mmu_l1_write_done = 0;
        mmu_l1_volatile = 0;
        mmu_l1_read_data = 32'b0;

        #8 rst_n = 1;
    end
    
    always @(posedge sys_clk) begin
        if (l1_mmu_req) begin
            if (l1_mmu_req_read) begin
                mmu_l1_read_done <= 1;
                mmu_l1_read_data <= l1_mmu_req_addr + 32'h00000001;
            end else begin
                mmu_l1_write_done <= 1;
            end
        end else begin
            mmu_l1_read_done <= 0;
            mmu_l1_write_done <= 0;
            mmu_l1_read_data <= 32'b0;
        end
    end

    initial begin
        #15 
        l1_read = 1;
        l1_addr = 32'b1111_00000_00011_11;

        #40 
        l1_read = 0;

        #40 
        l1_read = 1;
        l1_addr = 32'b1100_00000_00011_11;

        #40 
        l1_read = 0;
        l1_write = 1;
        l1_addr = 32'b1100_00000_00011_11;
        l1_write_data = 32'hAAAABBBB;

        #40 
        l1_read = 1;
        l1_write = 0;
        l1_addr = 32'b1111_00000_00011_11;
        l1_write_data = 0;

        #40
        l1_read = 1;
        l1_write = 0;
        l1_addr = 32'b1100_00000_00011_10;

        #40
        l1_read = 0;
        l1_write = 1;
        l1_write_type = 2'b01;
        l1_addr = 32'b1100_00000_00011_00;
        l1_write_data = 32'H0000ABCD;

        #40
        l1_addr = 32'b1100_00000_00011_10;
        l1_write_data = 32'H0000FFFF;

        #40
        l1_write_type = 2'b10;
        l1_addr = 32'b1100_00000_00011_00;
        l1_write_data = 32'H00000012;
        
        #40
        l1_addr = 32'b1100_00000_00011_01;
        l1_write_data = 32'H00000034;

        #40
        l1_addr = 32'b1100_00000_00011_10;
        l1_write_data = 32'H00000056;

        #40
        l1_addr = 32'b1100_00000_00011_11;
        l1_write_data = 32'H00000078;


        #40
        l1_read = 0; 
        l1_write = 0;
        mmu_l1_volatile = 1;

        #15 
        l1_read = 1;
        l1_addr = 32'b1111_00000_00011_11;

        #40 
        l1_read = 0;

        #40 
        l1_read = 1;
        l1_addr = 32'b1100_00000_00011_11;

        #40 
        l1_read = 0;
        l1_write = 1;
        l1_addr = 32'b1100_00000_00011_11;
        l1_write_data = 32'hAAAABBBB;

        #40 
        l1_read = 1;
        l1_write = 0;
        l1_addr = 32'b1111_00000_00011_11;
        l1_write_data = 0;

        #40
        l1_read = 1;
        l1_write = 0;
        l1_addr = 32'b1100_00000_00011_10;

        #40
        l1_read = 0;
        l1_write = 1;
        l1_write_type = 2'b01;
        l1_addr = 32'b1100_00000_00011_00;
        l1_write_data = 32'H0000ABCD;

        #40
        l1_addr = 32'b1100_00000_00011_10;
        l1_write_data = 32'H0000FFFF;

        #40
        l1_write_type = 2'b10;
        l1_addr = 32'b1100_00000_00011_00;
        l1_write_data = 32'H00000012;
        
        #40
        l1_addr = 32'b1100_00000_00011_01;
        l1_write_data = 32'H00000034;

        #40
        l1_addr = 32'b1100_00000_00011_10;
        l1_write_data = 32'H00000056;

        #40
        l1_addr = 32'b1100_00000_00011_11;
        l1_write_data = 32'H00000078;


    end

    l1cache l1cache_s(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .l1_read(l1_read),
        .l1_addr(l1_addr),
        .l1_write(l1_write),
        .l1_write_type(l1_write_type),
        .l1_write_data(l1_write_data),
        
        .l1_data_o(l1_data_o),
        .stall(stall),
        
        .l1_mmu_req(l1_mmu_req),
        .l1_mmu_req_read(l1_mmu_req_read),
        .l1_mmu_req_write(l1_mmu_req_write),
        .l1_mmu_req_addr(l1_mmu_req_addr),
        .l1_mmu_write_data(l1_mmu_write_data),

        .mmu_l1_read_done(mmu_l1_read_done),
        .mmu_l1_write_done(mmu_l1_write_done),
        .mmu_l1_volatile(mmu_l1_volatile),
        .mmu_l1_read_data(mmu_l1_read_data)
    );

endmodule
