module rv32imp_fpga (
    input  logic MAX10_CLK1_50, // 50MHz clock input
    input  logic [0:0] KEY,     // KEY[0] as active-low Reset
    output logic [9:0] LEDR,    // 10 LEDs output
    output logic UART_TXD,
    input  logic UART_RXD
);
    logic [31:0] obs_data;
    logic [31:0] obs_reg;

    logic clk_5M;
    logic done_flag;
    Clock_Divider #(.DIV(5)) u_clk_div (
        .clk_in (MAX10_CLK1_50),
        .rst_n  (KEY[0]),
        .clk_out(clk_5M)
    );

    // UART Memory Interface
    logic [31:0] dump_ram_addr;
    logic [31:0] dump_ram_rdata;

    // 2. RV32IMP CPU Instance
    rv32imp_pipeline #(
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(4096)
    ) u_core (
        .clk       (clk_5M),
        .rst_n     (KEY[0]),
        .o_obs_data(obs_data),
        .o_done    (done_flag),
        .uart_clk  (MAX10_CLK1_50),
        .uart_addr (dump_ram_addr),
        .uart_dataR(dump_ram_rdata)
    );

    // 3. Register the observation data
    always_ff @(posedge MAX10_CLK1_50 or negedge KEY[0]) begin
        if (!KEY[0]) obs_reg <= 32'h0;
        else         obs_reg <= obs_data;
    end

    // 4. LED Output Mapping
    assign LEDR[0]   = 1'b0; // Turn off observation LEDs
    assign LEDR[8:1] = 8'b0; // Turn off observation LEDs
    assign LEDR[9]   = done_flag;                                      // DONE flag

    // -----------------------------------------------------------------
    // UART DUMP INTEGRATION
    // -----------------------------------------------------------------

    // Edge detector for done_flag (sync to 50MHz)
    logic done_q1, done_q2, dump_start;
    always_ff @(posedge MAX10_CLK1_50 or negedge KEY[0]) begin
        if (!KEY[0]) begin
            done_q1 <= 1'b0;
            done_q2 <= 1'b0;
        end else begin
            done_q1 <= done_flag;
            done_q2 <= done_q1;
        end
    end
    assign dump_start = done_q1 & ~done_q2; // Rising edge

    wire       uart_tx_full;
    wire       uart_wr_en;
    wire [7:0] uart_wr_data;
    
    // SRAM Dump Controller (Base Addr: 0, Count: 4096 words)
    sram_dump_uart #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .BASE_ADDR(32'd1048), 
        .COUNT(1024)
    ) u_dump (
        .clk(MAX10_CLK1_50),
        .rst_n(KEY[0]),
        .start(dump_start),
        .active(), // not needed
        .done(),   // not needed
        .ram_addr(dump_ram_addr_word),
        .ram_rdata(dump_ram_rdata),
        .uart_tx_full(uart_tx_full),
        .uart_wr_en(uart_wr_en),
        .uart_wr_data(uart_wr_data)
    );
    
    wire [31:0] dump_ram_addr_word;
    assign dump_ram_addr = 32'h8001_0000 + (dump_ram_addr_word << 2);

    // UART Top Module (Baud 115200 at 50MHz -> M=27)
    uart_top #(
        .DATA_WIDTH(8),
        .DEPTH(16),
        .AF_LEVEL(14),
        .AE_LEVEL(2),
        .DBIT(8),
        .DB_TICK(16),
        .SB_TICK(16)
    ) u_uart (
        .clk(MAX10_CLK1_50),
        .rst_n(KEY[0]),
        .rd_en(1'b0),
        .wr_en(uart_wr_en),
        .wr_data(uart_wr_data),
        .rx(UART_RXD),
        .tx(UART_TXD),
        .rd_data(),
        .rx_empty(),
        .tx_full(uart_tx_full)
    );

endmodule
