`timescale 1ns / 1ps

module execute(
    input sys_clk,
    input rst_n,

    input [31:0] reg1,  // rs
    input [31:0] reg2,  // rt
    input [31:0] immd,
    input [31:0] next_pc,
    input alu_src, // 0: reg2, 1: immd
    input allow_exp, // ignored

    // From Decoder
    input [5:0] opcode,
    input [5:0] func,
    input [4:0] ins_shamt,
    input R_op,
    input [25:0] ins_j_addr,
    input is_jump,
    input is_branch,
    input is_jal,
    input is_jr,
    input is_load_store,
    input alu_bypass,
    input [31:0] bypass_immd,

    output reg [31:0] result,
    output reg do_jump,
    output reg [31:0] j_addr,
    output stall            // stall request from multiplier
);
    // [slti, sltiu], R:[slt, sltu]
    wire is_set_op = opcode[5:1] == 5'b00101 || (R_op && (func[5:1] == 5'b10101));
    wire is_shift = opcode == 0 && func[5:3] == 3'b000;
    
    // calc address: [load, store]
    wire calc_addr = is_load_store;

    // [addi,addiu,slti,sltiu,andi,ori,xori,*lui*], R:[add,addu,sub,subu,and,or,xor,nor] [load,store]
    wire is_def = opcode[5:3] == 3'b001 || (R_op && (func[5:3] == 3'b100 || func[5:1] == 5'b10101)) || calc_addr;
    wire is_lui = opcode == 6'b001111;

    // Default ALU, use addiu to calc addr
    wire [2:0] def_exe = calc_addr ? 3'b001 : (opcode == 0 ? func[2:0] : opcode[2:0]);
    wire [31:0] op2 = alu_src ? immd : reg2;
    wire [31:0] inv_op2 = ~op2 + 1;

    reg alu_cf; // carry flag
    reg alu_sf; // sign flag
    reg alu_of; // overflow flag
    reg [31:0] result_mux;
    always @* begin
        casex (def_exe)
            3'b00x: {alu_cf,result_mux} = reg1 + op2;  // 0: of, 1:u no of
            3'b01x: {alu_cf,result_mux} = reg1 + inv_op2;  
            3'b100: {alu_cf,result_mux} = reg1 & op2;
            3'b101: {alu_cf,result_mux} = reg1 | op2;
            3'b110: {alu_cf,result_mux} = reg1 ^ op2;
            3'b111: {alu_cf,result_mux} = is_lui ? {immd[15:0], 16'b0} : ~ (reg1 | op2);
        endcase
        // Set condition registers
        if (def_exe[2] == 0) begin
            if (def_exe[0] == 1) begin
                // unsigned
                alu_sf = 0;
                alu_of = alu_cf;
            end else begin
                // signed, 2's complement
                if (def_exe[1] == 0) begin  // add
                    alu_sf = result_mux[31];
                    alu_of = (reg1[31] & op2[31] & ~result_mux[31]) | (~reg1[31] & ~op2[31] & result_mux[31]);
                end else begin              // minus
                    alu_sf = result_mux[31];
                    alu_of = (reg1[31] & inv_op2[31] & ~result_mux[31]) | (~reg1[31] & ~inv_op2[31] & result_mux[31]);
                end
            end
        end else begin
            alu_sf = 0;
            alu_of = 0;
        end
    end

    // Set Checker:is_set_op, [slti,sltiu], [slt,sltu]. 
    // Calculate reg1-op2 in ALU, judging by condition registers
    wire slt_unsgn = opcode[0]==1 || (R_op && func[0]==1); // only defined when is_set_op
    reg slt_result;
    always @* begin
        if (slt_unsgn) begin
            // unsigned comparision
            slt_result = !alu_cf;
        end else begin
            // signed comparision
            slt_result = alu_of ^ alu_sf;
        end
    end

    // Branch Comparator: is_branch, [beq, bneq, blez, bgez]
    reg do_branch;
    always @* begin 
        case (opcode[1:0])
            2'b00: do_branch = reg1 == reg2;
            2'b01: do_branch = ~(reg1 == reg2);
            2'b10: do_branch = reg1 == 0 || reg1[31] == 1;  // Signed comparison, less or equal to zero
            2'b11: do_branch = reg1[31] == 0;               // Signed comparison
        endcase
    end

    // Shifter: is_shift
    reg [31:0] shift_out;
    // use ins shamt with [sll,srl,sra]
    wire [4:0] real_shamt = func[5:2] == 4'b0000 ? ins_shamt : reg1[4:0];
    always @* begin
        case (func[1:0])
            2'b00: shift_out = reg2 << real_shamt;  // sll
            2'b01: shift_out = 0;                   // undefined
            2'b10: shift_out = $unsigned(reg2) >> real_shamt;  // srl
            2'b11: shift_out = $signed(reg2) >>> real_shamt; // sra
        endcase
    end

    // Multiplier
    wire is_mul = R_op && func[5:1] == 5'b01100;
    wire mul_unsign = func[0];
    wire mul_done = 1;

    // module here
    wire [63:0] mul_out;
    wire mul_low = ins_shamt == 5'b00010;
    wire [31:0] mul_mux = mul_low ? mul_out[31:0] : mul_out[63:32];
    assign stall = is_mul && !mul_done;
    
    multiplier mult(
        .clk(sys_clk),
        .rst_n(rst_n),
        .enable(is_mul),
        .is_unsign(mul_unsign),
        .a(reg1),
        .b(reg2),
        .result(mul_out),
        .done(mul_done)
    );

    // Mux Output
    always @* begin
        if (alu_bypass)
            result = bypass_immd;
        else if (is_set_op)
            result = {31'b0, slt_result};
        else if (is_mul)
            result = mul_mux;
        else if (is_def)
            result = result_mux;
        else if (shift_out)
            result = shift_out;
        else if (is_branch)
            result = 0;
        else if (is_jal)
            result = next_pc + 4;
        else
            result = 0;
    end

    // Jump & Branch
    // I:[j,jal], R:[jr, jalr]
    // {4'b next_pc | 26'b ins_j_addr | 2'b00 }
    wire [31:0] _jump_addr_ext = {next_pc[31:28], ins_j_addr[25:0] , 2'b0};
    wire [31:0] _branch_addr_ext = next_pc + {immd[29:0] , 2'b0};
    always @* begin
        if (is_jump) begin
            do_jump = 1;
            if (is_jr)
                j_addr = reg1;
            else
                j_addr = _jump_addr_ext;
        end else if (is_branch && do_branch) begin
            do_jump = 1;
            j_addr = _branch_addr_ext;
        end else begin
            do_jump = 0;
            j_addr = 0;
        end
    end

endmodule