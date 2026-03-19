package rv32_pkg;

  //Immediate Generator Select
  typedef enum logic [2:0] {
    Imm_I = 3'b000,
    Imm_S = 3'b001,
    Imm_B = 3'b010,
    Imm_U = 3'b011,
    Imm_J = 3'b100,
    Imm_P = 3'b101
  }ImmSel_t;

  // ALU Select
  typedef enum logic [6:0] {
    ALU_ADD  = 7'b0000000,   // rs1 + rs2
    ALU_SUB  = 7'b0000001,   // rs1 - rs2
    ALU_SLT  = 7'b0000010,   // signed less-than
    ALU_SLTU = 7'b0000011,   // unsigned less-than

    ALU_AND  = 7'b0000100,   // bitwise AND
    ALU_OR   = 7'b0000101,   // bitwise OR
    ALU_XOR  = 7'b0000110,   // bitwise XOR

    ALU_SLL  = 7'b0000111,   // shift left logical
    ALU_SRL  = 7'b0001000,   // shift right logical
    ALU_SRA  = 7'b0001001,   // shift right arithmetic

    ALU_LUI  = 7'b0001010,
    ALU_JALR = 7'b0001011,
    ALU_MUL  = 7'b0010000,
    ALU_MULH = 7'b0010001,
    ALU_MULHSU     = 7'b0010010,
    ALU_MULHU      = 7'b0010011,
    ALU_DIV        = 7'b0010100,
    ALU_DIVU       = 7'b0010101,
    ALU_REM        = 7'b0010111,
    ALU_REMU       = 7'b0011000,
    ALU_PADD_B     = 7'b0011001,
    ALU_PADD_H     = 7'b0011010,
    ALU_PSADD_B    = 7'b0011011,
    ALU_PSADD_H    = 7'b0011100,
    ALU_PSADDU_B   = 7'b0011101,
    ALU_PSADDU_H   = 7'b0011110,
    ALU_PAADD_B    = 7'b0011111,
    ALU_PAADD_H    = 7'b0100000,
    ALU_PAADDU_B   = 7'b0100001,
    ALU_PAADDU_H   = 7'b0100010,
    ALU_PSUB_B     = 7'b0100011,
    ALU_PSUB_H     = 7'b0100100,
    ALU_PSSUB_B    = 7'b0100101,
    ALU_PSSUB_H    = 7'b0100110,
    ALU_PSSUBU_B   = 7'b0100111,
    ALU_PSSUBU_H   = 7'b0101000,
    ALU_PASUB_B    = 7'b0101001,
    ALU_PASUB_H    = 7'b0101010,
    ALU_PASUBU_B   = 7'b0101011,
    ALU_PASUBU_H   = 7'b0101100,
    ALU_PAS_HX     = 7'b0101101,
    ALU_PSA_HX     = 7'b0101110,
    ALU_PSAS_HX    = 7'b0101111,
    ALU_PSSA_HX    = 7'b0110000,
    ALU_PAAS_HX    = 7'b0110001,
    ALU_PASA_HX    = 7'b0110010,
    ALU_PMIN_H     = 7'b0110011,
    ALU_PMAX_H     = 7'b0110100,
    ALU_PMINU_H    = 7'b0110101,
    ALU_PMAXU_H    = 7'b0110110,
    ALU_PMSEQ_H    = 7'b0110111,
    ALU_PMSLT_H    = 7'b0111000,
    ALU_PMSLTU_H   = 7'b0111001,
    ALU_PSABS_H    = 7'b0111010,
    ALU_PSATI_H    = 7'b0111011,
    ALU_PUSATI_H   = 7'b0111100,
    ALU_PMHACC_H   = 7'b0111101
  } ALUSel_t;

  //PCSel 
  typedef enum logic {
    PC_PC4 = 1'b0,
    PC_ALU = 1'b1
  } PCSel_t;

  // Write Back Select
  typedef enum logic [1:0] {
    WB_PC4 = 2'b10,
    WB_ALU  = 2'b01,
    WB_MEM  = 2'b00
  } WBSel_t;

  // Opcode 
  typedef enum logic [6:0] {
    OC_R         = 7'b0110011,
    OC_I_ALU     = 7'b0010011,
    OC_I_LOAD    = 7'b0000011,
    OC_S         = 7'b0100011,
    OC_B         = 7'b1100011,
    OC_U_LUI     = 7'b0110111,
    OC_U_AUIPC   = 7'b0010111,
    OC_J         = 7'b1101111,
    OC_I_JALR    = 7'b1100111,
    OC_PEXT      = 7'b0111011,
    OC_PEXT_IMM  = 7'b0011011
  } opcode_t;

  typedef enum logic [1:0] {
    ALU_RESULT,
    ALUP_RESULT
  } rdSel_t;
  //Funct 3
  typedef logic [2:0] funct3_t;

  // M_Extension
  localparam logic [2:0]
    F3_MUL      = 3'b000,
    F3_MULH     = 3'b001,
    F3_MULHSU   = 3'b010,
    F3_MULHU    = 3'b011,
    F3_DIV      = 3'b100,
    F3_DIVU     = 3'b101,
    F3_REM      = 3'b110,
    F3_REMU     = 3'b111;
    

  // R-type
  localparam logic [2:0]
    F3_ADD_SUB  = 3'b000,
    F3_SLL      = 3'b001,
    F3_SLT      = 3'b010,
    F3_SLTU     = 3'b011,
    F3_XOR      = 3'b100,
    F3_SRL_SRA  = 3'b101,
    F3_OR       = 3'b110,
    F3_AND      = 3'b111;
        
  // I-type ALU
  localparam logic [2:0]
    F3_ADDI       = 3'b000,
    F3_SLTI       = 3'b010,
    F3_SLTIU      = 3'b011,
    F3_XORI       = 3'b100,
    F3_ORI        = 3'b110,
    F3_ANDI       = 3'b111,
    F3_SLLI       = 3'b001,
    F3_SRLI_SRAI  = 3'b101;

  // LOAD 
  localparam logic [2:0]
    F3_LB  = 3'b000,
    F3_LH  = 3'b001,
    F3_LW  = 3'b010,
    F3_LBU = 3'b100,
    F3_LHU = 3'b101;
  
  // STORE
  localparam logic [2:0]
    F3_SB = 3'b000,
    F3_SH = 3'b001,
    F3_SW = 3'b010;

  // B-type
  localparam logic [2:0]
    F3_BEQ   = 3'b000,
    F3_BNE   = 3'b001,
    F3_BLT   = 3'b100,
    F3_BGE   = 3'b101,
    F3_BLTU  = 3'b110,
    F3_BGEU  = 3'b111;






  // ==============================
  // 🚀 Pipeline control + struct
  // ==============================

  // Gói tín hiệu điều khiển (control signals)
  typedef struct packed {
    rv32_pkg::ImmSel_t ImmSel;
    logic              BrUn;
    logic              ASel;
    logic              BSel;
    rv32_pkg::ALUSel_t ALUSel;
    logic              MemRW;
    logic [1:0]        MemSize;    
    logic              MemUnsigned;
    logic              RegWEn;
    rv32_pkg::WBSel_t  WBSel;
    rv32_pkg::rdSel_t  rdSel;       // THÊM: Chọn giữa ALU result và ALUP result để viết vào rd
  } ctrl_t;

  // ==============================
  // 🚀 Pipeline stage structures
  // ==============================

  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] inst;
  } if_id_t;

  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    ctrl_t       ctrl;
  } id_ex_t;

  typedef struct packed {
    logic [31:0] pc_plus4;
    logic [31:0] alu_out;
    logic [31:0] rs2_data;
    logic [4:0]  rd;
    ctrl_t       ctrl;
    logic        br_taken;
    logic [31:0] br_target;
  } ex_mem_t;

  typedef struct packed {
    logic [31:0] pc_plus4;
    logic [31:0] mem_rdata;
    logic [31:0] alu_out;
    logic [4:0]  rd;
    ctrl_t       ctrl;
  } mem_wb_t;

  // ==============================
  // 🚀 Default bubble/NOP constants
  // ==============================

  localparam ctrl_t CTRL_NOP = '{
      ImmSel     : Imm_I,      // không quan trọng lắm
      BrUn       : 1'b0,
      ASel       : 1'b0,
      BSel       : 1'b0,
      ALUSel     : ALU_ADD,    // ADD cho an toàn
      MemRW      : 1'b0,       // ❗ không ghi memory
      MemUnsigned: 1'b0,       // không quan trọng
      MemSize    : 2'b10,      // mặc định word (LW)
      RegWEn     : 1'b0,       // ❗ không ghi register
      WBSel      : WB_ALU
  };

  localparam if_id_t IF_ID_BUBBLE = '{
    pc: 32'b0,
    inst: 32'b0
  };

  localparam id_ex_t ID_EX_BUBBLE = '{
    pc: 32'b0,
    rs1_data: 32'b0,
    rs2_data: 32'b0,
    imm: 32'b0,
    rs1: 5'b0,
    rs2: 5'b0,
    rd: 5'b0,
    ctrl: CTRL_NOP
  };

  localparam ex_mem_t EX_MEM_BUBBLE = '{
    pc_plus4: 32'b0,
    alu_out: 32'b0,
    rs2_data: 32'b0,
    rd: 5'b0,
    ctrl: CTRL_NOP,
    br_taken: 1'b0,
    br_target: 32'b0
  };

  localparam mem_wb_t MEM_WB_BUBBLE = '{
    pc_plus4: 32'b0,
    mem_rdata: 32'b0,
    alu_out: 32'b0,
    rd: 5'b0,
    ctrl: CTRL_NOP
  };

endpackage
