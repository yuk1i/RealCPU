`timescale 1ns / 1ps

module idecoder(
    input sys_clk,
    input rst_n,
    input [31:0] ins_i,
    input is_stalling,

    // From WB
    input reg_write_i,
    input [4:0] reg_write_id_i,
    input [31:0] reg_write_data_i,

    // Decoder output
    output [5:0] opcode,
    output [4:0] shift_amt,
    output [5:0] func,
    output I_op,
    output R_op,
    output J_op,

    output [31:0] ext_immd,
    output [25:0] j_addr,
    output is_jump,        // jump {PC+4[31:28],
    output is_jal,
    output is_jr,
    output is_branch,      // [beq, bneq, beqz, bneqz]
    output is_regimm_op,
    output is_load_store,
    output is_sync_icache,
    output is_sync_dcache,

    output [4:0] rs_id,
    output [4:0] rt_id,
    output [4:0] rd_id,

    // Decoder register values
    output [31:0] reg_read1,
    output [31:0] reg_read2,

    // Controller
    output mem_to_reg,  // load instructions
    output mem_write,   // store instructions
    output alu_src,     // 1:immd, 0: reg2
    output reg_write,   // 1:write reg, 0:not
    output reg_dst,     // 1:rd, 0:rt
    output alu_bypass,  // bypass bypass_immd to result
    output [31:0] bypass_immd
);
    // ***** BEGIN Decoder ***** //
    assign opcode = ins_i[31:26];       // 6 bits
    assign shift_amt = ins_i[10:6];     // 5 bits
    assign func = ins_i[5:0];           // 6 bits
    assign R_op = opcode == 6'b0;
    assign J_op = opcode == 6'h2 || opcode == 6'h3;
    assign I_op = !(R_op || J_op);
    
    assign j_addr = J_op ? ins_i[25:0] : 26'b0;
    assign is_jump = opcode[5:1] == 5'b00001 || (R_op && func[5:1]==5'b00100);

    // [NAL: 10000], [BAL: 10001], [BGEZ: 00001]
    assign is_regimm_op = opcode == 6'b000001;
    assign special_link = is_regimm_op && (_real_rt_id[4:1] == 4'b1000);                      // REGIMM: [NAL, BAL]
    assign special_branch = is_regimm_op && (_real_rt_id == 5'b10001 || _real_rt_id == 5'b00001);   // REGIMM: [BAL, BGEZ]

    // is_jal: jal or jalr or [BAL, NAL]
    assign is_jal = opcode == 6'h3 || (R_op && func==6'b001001) || special_link;        
    assign is_jr = R_op && func[5:1] == 5'b00100;
    assign is_branch = opcode[5:2] == 4'b0001 || special_branch;
    assign is_load_store = mem_to_reg || mem_write;
    assign is_sync_icache = R_op && func == 6'b001111 && ins_i[6] == 0;
    assign is_sync_dcache = R_op && func == 6'b001111 && ins_i[6] == 1;

    assign rs_id = ins_i[25:21];        // 5 bits
    // override rt when jal only
    wire [4:0] _real_rt_id = ins_i[20:16];
    assign rt_id = (opcode == 6'h3 || special_link) ? 5'b11111 : _real_rt_id; // 5 bits
    assign rd_id = ins_i[15:11];        // 5 bits
    
    // ***** END Decoder ***** //
    
    // ***** BEGIN Controller ***** //

    // reg_dst: write rd when R-type, write to rt when I-type and jal/jalr
    // 1:rd, 0:rt
    assign reg_dst = R_op;
    // alu_src: I-type, exclude [beq 04, bne 05, blez 06, bgtz 07]
    assign alu_src = I_op & opcode[5:2] != 4'b0001;
    // use zero extension: [andi c,ori d,xori e,lui f], otherwise signed ext
    wire zero_ext = opcode[5:2]==4'b0011;
    assign ext_immd = zero_ext ? {16'b0, ins_i[15:0]} : {{16{ins_i[15]}}, ins_i[15:0]};
    // mem_to_reg: 1: ALU->Address; 0: ALU->Reg [lb 20, lh 21, lwl 22, lw, 23, lbu 24, lhu 25, lwr 26],[ll to ldc2]
    assign mem_to_reg = opcode[5:3]==3'b100; // ignore [ll to ldc2] 6'b110xxx
    // mem_write: [sb,sh,swl,sw], [swr], [sc swc1 swc2]
    assign mem_write = opcode[5:2]==4'b1010 || opcode==6'b101110 || opcode[5:3]==3'b111;
    // reg_write: R{,[sll,srl,sra,sllv,srlv,srav],[jr,jalr,movz,movn],
    //               [add,addu,sub,subu, and,or,xor,nor]
    //               [slt,  sltu]
    // assign reg_write = (R_op && (func[5:3]==3'b000 
    //                         || (func[5:3]==3'b001 && func!=6'b001000) 
    //                         || func==6'b010000 || func==6'b010010
    //                         || func[5:3]==3'b100
    //                         || func[5:1]==5'b10101)
    //                    )
    //                     || opcode[5:3]==3'b001 || opcode[5:3]==3'b100 || opcode == 6'b000011 || (C0_op && move_from_co);
    reg _reg_write_r;
    reg _reg_write_i;
    always @* begin
        casez(func)
            6'b000zzz : _reg_write_r = 1;   // [sll,srl,sra,sllv,srlv,srav]
            6'b0010zz : _reg_write_r = 1;   // MIPS32r6: jalr
            6'b0110zz : _reg_write_r = 1;   // MIPS32r6: [mul, div] 
            6'b10zzzz : _reg_write_r = 1;   // [add,addu,sub,subu, and,or,xor,nor], [slt, sltu]
            default   : _reg_write_r = 0;
        endcase
        casez(opcode)
            6'b000011 : _reg_write_i = 1;   // jal
            6'b001zzz : _reg_write_i = 1;   // [add,addu,sub,subu, and,or,xor,nor]
            6'b100zzz : _reg_write_i = 1;   // [lb,lh,lw, lbu, lhu]
            default   : _reg_write_i = 0;
        endcase
    end
    assign reg_write = (R_op && _reg_write_r) || _reg_write_i || special_link;
    // ***** END Controller ***** //

    // ***** BEGIN Registers ***** //
    reg [31:0] register [0:31];

    // Decoder Register output
    assign reg_read1 = register[rs_id];
    assign reg_read2 = register[rt_id];

    integer i;
    // Register Write
    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i<32; i=i+1) begin
                register[i] <= 32'h0;
            end 
        end else begin
            register[0] <= 32'b0;
            for (i = 1; i<32; i=i+1) begin
                if (reg_write_i && i==reg_write_id_i && !is_stalling)
                    register[i] <= reg_write_data_i;
                else
                    register[i] <= register[i];
            end
        end
    end
    // ***** END Registers ***** //


    // ***** BEGIN Coprocessor 0 ***** //

    reg [31:0] co0_regs [0:31];
    integer c0i;

    wire C0_op = opcode == 6'b010000;
    wire move_to_co = rs_id == 5'b00100;
    wire move_from_co = rs_id == 5'b00000;
    assign alu_bypass = C0_op && move_from_co;
    assign bypass_immd = co0_regs[rd_id];

    // Co0 Register Write
    always @(posedge sys_clk, negedge rst_n) begin
        if (!rst_n) begin
            for (c0i = 0; c0i<32; c0i=c0i+1) begin
                co0_regs[c0i] <= 32'h0;
            end 
        end else begin
            for (c0i = 0; c0i<32; c0i=c0i+1) begin
                if (C0_op && move_to_co && c0i == rd_id)
                    co0_regs[c0i] <= register[rt_id];
                else
                    co0_regs[c0i] <= co0_regs[c0i];
            end 
        end
    end
    // ***** END Coprocessor 0 ***** //

endmodule
