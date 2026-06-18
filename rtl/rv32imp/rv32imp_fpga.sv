module rv32imp_fpga (
    input  logic MAX10_CLK1_50, // 50MHz clock input
    input  logic [0:0] KEY,     // KEY[0] as active-low Reset
    output logic [9:0] LEDR     // 10 LEDs output
);
    logic [31:0] obs_data;
    logic [31:0] obs_reg;

//    // 1. System Heartbeat (1Hz flashing LED)
//    Clock_Divider #(.DIV(25_000_000)) u_heartbeat (
//        .clk_in (MAX10_CLK1_50),
//        .rst_n  (KEY[0]),
//        .clk_out(clk_1hz)
//    );

    // 2. RV32IMP CPU Instance
    rv32imp_pipeline #(
        .IMEM_DEPTH(1024),
        .DMEM_DEPTH(4098)
    ) u_core (
        .clk       (MAX10_CLK1_50),
        .rst_n     (KEY[0]),
        .o_obs_data(obs_data)
    );

    // 3. Register the observation data
    always_ff @(posedge MAX10_CLK1_50 or negedge KEY[0]) begin
        if (!KEY[0]) obs_reg <= 32'h0;
        else         obs_reg <= obs_data;
    end

    // 4. LED Output Mapping
    assign LEDR[0]   = obs_reg[31];                                    // MSB of observation data
    assign LEDR[9:1] = obs_reg[8:0] ^ obs_reg[17:9] ^ obs_reg[26:18]; // folded XOR

endmodule
