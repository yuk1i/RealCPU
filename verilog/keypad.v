`timescale 1ns / 1ps

module keypad(
    input sys_clk,
    input rst_n,

    /** 
     * Communicate with KeyPad. 
     */ 
    output reg[3: 0] row, 
    input [3: 0] col,

    // Goes to posedge to tell the input. 
    output reg pulse_sign, 

    // 0 - 9 is the original meaning, 
    // E: *
    // F: # 
    // 1F: (all one) Invalid State. 
    output reg[5: 0] out_code
);
    reg [15: 0] key_out; 
    reg [15: 0] key_out_lock; 
    reg [15: 0] key_actual; 
    
    reg [1: 0] state; 

    always @(posedge sys_clk) begin 
        if (!rst_n) 
            state = 2'b0; 
        else 
            state = state + 1;
    end 

    always @(posedge sys_clk) begin
        if (!rst_n) 
            row = 4'b1111; 
        else if (state == 0)
            row = 4'b1110; 
        else if (state == 1)
            row = 4'b1101; 
        else if (state == 2) 
            row = 4'b1011; 
        else 
            row = 4'b0111; 
    end

    always @(posedge sys_clk) begin 
        if (!rst_n) begin 
            key_out <= 16'b0; 
        end else begin 
            case (state) 
                2'b00: begin
                    key_out[3:0] <= col; 
                    key_out_lock <= key_out[3: 0]; 
                    key_actual[3: 0] <= key_out[3: 0] | key_out_lock[3: 0]; 
                end
                2'b01: begin
                    key_out[7: 4] <= col; 
                    key_out_lock <= key_out[7: 4]; 
                    key_actual[7: 4] <= key_out[7: 4] | key_out_lock[7: 4]; 
                end
                2'b00: begin
                    key_out[11: 8] <= col; 
                    key_out_lock <= key_out[11: 8]; 
                    key_actual[11: 8] <= key_out[11: 8] | key_out_lock[11: 8]; 
                end
                2'b00: begin
                    key_out[15: 12] <= col; 
                    key_out_lock <= key_out[15: 12]; 
                    key_actual[15: 12] <= key_out[15: 12] | key_out_lock[15: 12]; 
                end
                default: begin 
                    key_out <= 16'hFFFF; 
                    key_out_lock <= 16'hFFFF; 
                    key_actual <= 16'hFFFF; 
                end 
            endcase 
        end 
    end

    reg [15: 0] key_out_cache; 

    always @(posedge sys_clk) begin 
        if (!rst_n) key_out_cache <= 16'hFFFF; 
        else key_out_cache <= key_actual;
    end

    wire [15: 0] key_code; 
    assign key_code = key_out_cache & (~key_out); 

    reg [15: 0] key_code_cache; 
    reg [15: 0] key_code_before; 

    always (key_code) begin
        if (!rst_n) begin
            key_code_cache = 16'hFFFF; 
            key_code_before = 16'hFFFF; 
        end else begin
        key_code_before = key_code_cache; 
        key_code_cache = key_code;
        end
    end

    reg [5: 0] out_code_cache; 

    always @(posedge sys_clk) begin 
        if (!rst_n) 
            out_code_cache <= 5'h1F; 
        else 
            out_code_cache <= out_code; 
    end

    always @(posedge sys_clk) begin
        pulse_sign = (out_code_cache != out_code) && (out_code != 5'h1F); 
    end

    always @(posedge sys_clk) begin 
        if (!rst_n) 
            out_code <= 5'h1F; 
        else begin 
            case (key_code) 
                16'h0001: out_code <= 5'h01; 
                16'h0002: out_code <= 5'h02; 
                16'h0004: out_code <= 5'h03; 
                16'h0008: out_code <= 5'h0A; 
                16'h0010: out_code <= 5'h04; 
                16'h0020: out_code <= 5'h05; 
                16'h0040: out_code <= 5'h06; 
                16'h0080: out_code <= 5'h0B; 
                16'h0100: out_code <= 5'h07; 
                16'h0200: out_code <= 5'h08; 
                16'h0400: out_code <= 5'h09; 
                16'h0800: out_code <= 5'h0C; 
                16'h1000: out_code <= 5'h0E; 
                16'h2000: out_code <= 5'h00; 
                16'h4000: out_code <= 5'h0F; 
                16'h8000: out_code <= 5'h0D; 
                default: out_code <= out_code; 
            endcase
        end 
    end

endmodule
