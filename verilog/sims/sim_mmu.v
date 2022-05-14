`timescale 1ns / 1ps


module sim_mmu();
    reg sys_clk;
    reg rst_n;
    
    always #1 sys_clk = ~sys_clk;

    reg l1_read;
    reg l1_write;
    reg [31:0] l1_addr;
    reg [1:0] l1_write_type;
    reg [31:0] l1_write_data;

    wire [31:0] l1_data_o;
    wire stall;

    wire l1_mmu_req_read;
    wire l1_mmu_req_write;
    wire [31:0] l1_mmu_req_addr;
    wire [255:0] l1_mmu_write_data;

    wire mmu_l1_read_done;
    wire mmu_l1_write_done;
    wire [255:0] mmu_l1_read_data;
    
    reg ram_i_write;

    initial begin 
        sys_clk = 0;
        rst_n = 0;
        l1_read = 0;
        l1_write = 0;
        l1_addr = 32'b0;
        l1_write_type = 2'b0;
        l1_write_data = 32'b0;

        #8 rst_n = 1;
    end

    initial begin
        #20
        l1_read = 1;
        l1_addr = 32'b111_00000_00000_01100;

        #16
        l1_read = 0;

        #16
        l1_read = 1;
        l1_addr = 32'b001_00000_00000_01100;
        // expected mmu req

        #16
        l1_read = 0;
        l1_write = 1;
        l1_addr = 32'b001_00000_00000_01100;
        l1_write_data = 32'hAAAABBBB;
        // write to cached

        #16
        l1_read =0;
        l1_write=1;
        l1_addr = 32'b010_00000_00000_00000;
        l1_write_data = 32'HEEEEFFFF;

        #32
        l1_read = 1;
        l1_write = 0;
        l1_addr = 32'b001_00000_00000_01100;
        l1_write_data = 0;
        // read cached

        #32
        l1_read = 0;
        l1_write = 1;
        l1_addr = 32'b011_00000_00000_01100;
        l1_write_data = 32'hBBB00CCC;
        // write uncached, dirty 

        #32
        l1_read = 1;
        l1_write = 0;
        l1_addr = 32'b001_00000_00000_01100;
        // flush out cache

        // Test SW
        #32
        l1_read = 0;
        l1_write = 1;
        l1_write_type = 2'b00;
        l1_addr = 32'b010_00000_00000_00000;
        l1_write_data = 32'H11112222;

        #32
        l1_addr = 32'b010_00000_00000_00100;
        l1_write_data = 32'H33334444;

        #4
        l1_addr = 32'b010_00000_00000_01000;
        l1_write_data = 32'H55556666;

        #4
        l1_addr = 32'b010_00000_00000_01100;
        l1_write_data = 32'H77778888;        
        
        #4
        l1_addr = 32'b010_00000_00000_10000;
        l1_write_data = 32'H9999AAAA;

        #4
        l1_addr = 32'b010_00000_00000_10100;
        l1_write_data = 32'HBBBBCCCC;

        #4
        l1_addr = 32'b010_00000_00000_11000;
        l1_write_data = 32'HDDDDEEEE;

        #4
        l1_addr = 32'b010_00000_00000_11100;
        l1_write_data = 32'HFFFF0000;

        // test sh
        #4
        l1_write_type = 2'b01;
        l1_addr = 32'b010_00000_00000_00000;
        l1_write_data = 32'H00001234;
        #4
        l1_addr = 32'b010_00000_00000_00010;
        l1_write_data = 32'H00001234;
        #4
        l1_addr = 32'b010_00000_00000_00100;
        l1_write_data = 32'H00001234;

        // test sb
        #4
        l1_write_type = 2'b10;
        l1_addr = 32'b010_00000_00000_01000;
        l1_write_data = 32'H000012FF;
        #4
        l1_addr = 32'b010_00000_00000_01001;
        #4
        l1_addr = 32'b010_00000_00000_01010;
        #4
        l1_addr = 32'b010_00000_00000_01011;

        #16
        l1_read = 1;
        l1_write = 0;
        l1_write_type = 2'b00;
        l1_addr = 32'b010_00000_00000_01100;

    end

    l1cache l1cache_s(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .l1_read(l1_read),
        .l1_write(l1_write),
        .l1_addr(l1_addr),
        .l1_write_type(l1_write_type),
        .l1_write_data(l1_write_data),
        
        .l1_data_o(l1_data_o),
        .stall(stall),
        
        .l1_mmu_req_read(l1_mmu_req_read),
        .l1_mmu_req_write(l1_mmu_req_write),
        .l1_mmu_req_addr(l1_mmu_req_addr),
        .l1_mmu_write_data(l1_mmu_write_data),

        .mmu_l1_read_done(mmu_l1_read_done),
        .mmu_l1_write_done(mmu_l1_write_done),
        .mmu_l1_read_data(mmu_l1_read_data)
    );

    l1mmu mmu(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .l1_mmu_req_read(l1_mmu_req_read),
        .l1_mmu_req_write(l1_mmu_req_write),
        .l1_mmu_req_addr(l1_mmu_req_addr),
        .l1_mmu_write_data(l1_mmu_write_data),

        .mmu_l1_read_done(mmu_l1_read_done),
        .mmu_l1_write_done(mmu_l1_write_done),
        .mmu_l1_read_data(mmu_l1_read_data),
        
        .mmu_mmio_done(1),
        .mmu_mmio_write_data(32'hABCDEF00)
    );

endmodule
