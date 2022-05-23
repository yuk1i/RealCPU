module coproc0 (
    input sys_clk, 
    input rst_n,

    input is_coproc0_ins,
    input [31:0] instr,
    input [31:0] mtc0_data,

    output is_c0_out,
    output [31:0] mfc0_data_o
);

    // Support Instructions:
    // [DI, Disable Interrupt]

    wire [4:0] rs_id = ins_i[25:21];
    wire [4:0] rt_id = ins_i[20:16];
    wire [4:0] rd_id = ins_i[15:11];

    wire move_to_c0     = rs_id == 5'b00100;
    wire move_from_c0   = rs_id == 5'b00000;
    wire disable_int    = rs_id == 5'b01011;

    assign is_c0_out    = move_from_c0 || disable_int;
    assign mfc0_data_o  = co0_regs[]

    reg [31:0] co0_regs [0:31];
    integer i;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            for (i = 0; i<32; i=i+1) begin
                co0_regs[i] <= 32'h0;
            end 
        end else begin
            for (i = 0; i<32; i=i+1) begin
                if (is_coproc0_ins && move_to_c0 && i == rd_id)
                    co0_regs[i] <= mtc0_data;
                else
                    co0_regs[i] <= co0_regs[i];
            end 
        end
    end
endmodule