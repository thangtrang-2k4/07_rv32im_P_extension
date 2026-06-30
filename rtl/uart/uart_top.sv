module uart_top #(
        // fifo
        parameter integer DATA_WIDTH = 8,
        parameter integer DEPTH      = 8,
        parameter         AF_LEVEL   = 1,
        parameter         AE_LEVEL   = 1,

        // rx, tx
        parameter integer DBIT    = 8, 
        parameter integer DB_TICK = 16,
        parameter integer SB_TICK = 16
        ) (
        input  logic            clk,
        input  logic            rst_n,
        input  logic            rd_en,
        input  logic            wr_en,
        input  logic [DBIT-1:0] wr_data,
        input  logic            rx,

        output logic            tx,
        output logic [DBIT-1:0] rd_data,
        output logic            rx_empty,
        output logic            tx_full
        );
    import uart_pkg::*;
    
    logic            tick;
    logic [DBIT-1:0] fifo_rx_din, fifo_rx_dout, fifo_tx_din, fifo_tx_dout;
    logic            fifo_rx_wr, fifo_rx_rd, fifo_tx_wr, fifo_tx_rd;
    logic            fifo_rx_empty, fifo_rx_full, fifo_rx_alempty, fifo_rx_alfull;
    logic            fifo_rx_overflow, fifo_rx_usedw;
    logic            fifo_tx_empty, fifo_tx_full, fifo_tx_alempty, fifo_tx_alfull;
    logic            fifo_tx_overflow, fifo_tx_usedw;

    assign rd_data     = fifo_rx_dout;
    assign fifo_rx_rd  = rd_en;
    assign rx_empty       = fifo_rx_empty;

    assign fifo_tx_din = wr_data;
    assign fifo_tx_wr  = wr_en;
    assign tx_full        = fifo_tx_full;

    // BAUD RATE GENERATOR
    baud_rate #(
            .M(163)
            ) baud (
            .clk(clk),
            .rst_n(rst_n),
    
            .tick(tick)
            );
    // RECEIVER
    rx #(
        .DBIT(DBIT),
        .DB_TICK(DB_TICK),
        .SB_TICK(SB_TICK)
        ) receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tick(tick),
    
        .dout(fifo_rx_din),
        .rx_done_tick(fifo_rx_wr)
        );
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .AF_LEVEL(AF_LEVEL),
        .AE_LEVEL(AE_LEVEL)
        ) rx_fifo (
        .clk(clk),
        .sclr_n(rst_n),
        .aclr_n(1'b1),
        .din(fifo_rx_din),
        .wr_en(fifo_rx_wr),
        .rd_en(fifo_rx_rd),
        
        .dout(fifo_rx_dout),
        .full(fifo_rx_full),
        .almost_full(fifo_rx_alfull),
        .empty(fifo_rx_empty),
        .almost_empty(fifo_rx_alempty),
        .overflow(fifo_rx_overflow),
        .usedw(fifo_rx_usedw)
        );
    // TRANSMITTER
    tx #(
        .DBIT(DBIT),
        .DB_TICK(DB_TICK),
        .SB_TICK(SB_TICK)
        ) transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .tx_start(~fifo_tx_empty),
        .din(fifo_tx_dout),
    
        .tx(tx),
        .tx_done_tick(fifo_tx_rd)
        );
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .AF_LEVEL(AF_LEVEL),
        .AE_LEVEL(AE_LEVEL)
        ) tx_fifo (
        .clk(clk),
        .sclr_n(rst_n),
        .aclr_n(1'b1),
        .din(fifo_tx_din),
        .wr_en(fifo_tx_wr),
        .rd_en(fifo_tx_rd),
        
        .dout(fifo_tx_dout),
        .full(fifo_tx_full),
        .almost_full(fifo_tx_alfull),
        .empty(fifo_tx_empty),
        .almost_empty(fifo_tx_alempty),
        .overflow(fifo_tx_overflow),
        .usedw(fifo_tx_usedw)
        );
endmodule
