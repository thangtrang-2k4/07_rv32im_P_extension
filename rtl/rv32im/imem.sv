module IMem #(
    parameter int DEPTH_WORDS = 16384,
    parameter logic [31:0] BASE_ADDR = 32'h8000_0000
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        i_stb,
    input  logic [31:0] i_addr,
    output logic        o_ack,
    output logic [31:0] o_inst
);

    // Force Quartus infer block RAM
    (* ramstyle = "M10K" *)
    logic [31:0] rom_array [0:DEPTH_WORDS - 1];

    localparam int ADDR_BITS = $clog2(DEPTH_WORDS);

    logic [ADDR_BITS-1:0] word_addr;

    assign word_addr = i_addr[ADDR_BITS+1:2] - BASE_ADDR[ADDR_BITS+1:2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_ack  <= 1'b0;
        end else begin
            o_ack <= i_stb;
        end
    end

    // M10K inference requires read register to NOT have async reset
    always_ff @(posedge clk) begin
        if (i_stb) begin
            o_inst <= rom_array[word_addr];
        end
    end

    // Load program
    initial begin
`ifdef SIM
        $readmemh("../sw/Filter-Fir/scala_imem.hex", rom_array);
`else
        $readmemh("../../sw/Filter-Fir/scala_imem.hex", rom_array);
`endif
    end
endmodule
