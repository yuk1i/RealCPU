`timescale 1ns / 1ps
module mmio_addr(
    input [31:0] addr,
    output reg is_mmio
);
    always @* begin
        casex(addr)
            31'hFFFF????:   is_mmio = 1;
            default:        is_mmio = 0;
        endcase
    end

endmodule
