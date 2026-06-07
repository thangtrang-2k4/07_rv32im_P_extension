module IMem #(
    parameter int DEPTH_WORDS = 16384,
    parameter logic [31:0] BASE_ADDR = 32'h8000_0000
)(
    input  logic        rst_n,
    input  logic [31:0] addr,
    output logic [31:0] inst
);

    // Force Quartus infer block RAM
    (* ramstyle = "M10K" *)
    logic [31:0] rom_array [0:DEPTH_WORDS - 1];

    logic [31:0] word_addr;

    //assign word_addr = addr[31:2];   // word aligned
    assign word_addr = (addr - BASE_ADDR) >> 2;
    //assign word_addr = addr >> 2;

    // Use continuous assignment for the RAM read
    wire [31:0] rom_data = (word_addr < DEPTH_WORDS) ? rom_array[word_addr] : 32'h00000013; // NOP if out of bounds

    always_comb begin
        if (!rst_n)
            inst = 32'h00000013; // NOP
        else
            inst = rom_data;
    end

    // Load program
    initial begin
        $readmemh("../../sw/matrix-multiplication/pext_imem.hex", rom_array);
    end
endmodule
