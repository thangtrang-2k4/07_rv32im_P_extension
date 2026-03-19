package rv32_pkg;

  //Immediate Generator Select
  typedef enum logic [2:0] {
    Imm_I = 3'b000,
    Imm_S = 3'b001,
    Imm_B = 3'b010,
    Imm_U = 3'b011,
    Imm_J = 3'b100
  }ImmSel_t;

  // ALU Select
  typedef enum logic [4:0] {
    // rv32i base
    ALU_ADD    = 5'b00000,   // rs1 + rs2
    ALU_SUB    = 5'b00001,   // rs1 - rs2
    ALU_SLT    = 5'b00010,   // signed less-than
    ALU_SLTU   = 5'b00011,   // unsigned less-than
  
    ALU_AND    = 5'b00100,   // bitwise AND
    ALU_OR     = 5'b00101,   // bitwise OR
    ALU_XOR    = 5'b00110,   // bitwise XOR
  
    ALU_SLL    = 5'b00111,   // shift left logical
    ALU_SRL    = 5'b01000,   // shift right logical
    ALU_SRA    = 5'b01001,   // shift right arithmetic

    ALU_LUI    = 5'b01010,
    ALU_JALR   = 5'b01011,

    // M extension
    ALU_MUL    = 5'b01100,
    ALU_MULH   = 5'b01101,
    ALU_MULHSU = 5'b01110,
    ALU_MULHU  = 5'b01111,
    ALU_DIV    = 5'b10000,
    ALU_DIVU   = 5'b10001,
    ALU_REM    = 5'b10011,
    ALU_REMU   = 5'b10100,

    // P extension
    ALU_PADD.B = 5'b10101,
    ALU_PADD.H = 5'b10110
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
    OC_P         = 7'b0111011
  } opcode_t;

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
  // Pipeline control + struct
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
  } ctrl_t;


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

endpackage
