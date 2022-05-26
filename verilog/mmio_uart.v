`timescale 1ns / 1ps
module mmio_uart(
    input sys_clk,
    input rst_n,
    
    input mmio_read,
    input mmio_write,
    input [31:0] mmio_addr,
    input [31:0] mmio_write_data,

    output mmio_work,
    output reg mmio_done,
    output reg [31:0] mmio_read_data,

    // IO Pins
    input uart_rx_pin,
    output uart_tx_pin,
    input bank_sys_clk
);
    wire uart_clk = sys_clk;
    // UART
    // Address: 0xFFFF0120 - 0xFFFF013F, 8 words, 32 bytes
    //          0b100100000, 0b100111111
    // RX VALID: 0xFFFF0120      // ro, set by UART
    // RX FIFO : 0xFFFF0124      // ro, read until RX READY is off
    // TX BUSY : 0xFFFF0128      // ro
    // TX FULL : 0xFFFF012C      // ro, 
    // TX SEND : 0xFFFF0130      // rw, set by system, then pull down by UART
    // TX FIFO : 0xFFFF0134      // wo
    wire [2:0] _addr = mmio_addr[4:2];
    assign mmio_work = (mmio_read || mmio_write) && mmio_addr[31:16] == 16'HFFFF && mmio_addr[15:5] == 11'b00000001_001;

    wire acc_rx_valid   = mmio_work && _addr == 3'b000;  // ro
    wire acc_rx_fifo    = mmio_work && _addr == 3'b001;  // ro
    wire acc_tx_busy    = mmio_work && _addr == 3'b010;  
    wire acc_tx_full    = mmio_work && _addr == 3'b011;
    wire acc_tx_send    = mmio_work && _addr == 3'b100;  // wr
    wire acc_tx_fifo    = mmio_work && _addr == 3'b101;  // wo

    reg acc_rx_fifo_d;
    always @(posedge sys_clk) acc_rx_fifo_d <= acc_rx_fifo;
    reg uart_tx_start;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            mmio_done <= 0;
            mmio_read_data <= 0;
            uart_tx_start <= 0;
        end else begin
            if (mmio_done) begin
                mmio_done <= 0;
                mmio_read_data <= 0;
            end else if (mmio_work) begin
                if (acc_rx_fifo && !acc_rx_fifo_d)
                    mmio_done <= 0;
                else 
                    mmio_done <= 1;
                if (acc_rx_valid)       mmio_read_data <= {31'b0, !rx_fifo_empty};
                else if (acc_rx_fifo)   mmio_read_data <= {24'b0, rx_fifo_r_dout};
                //  rx_fifo_read is done at sys_clk negedge, sampling at posedge 
                else if (acc_tx_busy)   mmio_read_data <= {31'b0, !tx_fifo_empty};
                else if (acc_tx_full)   mmio_read_data <= {31'b0, tx_fifo_full};
                else if (acc_tx_send)   mmio_read_data <= {31'b0,  uart_tx_start};
                else if (acc_tx_fifo)   mmio_read_data <= 32'b0;
                else mmio_read_data <= 32'b0;
                if (mmio_write && acc_tx_send)
                    uart_tx_start <= mmio_write_data[0];
                else
                    uart_tx_start <= uart_tx_start;
            end else begin
                if (uart_tx_start && tx_fifo_empty)
                    uart_tx_start <= 0;
                else begin
                    uart_tx_start <= uart_tx_start;
                end
            end
        end
    end
    
    wire [7:0]  tx_fifo_w_din  =  mmio_write_data[7:0];
    wire        tx_fifo_w_en =  mmio_work && mmio_write && acc_tx_fifo && !mmio_done;  // write to tx fifo 
    wire        tx_fifo_full;
    wire [7:0]  tx_fifo_r_dout;
    wire        tx_fifo_r_ren;
    wire        tx_fifo_empty;
    uart_fifo tx_fifo(
        .rst(fifo_rst),
        // write, from host, use cpu clk
        .clk(sys_clk),
        .din(tx_fifo_w_din),
        .wr_en(tx_fifo_w_en),
        .full(tx_fifo_full),
        // read, from UART, use uart clk
        .dout(tx_fifo_r_dout),
        .rd_en(tx_fifo_r_ren),
        .empty(tx_fifo_empty)
    );

    localparam  TX_STATUS_IDLE  = 3'b000,
                TX_STATUS_WORK  = 3'b001,
                TX_STATUS_READ  = 3'b010,
                TX_STATUS_READ2 = 3'b011,
                TX_STATUS_READ3 = 3'b100,
                TX_STATUS_START = 3'b110,
                TX_STATUS_WAIT  = 3'b111;
    reg [2:0]   uart_tx_status;
    assign      tx_fifo_r_ren   = uart_tx_status == TX_STATUS_READ;
    assign      uart_tx_en      = uart_tx_status == TX_STATUS_START;
    assign      uart_tx_din     = tx_fifo_r_dout;
    always @(posedge uart_clk) begin
        if (!rst_n) begin
            uart_tx_status <= 0;
        end else begin
            if (uart_tx_status == TX_STATUS_IDLE) begin
                if (uart_tx_start && !tx_fifo_empty) 
                    uart_tx_status <= TX_STATUS_WORK;
                else
                    uart_tx_status <= uart_tx_status;
            end else begin
                if (uart_tx_status == TX_STATUS_WORK) begin
                    if (tx_fifo_empty)
                        uart_tx_status <= TX_STATUS_IDLE;
                    else if (!uart_tx_busy) 
                        uart_tx_status <= TX_STATUS_READ;
                    else 
                        uart_tx_status <= uart_tx_status;
                end else if (uart_tx_status == TX_STATUS_READ) begin
                    uart_tx_status <= TX_STATUS_START;
                end else if (uart_tx_status == TX_STATUS_START) begin
                    uart_tx_status <= TX_STATUS_WAIT;
                end else if (uart_tx_status == TX_STATUS_WAIT) begin
                    if (uart_tx_busy) 
                        uart_tx_status <= uart_tx_status;
                    else 
                        uart_tx_status <= TX_STATUS_WORK;
                end
            end
        end
    end

    wire uart_tx_en;
    wire uart_tx_busy;
    wire [7:0] uart_tx_din;
    uart_send uart_tx(
        .sys_clk(uart_clk),
        .sys_rst_n(rst_n),

        .uart_en(uart_tx_en),
        .uart_din(uart_tx_din),
        .uart_tx_busy(uart_tx_busy),

        .uart_txd(uart_tx_pin)
    );

    wire [7:0]  rx_fifo_w_din   = uart_rx_data_algn;
    wire        rx_fifo_w_en    = uart_rx_done_algn && ! rx_fifo_full;
    wire        rx_fifo_full;
    reg [7:0]  rx_fifo_r_dout;
    wire [7:0]  rx_fifo_r_dout_w;
    wire        rx_fifo_r_en    = mmio_work && mmio_read && acc_rx_fifo && !mmio_done && !acc_rx_fifo_d;
    wire        rx_fifo_empty;
    rx_uart_fifo rx_fifo(
        .rst(fifo_rst),
        // write, from UART, use uart clk
        .clk(sys_clk),
        .din(rx_fifo_w_din),
        .wr_en(rx_fifo_w_en),
        .full(rx_fifo_full),
        // read, from host, use cpu clk
        .dout(rx_fifo_r_dout_w),
        .rd_en(rx_fifo_r_en),
        .empty(rx_fifo_empty)
    );
    always @(negedge sys_clk) begin
        if (mmio_work && mmio_read && acc_rx_fifo && !mmio_done && acc_rx_fifo_d)
            rx_fifo_r_dout <= rx_fifo_r_dout_w;
        else 
            rx_fifo_r_dout <= 8'b0;
    end
    reg [7:0] uart_rx_data_algn;
    reg       uart_rx_done_algn;
    reg       uart_rx_done_wait_neg;
    always @(posedge uart_clk) begin
        if (!rst_n) begin
            uart_rx_data_algn <= 0;
            uart_rx_done_algn <= 0;
            uart_rx_done_wait_neg <= 0;
        end else begin
            if (uart_rx_done_wait_neg) begin
                uart_rx_data_algn <= 0;
                uart_rx_done_algn <= 0;
                uart_rx_done_wait_neg <= uart_rx_done;
            end else begin
                if (!uart_rx_done_algn && uart_rx_done) begin
                    uart_rx_done_algn <= 1;
                    uart_rx_data_algn <= uart_rx_data;
                    uart_rx_done_wait_neg <= 1;
                end else begin
                    uart_rx_done_algn <= 0;
                    uart_rx_data_algn <= 8'b0;
                    uart_rx_done_wait_neg <= 0;
                end
            end
        end
    end

    wire [7:0] uart_rx_data;
    wire uart_rx_done;
    uart_recv uart_rx(
        .sys_clk(uart_clk),
        .sys_rst_n(rst_n),
        
        .uart_done(uart_rx_done),
        .uart_data(uart_rx_data),

        .uart_rxd(uart_rx_pin)
    );

    // Generate RST Signal for FIFOs, active high
    reg fifo_rst;
    reg [4:0] rst_cnt;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            fifo_rst <= 1;
            rst_cnt <= 5'b1;
        end else begin
            if (fifo_rst) begin
                rst_cnt <= rst_cnt + 1;
                if (rst_cnt == 5'b11111)
                    fifo_rst <= 0;
                else
                    fifo_rst <= fifo_rst;
            end else begin
                rst_cnt <= 0;
                fifo_rst <= 0;
            end
        end
    end 
endmodule
