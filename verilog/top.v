`timescale 1ns / 1ps

module top(
    input bank_sys_clk,
    input bank_rst,

    // IO Devices
    input [23:0] switches_pin,
    output [23:0] leds_pin,
    output [7:0] seg7_bits_pin, 
    output [7:0] seg7_led_pin,
    input uart_rx_pin,
    output uart_tx_pin
);

//#region SYS_CLK & RST Generator
    reg resetter;   // low to reset system
    wire rst_n_w = !bank_rst && sys_clk_lock && resetter;
    reg rst_n;
    wire sys_clk;
    wire sys_clk_lock;

    clk_wiz clk_gen(
        .clk_in1(bank_sys_clk),
        .cpu_clk(sys_clk),
        .locked(sys_clk_lock)
    );

    reg [4:0] cnt;
    always @(posedge sys_clk) begin
        if (bank_rst || !sys_clk_lock) begin
            cnt <= 0;
            resetter <= 0;
        end else begin
            if (cnt == 5'b11110) begin
                resetter <= 1;
                cnt <= cnt;
            end else begin
                resetter <= 0;
                cnt <= cnt + 1;
            end
        end
    end
    always @(posedge sys_clk) rst_n <= rst_n_w;
//#endregion


    wire e_stall;
    wire m_stall;

    wire fecth_stall = e_stall || m_stall;
    wire global_stall;

//region fetch & decoder
    wire [31:0] f_ins;
    wire [31:0] f_pc;
    wire [31:0] f_next_pc;

    wire [31:0] d_ext_immd; 
    wire d_is_link;
    wire d_is_jump;      
    wire d_is_branch;
    wire d_is_sync;

    wire [31:0] d_reg_read1;
    wire [31:0] d_reg_read2;

    wire d_mem_to_reg;
    wire d_mem_write;
    wire d_alu_src;
    wire d_reg_write;
    wire [4:0] d_reg_dst_id;

    // L1I to MMU 
    wire immu_read;
    wire [31:0] immu_addr;
    wire immu_done;
    wire [255:0] immu_read_data;

    ifetch fetch(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .fetch_bubble(insert_bubble),

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

        .is_sync_ins(d_is_sync)
    );
    // WB to Decoder
    wire          wb_reg_write;
    wire [4:0]    wb_reg_dst_id;
    wire [31:0]   wb_reg_wdata;
    // Bubble Controller, ID/EX to Decoder
    wire          id_ex_mem_read;
    wire [4:0]    id_ex_reg_dst_id;
    wire          insert_bubble;
    idecoder decoder(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .ins_i(f_ins),
        .is_stalling(global_stall),

        .reg_write_i(wb_reg_write),
        .reg_write_id_i(wb_reg_dst_id),
        .reg_write_data_i(wb_reg_wdata),
        
        .ext_immd(d_ext_immd),
        .is_link(d_is_link),
        .is_jump(d_is_jump),
        .is_branch(d_is_branch),
        .is_sync_ins(d_is_sync),

        .reg_read1(d_reg_read1),
        .reg_read2(d_reg_read2),

        .mem_to_reg(d_mem_to_reg),
        .mem_write(d_mem_write),
        .alu_src(d_alu_src),
        .reg_write(d_reg_write),
        .reg_dst_id(d_reg_dst_id),

        .insert_bubble(insert_bubble),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_reg_dst_id(id_ex_reg_dst_id)
    );
//#endregion

    // ID/EX to EX
    wire [31:0]   ex_ins;
    wire [31:0]   ex_reg1;
    wire [31:0]   ex_reg2;
    wire [31:0]   ex_immd;
    wire [31:0]   ex_next_pc;
    wire          ex_alu_src;
    wire          ex_is_link;
    wire          ex_is_jump;
    wire          ex_is_branch;
    wire          ex_is_load_store;
    // ID/EX to EX/MEM & MEM/WB
    wire          eo_mem_to_reg;
    wire          eo_mem_write;
    wire          eo_reg_write;
    wire [4:0]    eo_reg_dst_id;
    wire          eo_is_sync;
    // EX Output
    wire [31:0]   e_result;
    wire          e_do_jump;
    wire [31:0]   e_j_addr;
    // Forwardings
    wire          fwd_ex_reg_write;
    wire [4:0]    fwd_ex_reg_dst_id;
    wire [31:0]   fwd_ex_result;
    wire          fwd_mem_reg_write;
    wire [4:0]    fwd_mem_reg_dst_id;
    wire [31:0]   fwd_mem_result;
    // Bubble Controller, ID/EX to Decoder
    assign        id_ex_mem_read    = eo_mem_to_reg;
    assign        id_ex_reg_dst_id  = eo_reg_dst_id;
    id_ex id_exi(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .id_ex_stall(global_stall),
        .id_ex_bubble(insert_bubble),

        .di_pc(f_pc),
        .di_next_pc(f_next_pc),
        .di_ins(f_ins),
        .di_ext_immd(d_ext_immd),
        .di_is_link(d_is_link),
        .di_is_jump(d_is_jump),
        .di_is_branch(d_is_branch),
        .di_is_sync(d_is_sync),
        .di_reg_read1(d_reg_read1),
        .di_reg_read2(d_reg_read2),

        .di_mem_to_reg(d_mem_to_reg),
        .di_mem_write(d_mem_write),
        .di_alu_src(d_alu_src),
        .di_reg_write(d_reg_write),
        .di_reg_dst_id(d_reg_dst_id),

        .eo_ins(ex_ins),
        .eo_reg1(ex_reg1),
        .eo_reg2(ex_reg2),
        .eo_immd(ex_immd),
        .eo_next_pc(ex_next_pc),
        .eo_alu_src(ex_alu_src),
        .eo_is_link(ex_is_link),
        .eo_is_jump(ex_is_jump),
        .eo_is_branch(ex_is_branch),
        .eo_is_load_store(ex_is_load_store),

        .eo_mem_to_reg(eo_mem_to_reg),
        .eo_mem_write(eo_mem_write),
        .eo_reg_write(eo_reg_write),
        .eo_reg_dst_id(eo_reg_dst_id),
        .eo_is_sync(eo_is_sync),

        .fwd_ex_reg_write(fwd_ex_reg_write),
        .fwd_ex_reg_dst_id(fwd_ex_reg_dst_id),
        .fwd_ex_result(fwd_ex_result),
        .fwd_mem_reg_write(fwd_mem_reg_write),
        .fwd_mem_reg_dst_id(fwd_mem_reg_dst_id),
        .fwd_mem_result(fwd_mem_result)        
    );

    execute ex(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        
        .ins(ex_ins),
        .reg1(ex_reg1),
        .reg2(ex_reg2),
        .immd(ex_immd),
        .next_pc(ex_next_pc),
        .alu_src(ex_alu_src),
        
        .is_link(ex_is_link),
        .is_jump(ex_is_jump),
        .is_branch(ex_is_branch),
        .is_load_store(ex_is_load_store),
        
        .result(e_result),
        .do_jump(e_do_jump),
        .j_addr(e_j_addr),
        .stall(e_stall)
    );

    // EX/MEM to MEM
    wire          mo_mem_read      ;
    wire          mo_mem_write     ;
    wire [31:0]   mo_ex_result     ;
    wire [31:0]   mo_mem_write_data;
    wire [1:0]    mo_mem_write_type;
    wire          mo_is_sync_ins   ;
    wire [4:0]    mo_sync_type     ;
    // EX/MEM to MEM/WB
    wire [5:0]    mo_opcode       ;
    wire          mo_reg_write    ;
    wire [4:0]    mo_reg_dst_id   ;

    ex_mem em_memi(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .ex_mem_stall(global_stall),

        .ei_result(e_result),

        .ei_ins(ex_ins),
        .ei_is_sync(eo_is_sync),
        .ei_reg_read2(ex_reg2),
        .ei_mem_to_reg(eo_mem_to_reg),
        .ei_mem_write(eo_mem_write),
        .ei_reg_write(eo_reg_write),
        .ei_reg_dst_id(eo_reg_dst_id),

        .mo_mem_read(mo_mem_read),
        .mo_mem_write(mo_mem_write),
        .mo_ex_result(mo_ex_result),
        .mo_mem_write_data(mo_mem_write_data),
        .mo_mem_write_type(mo_mem_write_type),
        .mo_is_sync_ins(mo_is_sync_ins),
        .mo_sync_type(mo_sync_type),
        
        .mo_opcode(mo_opcode),
        .mo_reg_write(mo_reg_write),
        .mo_reg_dst_id(mo_reg_dst_id),

        .fwd_ex_reg_write(fwd_ex_reg_write),
        .fwd_ex_reg_dst_id(fwd_ex_reg_dst_id),
        .fwd_ex_result(fwd_ex_result),
        .fwd_mem_reg_write(fwd_mem_reg_write),
        .fwd_mem_reg_dst_id(fwd_mem_reg_dst_id),
        .fwd_mem_result(fwd_mem_result)    
    );

    // MEM Output
    wire [31:0] mem_data_out;

    mem_wb mem_wbi(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .mem_wb_stall(global_stall),

        .mi_opcode(mo_opcode),
        .mi_mem_to_reg(mo_mem_read),
        .mi_ex_result(mo_ex_result),
        .mi_reg_write(mo_reg_write),
        .mi_reg_dst_id(mo_reg_dst_id),

        .mi_mem_read_data(mem_data_out),

        .wbo_reg_write(wb_reg_write),
        .wbo_reg_dst_id(wb_reg_dst_id),
        .wbo_reg_wdata(wb_reg_wdata),

        .fwd_mem_reg_write(fwd_mem_reg_write),
        .fwd_mem_reg_dst_id(fwd_mem_reg_dst_id),
        .fwd_mem_result(fwd_mem_result)    
    );

    // D Cache to MMU
    wire dmmu_read;
    wire dmmu_write;
    wire [31:0] dmmu_addr;
    wire [255:0] dmmu_write_data;
    wire dmmu_done;
    wire [255:0] dmmu_read_data;

    l1dcache dcache(
        .sys_clk(sys_clk),
        .rst_n(rst_n),

        .l1_read(mo_mem_read),
        .l1_write(mo_mem_write),
        .l1_addr(mo_ex_result),
        .l1_write_data(mo_mem_write_data),
        .l1_write_type(mo_mem_write_type),
        .is_sync_ins(mo_is_sync_ins),
        .sync_type(mo_sync_type),

        .l1_data_o(mem_data_out),
        .stall(m_stall),

        .l1_mmu_req_read(dmmu_read),
        .l1_mmu_req_write(dmmu_write),
        .l1_mmu_req_addr(dmmu_addr),
        .l1_mmu_write_data(dmmu_write_data),
        
        .mmu_l1_done(dmmu_done),
        .mmu_l1_read_data(dmmu_read_data)

    );

    // MMU Control Signals
    reg  dmmu_pending;
    always @(posedge sys_clk) begin
        if (rst_n) dmmu_pending <= 0;
        else begin
            if (!dmmu_pending && (dmmu_read || dmmu_write) && !immu_read) begin
                dmmu_pending <= 1;
            end else if (dmmu_pending) begin
                dmmu_pending <= mmu_done;
            end else begin
                dmmu_pending <= 0;
            end
        end
    end
    // Don't transfer control to L1I when L1D is pending, works at immu_read is one clk delayed to dmmu requests
    wire serve_ic           = immu_read && !dmmu_pending;
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
    // MMIO Control Signals
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
        .bank_sys_clk(bank_sys_clk),
        .uart_rx_pin(uart_rx_pin),
        .uart_tx_pin(uart_tx_pin)
    );
    

endmodule
