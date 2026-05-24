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

    localparam int ADDR_BITS = $clog2(DEPTH_WORDS);

    logic [ADDR_BITS-1:0] word_addr;

    assign word_addr = i_addr[ADDR_BITS+1:2] - BASE_ADDR[ADDR_BITS+1:2];

    // Ack: registered strobe
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            o_ack <= 1'b0;
        else
            o_ack <= i_stb;
    end

    // ROM: synchronous read, no write ports
    (* ramstyle = "M10K" *)
    logic [31:0] rom_array [0:DEPTH_WORDS - 1];

    always_ff @(posedge clk) begin
        o_inst <= rom_array[word_addr];
    end

    initial begin
        $readmemh("../../sw/Filter-Fir/pext_imem.hex", rom_array);
    end

endmodule
