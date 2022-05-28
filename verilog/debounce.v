`timescale 1ns/1ps

module debounce (
    input sys_clk,
    input rst_n,

    input btn_input,
    output reg status
);
    // 40M, hold 10ms, count to 40,000
    reg [15:0] counter;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            counter <= 16'b0;
            status <= 0;
        end else begin
            case ({status, btn_input})
                2'b00   : begin
                    counter <= 16'b0;
                    status <= status;
                end
                2'b01   : begin
                    if (counter == 16'd40000) begin
                        status <= 1;
                        counter <= 16'b0;
                    end else 
                        counter <= counter + 1;
                end
                2'b10 : begin
                    if (counter == 16'd40000) begin
                        status <= 0;
                        counter <= 16'b0;
                    end else 
                        counter <= counter + 1;
                end
                2'b11 : begin
                    counter <= 16'b0;
                    status <= status;
                end 
            endcase
        end
    end
    
endmodule