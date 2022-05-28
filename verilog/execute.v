`timescale 1ns / 1ps

module execute(
    input sys_clk,
    input rst_n,

    input [31:0] ins,   // instruction
    input [31:0] reg1,  // rs
    input [31:0] reg2,  // rt
    input [31:0] immd,
    input [31:0] next_pc,
    input alu_src, // 0: reg2, 1: immd

    // From Decoder
    input is_link,
    input is_jump,
    input is_branch,
    input is_load_store,

    output reg [31:0] result,
    output reg do_jump,
    output reg [31:0] j_addr,
    output stall            // stall request from multiplier
);

    wire [5:0]  opcode   = ins[31:26];       // 6 bits
    wire [4:0]  rt_id    = ins[20:16];
    wire R_op            = opcode == 6'b0;
    wire [4:0] ins_shamt = ins[10:6];     // 5 bits
    wire [5:0] func      = ins[5:0];           // 6 bits
    wire is_regimm_op    = opcode == 6'b000001;
    wire is_special3     = opcode == 6'b011111;

    // [slti, sltiu], R:[slt, sltu]
    wire is_set_op       = opcode[5:1] == 5'b00101 || (R_op && (func[5:1] == 5'b10101));
    wire is_shift        = opcode == 0 && func[5:3] == 3'b000;
    
    // calc address: [load, store]
    wire calc_addr       = is_load_store;

    // [addi,addiu,slti,sltiu,andi,ori,xori,*lui*], R:[add,addu,sub,subu,and,or,xor,nor] [load,store]
    wire is_def          = opcode[5:3] == 3'b001 || (R_op && (func[5:3] == 3'b100)) || calc_addr;
    wire is_aui          = opcode == 6'b001111;
    // MIPS32r6 changes: aui

    // Default ALU, use addiu to calc addr
    wire [2:0]  def_exe = calc_addr ? 3'b001 : (R_op ? func[2:0] : opcode[2:0]);
    wire [31:0] op2     = alu_src ? immd : reg2;
    wire [31:0] inv_op2 = ~op2 + 1;

    reg [31:0] result_mux;
    always @* begin
        casex (def_exe)
            3'b00x: result_mux = reg1 + op2;  // 0: of, 1:u no of
            3'b01x: result_mux = reg1 + inv_op2;  
            3'b100: result_mux = reg1 & op2;
            3'b101: result_mux = reg1 | op2;
            3'b110: result_mux = reg1 ^ op2;
            3'b111: result_mux = is_aui ? ({immd[15:0], 16'b0} + reg1) : ~ (reg1 | op2);
        endcase
    end

    // Set Checker:is_set_op, [slti,sltiu], [slt,sltu]. 
    reg slt_result;
    always @* begin
        if (R_op) begin
            if (func[0] == 1) // unsigned
                slt_result = $unsigned(reg1) < $unsigned(reg2); //sltu
            else
                slt_result = $signed(reg1) < $signed(reg2);     // slt
        end else begin
            if (opcode[0] == 1) // unsigned
                slt_result = $unsigned(reg1) < $unsigned(immd); // sltiu
            else
                slt_result = $signed(reg1) < $signed(immd);     // slti
        end
    end

    // Branch Comparator: is_branch, [beq, bneq, blez, bgtz], REGIMM: [bgez, bal, nal]
    reg do_branch;
    always @* begin
        if (is_regimm_op) begin
            case (rt_id)
                5'b00001: do_branch = reg1[31] == 0;            // bgez
                5'b10001: do_branch = 1;                        // bal
                default:  do_branch = 0;                        // other, including nal
            endcase
        end else begin
            case (opcode[1:0])
                2'b00: do_branch = reg1 == reg2;
                2'b01: do_branch = ~(reg1 == reg2);
                2'b10: do_branch = $signed(reg1) <= 0;          // Signed comparison, less or equal to zero
                2'b11: do_branch = $signed(reg1) > 0;           // Signed comparison, greater than zero
            endcase
        end
    end

    // Shifter: is_shift
    reg [31:0] shift_out;
    // use ins shamt with [sll,srl,sra]
    wire [4:0] real_shamt = func[5:2] == 4'b0000 ? ins_shamt : reg1[4:0];
    always @* begin
        case (func[1:0])
            2'b00: shift_out = reg2 << real_shamt;  // sll
            2'b01: shift_out = func[5:2] == 4'b0001 ? (reg1 << (ins_shamt[1:0] + 1)) + reg2 : 32'b0; // lsa
            2'b10: shift_out = $unsigned(reg2) >> real_shamt;  // srl
            2'b11: shift_out = $signed(reg2) >>> real_shamt; // sra
        endcase
    end

    // SPECIAL3 Operations
    reg [31:0] special3_out;
    wire [4:0] ins_lsb = ins[10:6];
    wire [4:0] ins_msb = ins[15:11];
    integer i;
    always @* begin
        if (func == 6'b000100) begin
            // INS, Insert Bit Field
            // special3_out = {reg2[31:ins_msb+1], reg1[ins_msb - ins_lsb : 0], reg2[ins_lsb-1:0]};
            for(i=0;i<32;i=i+1) begin
                if (i < ins_lsb) special3_out[i] = reg2[i];
                else if (i <= ins_msb && i >= ins_lsb) special3_out[i] = reg1[i-ins_lsb];
                else special3_out[i] = reg2[i];
            end
        end else if (func == 6'b000000) begin
            // EXT
            // special3_out = {32'b0 ,reg1[ins_lsb+ins_msb:ins_lsb]};
            for(i=0;i<32;i=i+1) begin
                if (i <= ins_msb) special3_out[i] = reg1[i + ins_lsb];
                else special3_out[i] = 1'b0;
            end
        end else if (func == 6'b100000) begin
            // BSHFL
            case (ins_shamt)
                // 5'b00000 : special3_out = {reg2[0], reg2[1], reg2[2], reg2[3], reg2[4], }  // BITSWAP
                5'b10000 : special3_out = {{24{reg2[7]}}, reg2[7:0]};      // seb
                5'b11000 : special3_out = {{16{reg2[15]}}, reg2[15:0]};    // seh
                default  : special3_out = 32'b0;
            endcase
        end else 
            special3_out = 32'b0;
    end

    // Multiplier
    wire is_mul = R_op && func[5:1] == 5'b01100;
    wire mul_unsign = func[0];
    wire mul_done;

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
        if (is_set_op)
            result = {31'b0, slt_result};
        else if (is_mul)
            result = mul_mux;
        else if (is_def)
            result = result_mux;
        else if (is_shift)
            result = shift_out;
        else if (is_link)
            result = next_pc + 4;
        else if (is_branch)
            result = 0;
        else if (is_special3)
            result = special3_out;
        else
            result = 0;
    end

    // Jump & Branch
    // I:[j,jal], R:[jr, jalr]
    // {4'b next_pc | 26'b ins_j_addr | 2'b00 }
    wire is_jr = R_op && func[5:1] == 5'b00100;
    wire [25:0] ins_j_addr = ins[25:0];
    wire [31:0] jump_addr_ext = {next_pc[31:28], ins_j_addr[25:0] , 2'b0};
    wire [31:0] branch_addr_ext = next_pc + {immd[29:0] , 2'b0};
    always @* begin
        if (is_jump) begin
            do_jump = 1;
            if (is_jr)
                j_addr = reg1;
            else
                j_addr = jump_addr_ext;
        end else if (is_branch && do_branch) begin
            do_jump = 1;
            j_addr = branch_addr_ext;
        end else begin
            do_jump = 0;
            j_addr = 0;
        end
    end

endmodule