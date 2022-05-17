`timescale 1ns / 1ps

module top(
    input bank_sys_clk,
    input bank_rst,
    
    // input sw_clk,
    // input sw_pc_ins,

    // wire [7:0] seg7_led,
    // wire [7:0] seg7_select
    
    // IO Devices
    input [23:0] switches_pin,
    output [23:0] leds_pin,
    output [7:0] seg7_bits_pin, 
    output [7:0] seg7_led_pin,
    input uart_rx_pin,
    output uart_tx_pin
);

    wire rst_n = !bank_rst && sys_clk_lock;

    wire sys_clk;
    wire sys_clk_lock;

    clk_wiz clk_gen(
        .clk_in1(bank_sys_clk),
        .resetn(!bank_rst),
        .cpu_clk(sys_clk),
        .locked(sys_clk_lock)
    );


    wire [31:0] f_ins;
    wire [31:0] f_pc;
    wire [31:0] f_next_pc;

    wire [5:0] d_opcode;
    wire [4:0] d_shift_amt;
    wire [5:0] d_func;
    wire d_R_op;

    wire [31:0] d_ext_immd;
    wire [25:0] d_j_addr;
    wire d_is_jump;       
    wire d_is_jal;
    wire d_is_jr;
    wire d_is_branch;
    wire d_is_regimm_op;
    wire d_is_load_store;
    wire d_is_sync_icache;
    wire d_is_sync_dcache;

    wire [4:0] d_rs_id;
    wire [4:0] d_rt_id;
    wire [4:0] d_rd_id;

    wire [31:0] d_reg_read1;
    wire [31:0] d_reg_read2;

    wire d_mem_to_reg;
    wire d_mem_write;
    wire d_alu_src;
    wire d_reg_write;
    wire d_reg_dst;
    wire d_alu_bypass;
    wire [31:0] d_bypass_immd;

    wire [31:0] e_result;
    wire e_do_jump;
    wire [31:0] e_j_addr;
    wire e_stall;

    wire [31:0] m_mem_data;
    wire m_stall;

    /*** Write Back ***/ 
    wire [5:0] wb_opcode = d_opcode;
    wire wb_reg_write = d_reg_write;
    wire [4:0] wb_reg_write_id = d_reg_dst ? d_rd_id : d_rt_id;
    reg [31:0] wb_ext_data;
    wire [31:0] wb_data = d_mem_to_reg ? wb_ext_data : e_result;
    
    wire [7:0] wb_byte_extra = m_mem_data[e_result[1:0] * 8+:8];
    wire [16:0] wb_hw_extra = m_mem_data[e_result[1] * 16+:16];
    always @* begin
        case(wb_opcode[2:0])
            3'b000: wb_ext_data = {{24{wb_byte_extra[7]}}, wb_byte_extra[7:0]};       // lb
            3'b001: wb_ext_data = {{16{wb_hw_extra[15]}}, wb_hw_extra[15:0]};     // lh
            3'b011: wb_ext_data = m_mem_data;                                   // lw
            3'b100: wb_ext_data = {24'b0, wb_byte_extra[7:0]};                     // lbu
            3'b101: wb_ext_data = {16'b0, wb_hw_extra[15:0]};                    // lhu
            default:wb_ext_data = m_mem_data;
        endcase
    end

    wire fecth_stall = e_stall || m_stall;
    wire global_stall;

    // L1 iCache 
    wire immu_read;
    wire [31:0] immu_addr;
    wire immu_read_done;
    wire [255:0] immu_read_data;

    ifetch fetch(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .do_jump(e_do_jump),
        .jump_addr(e_j_addr),

        .stall(fecth_stall),
        .global_stall(global_stall),

        .ins_out(f_ins),
        .pc_out(f_pc),
        .next_pc_out(f_next_pc),

        .immu_read(immu_read),
        .immu_addr(immu_addr),
        .immu_done(immu_done),
        .immu_read_data(immu_read_data),

        .sync(d_is_sync_icache)
    );

    idecoder decoder(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .ins_i(f_ins),
        .is_stalling(global_stall),

        .reg_write_i(wb_reg_write),
        .reg_write_id_i(wb_reg_write_id),
        .reg_write_data_i(wb_data),
        
        .opcode(d_opcode),
        .shift_amt(d_shift_amt),
        .func(d_func),
        .R_op(d_R_op),
        .ext_immd(d_ext_immd),
        .j_addr(d_j_addr),
        .is_jump(d_is_jump),
        .is_jal(d_is_jal),
        .is_jr(d_is_jr),
        .is_branch(d_is_branch),
        .is_regimm_op(d_is_regimm_op),
        .is_load_store(d_is_load_store),
        .is_sync_icache(d_is_sync_icache),
        .is_sync_dcache(d_is_sync_dcache),

        .rs_id(d_rs_id),
        .rt_id(d_rt_id),
        .rd_id(d_rd_id),

        .reg_read1(d_reg_read1),
        .reg_read2(d_reg_read2),

        .mem_to_reg(d_mem_to_reg),
        .mem_write(d_mem_write),
        .alu_src(d_alu_src),
        .reg_write(d_reg_write),
        .reg_dst(d_reg_dst),
        .alu_bypass(d_alu_bypass),
        .bypass_immd(d_bypass_immd)

    );

    execute ex(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .reg1(d_reg_read1),
        .reg2(d_reg_read2),
        .immd(d_ext_immd),
        .next_pc(f_next_pc),
        .alu_src(d_alu_src),
        .alu_bypass(d_alu_bypass),
        .bypass_immd(d_bypass_immd),
        .allow_exp(1'b0),      // TODO: Exception support

        .opcode(d_opcode),
        .func(d_func),
        .ins_shamt(d_shift_amt),
        .R_op(d_R_op),
        .ins_j_addr(d_j_addr),
        .is_jump(d_is_jump),
        .is_branch(d_is_branch),
        .is_regimm_op(d_is_regimm_op),
        .rt_id(d_rt_id),
        .is_jal(d_is_jal),
        .is_jr(d_is_jr),
        .is_load_store(d_is_load_store),
        
        .result(e_result),
        .do_jump(e_do_jump),
        .j_addr(e_j_addr),
        .stall(e_stall)
    );

    // D Cache
    wire dmem_read = d_mem_to_reg;
    wire dmem_write = d_mem_write;
    wire [31:0] dmem_addr = e_result;
    wire [1:0] dmem_write_type = d_opcode[1:0];
    wire [31:0] dmem_write_data = d_reg_read2;

    wire dmmu_read;
    wire dmmu_write;
    wire [31:0] dmmu_addr;
    wire [255:0] dmmu_write_data;
    wire dmmu_done;
    wire [255:0] dmmu_read_data;

    l1dcache dcache(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .l1_read(dmem_read),
        .l1_write(dmem_write),
        .l1_addr(dmem_addr),
        .l1_write_type(dmem_write_type),
        .l1_write_data(dmem_write_data),

        .l1_data_o(m_mem_data),
        .stall(m_stall),

        .l1_mmu_req_read(dmmu_read),
        .l1_mmu_req_write(dmmu_write),
        .l1_mmu_req_addr(dmmu_addr),
        .l1_mmu_write_data(dmmu_write_data),
        
        .mmu_l1_done(dmmu_done),
        .mmu_l1_read_data(dmmu_read_data),

        .sync(d_is_sync_dcache)
    );
    wire serve_ic           = immu_read;
    wire mmu_read           = serve_ic ? immu_read : dmmu_read;
    wire mmu_write          = serve_ic ? 0         : dmmu_write;
    wire [31:0] mmu_addr    = serve_ic ? immu_addr : dmmu_addr;
    wire [255:0] mmu_write_data = dmmu_write_data;

    wire mmu_done;
    wire [255:0] mmu_read_data;
    
    // MMU to L1D and L1I
    assign immu_done        =  serve_ic && mmu_done;
    assign dmmu_done        = !serve_ic && mmu_done;

    assign immu_read_data   = mmu_read_data;
    assign dmmu_read_data   = mmu_read_data;

    wire mmio_read;
    wire mmio_write;
    wire [31:0] mmio_addr;
    wire [31:0] mmio_write_data;
    wire mmio_done;
    wire [31:0] mmio_read_data;

    l1mmu l1mmu1(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .l1_mmu_req_read(mmu_read),
        .l1_mmu_req_write(mmu_write),
        .l1_mmu_req_addr(mmu_addr),
        .l1_mmu_write_data(mmu_write_data),
        
        .mmu_l1_done(mmu_done),
        .mmu_l1_read_data(mmu_read_data),

        .mmu_mmio_write(mmio_write),
        .mmu_mmio_read(mmio_read),
        .mmu_mmio_addr(mmio_addr),
        .mmu_mmio_write_data(mmio_write_data),

        .mmu_mmio_done(mmio_done),
        .mmu_mmio_read_data(mmio_read_data)
    );

    mmio_devs mmiodevs(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .mmio_read(mmio_read),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),

        .mmio_done(mmio_done),
        .mmio_read_data(mmio_read_data),

        .switches_pin(switches_pin),
        .leds_pin(leds_pin),
        .seg7_bits_pin(seg7_bits_pin),
        .seg7_led_pin(seg7_led_pin),
        .bank_sys_clk(bank_sys_clk)
        
        ,
        .uart_rx_pin(uart_rx_pin),
        .uart_tx_pin(uart_tx_pin)
    );

    // assign uart_tx_pin = uart_rx_pin;

    // wire [31:0] dis;
    // assign dis = sw_pc_ins ? pc : ins;
	// seg7 seg_left(
	// 		.clk(sys_clk),
	// 		.rst_n(rst_n),
	// 		.numbers(dis),
	// 		.LED_BITS(seg7_select),
	// 		.LED(seg7_led)
	// );
endmodule
