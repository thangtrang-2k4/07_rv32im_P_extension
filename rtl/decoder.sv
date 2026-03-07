module decoder (
    input  logic [31:0] inst,
    output rv32_pkg::opcode_t opcode,
    output logic [4:0]  rd,
    output rv32_pkg::funct3_t funct3,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [6:0]  funct7,
    output logic [24:0] inst_imm
);
    import rv32_pkg::*;

    assign opcode   = opcode_t'(inst[6:0]);
    assign rd       = inst[11:7];
    assign funct3   = inst[14:12];
    assign rs1      = inst[19:15];
    assign rs2      = inst[24:20];
    assign funct7   = inst[31:25];
    assign inst_imm = inst[31:7];

endmodule
