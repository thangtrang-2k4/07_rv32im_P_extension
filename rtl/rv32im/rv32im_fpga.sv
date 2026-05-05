module rv32im_fpga (
    input  logic MAX10_CLK1_50, // 50MHz clock input
    input  logic [0:0] KEY,     // KEY[0] as active-low Reset
    output logic [9:0] LEDR     // 10 LEDs output
);
    logic clk_1hz;
    logic [31:0] obs_data;

    // 1. System Heartbeat (1Hz flashing LED)
    Clock_Divider #(.DIV(25_000_000)) u_heartbeat (
        .clk_in (MAX10_CLK1_50),
        .rst_n  (KEY[0]),
        .clk_out(clk_1hz)
    );

    // 2. RV32IM CPU Instance
    rv32im_pipeline #(
        .DEPTH_WORDS(16384) // 64KB Internal BRAM
    ) u_core (
        .clk       (MAX10_CLK1_50),
        .rst_n     (KEY[0]),
        .o_obs_data(obs_data)
    );

    // 3. LED Output Mapping
    assign LEDR[0] = clk_1hz;
    // Map 31 bits of observation data to 9 LEDs using XOR reduction
    assign LEDR[9:1] = obs_data[8:0] ^ obs_data[17:9] ^ obs_data[26:18];

endmodule
