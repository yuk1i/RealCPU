`timescale 1ns / 1ns

module sim_top();
    reg bank_sys_clk;
    reg bank_rst;
    reg [23:0] switches_pin;

    initial begin 
        bank_sys_clk = 0;
        bank_rst = 1;
        switches_pin = 0;
        #11 bank_rst = 0;

        #100 switches_pin = 24'b00000000_00000000_00000001;
        #100 switches_pin = 24'b00000000_00000000_00000011;
        #100 switches_pin = 24'b00000000_00000000_00000111;
    end

    always #5 bank_sys_clk = ~bank_sys_clk;
    wire sys_clk;
    wire uart_rx;
    wire uart_tx;
    top ttop(
        .bank_sys_clk(bank_sys_clk),
        .bank_rst(bank_rst),
        .switches_pin(switches_pin),

        .uart_rx_pin(uart_rx),
        .uart_tx_pin(uart_tx),
        .sim_sys_clk(sys_clk)
    );
    reg send;
    reg [7:0] dsend;
    wire uart_tx_busy;
    uart_send test_send(
        .sys_clk(sys_clk),
        .sys_rst_n(!bank_rst),

        .uart_en(send),
        .uart_din(dsend),
        .uart_tx_busy(uart_tx_busy),
        .uart_txd(uart_rx)
    );

    initial begin
        dsend = 8'hab;
        send = 0;
        #20
        send = 1;
        #20
        send = 0;
        
    end
    always wait(!uart_tx_busy && !bank_rst) begin
            #200 send = 1; 
            #20 send = 0;
    end

    wire sim_uart_rx_done;
    wire [7:0] sim_uart_rx_data;
    uart_recv test_recv(
        .sys_clk(sys_clk),
        .sys_rst_n(!bank_rst),
        .uart_rxd(uart_tx),
        .uart_done(sim_uart_rx_done),
        .uart_data(sim_uart_rx_data)
    );
endmodule
