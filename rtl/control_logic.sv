module Control_Logic (
                      input rv32_pkg::opcode_t  opcode,
                      input rv32_pkg::funct3_t  funct3,
                      input logic [6:0]         funct7,
                      //input logic               BrEq, 
                      //input logic               BrLT,

                      //output rv32_pkg::PCSel_t  PCSel,
                      output rv32_pkg::ImmSel_t ImmSel,
                      output logic              BrUn,
                      output logic              ASel,
                      output logic              BSel,
                      output rv32_pkg::ALUSel_t ALUSel,
                      output logic              MemRW,
                      output logic [1:0]        MemSize,     // 00=byte, 01=half, 10=word
                      output logic              MemUnsigned, // 1 = zero extend
                      output logic              RegWEn,
                      output rv32_pkg::WBSel_t  WBSel,
                      output rv32_pkg::rdSel_t  rdSel
);
   
   import rv32_pkg::*;

   always_comb begin
     // ===== Defaults to avoid latches =====
     //PCSel  = PC_PC4;
     ImmSel = Imm_I;
     BrUn   = 1'b0;          // default signed compare
     ASel   = 1'b0;
     BSel   = 1'b0;
     ALUSel = ALU_ADD;
     MemRW  = 1'b0;
     MemSize = 2'b00;       // default byte (for LB/LBU)
     MemUnsigned = 1'b0;
     RegWEn = 1'b0;
     WBSel  = WB_ALU;
     rdSel  = ALU_RESULT;
   
     unique case (opcode)
     
      OC_PEXT: begin
        ASel   = 1'b0;
        BSel   = 1'b0;
        RegWEn = 1'b1;
        MemRW  = 1'b0;
        WBSel  = WB_ALU;
        rdSel  = ALUP_RESULT;

        unique case ({funct7, funct3})

            // ===== ADD =====
            10'b1000010_000: ALUSel = ALU_PADD_B;
            10'b1000000_000: ALUSel = ALU_PADD_H;

            // ===== SAT ADD =====
            10'b1001010_000: ALUSel = ALU_PSADD_B;
            10'b1001000_000: ALUSel = ALU_PSADD_H;

            10'b1011010_000: ALUSel = ALU_PSADDU_B;
            10'b1011000_000: ALUSel = ALU_PSADDU_H;

            // ===== AVG ADD =====
            10'b1001110_000: ALUSel = ALU_PAADD_B;
            10'b1001100_000: ALUSel = ALU_PAADD_H;

            10'b1011110_000: ALUSel = ALU_PAADDU_B;
            10'b1011100_000: ALUSel = ALU_PAADDU_H;

            // ===== SUB =====
            10'b1100010_000: ALUSel = ALU_PSUB_B;
            10'b1100000_000: ALUSel = ALU_PSUB_H;

            // ===== SAT SUB =====
            10'b1101010_000: ALUSel = ALU_PSSUB_B;
            10'b1101000_000: ALUSel = ALU_PSSUB_H;

            10'b1111010_000: ALUSel = ALU_PSSUBU_B;
            10'b1111000_000: ALUSel = ALU_PSSUBU_H;

            // ===== AVG SUB =====
            10'b1101110_000: ALUSel = ALU_PASUB_B;
            10'b1101100_000: ALUSel = ALU_PASUB_H;

            10'b1111110_000: ALUSel = ALU_PASUBU_B;
            10'b1111100_000: ALUSel = ALU_PASUBU_H;

            // ===== HX =====
            10'b1000000_110: ALUSel = ALU_PAS_HX;
            10'b1000010_110: ALUSel = ALU_PSA_HX;
            10'b1001000_110: ALUSel = ALU_PSAS_HX;
            10'b1001010_110: ALUSel = ALU_PSSA_HX;
            10'b1001100_110: ALUSel = ALU_PAAS_HX;
            10'b1001110_110: ALUSel = ALU_PASA_HX;

            // ===== MIN/MAX =====
            10'b1110000_110: ALUSel = ALU_PMIN_H;
            10'b1111000_110: ALUSel = ALU_PMAX_H;
            10'b1110100_110: ALUSel = ALU_PMINU_H;
            10'b1111100_110: ALUSel = ALU_PMAXU_H;

            // ===== COMPARE =====
            10'b1100000_110: ALUSel = ALU_PMSEQ_H;
            10'b1101000_110: ALUSel = ALU_PMSLT_H;
            10'b1101100_110: ALUSel = ALU_PMSLTU_H;

            // ===== MAC =====
            10'b1000100_111: ALUSel = ALU_PMHACC_H;

            default: ALUSel = ALU_ADD;
        endcase
       end 

       OC_PEXT_IMM: begin
          ASel   = 1'b0;
          RegWEn = 1'b1;
          MemRW  = 1'b0;
          WBSel  = WB_ALU;
          ImmSel = Imm_P;

          unique case (funct7)

              7'b1110000: begin
                unique case (funct3)
                  3'b100: begin ALUSel = ALU_PSATI_H; BSel = 1'b1; end // ===== PSATI =====
                  3'b010: begin ALUSel = ALU_PSABS_H; BSel = 1'b0; end // ===== PSABS =====
                endcase
              end

              7'b1010000: begin
                unique case (funct3)
                  3'b100: begin ALUSel = ALU_PUSATI_H; BSel = 1'b1; end //===== PUSATI =====
                endcase
              end
          endcase
       end

       // ===== R-type =====
       OC_R: begin
         //PCSel  = PC_PC4;
         ASel   = 1'b0;
         BSel   = 1'b0;
         RegWEn = 1'b1;
         MemRW  = 1'b0;
         WBSel  = WB_ALU;
	 /*
         unique case (funct3)
           F3_ADD_SUB : ALUSel = (funct7[5]) ? ALU_SUB : ALU_ADD;
           F3_SLL     : ALUSel = ALU_SLL;
           F3_SLT     : ALUSel = ALU_SLT;
           F3_SLTU    : ALUSel = ALU_SLTU;
           F3_XOR     : ALUSel = ALU_XOR;
           F3_SRL_SRA : ALUSel = (funct7[5]) ? ALU_SRA : ALU_SRL;
           F3_OR      : ALUSel = ALU_OR;
           F3_AND     : ALUSel = ALU_AND;
           default    : ALUSel = ALU_ADD; // safe default
         endcase
       end*/
unique case (funct7)

    // ================= RV32I =================
    7'b0000000: begin
        unique case (funct3)
            F3_ADD_SUB : ALUSel = ALU_ADD;
            F3_SLL     : ALUSel = ALU_SLL;
            F3_SLT     : ALUSel = ALU_SLT;
            F3_SLTU    : ALUSel = ALU_SLTU;
            F3_XOR     : ALUSel = ALU_XOR;
            F3_SRL_SRA : ALUSel = ALU_SRL;
            F3_OR      : ALUSel = ALU_OR;
            F3_AND     : ALUSel = ALU_AND;
        endcase
    end

    7'b0100000: begin
        unique case (funct3)
            F3_ADD_SUB : ALUSel = ALU_SUB;
            F3_SRL_SRA : ALUSel = ALU_SRA;
        endcase
    end

    // ================= RV32M =================
    7'b0000001: begin
        unique case (funct3)
            3'b000: ALUSel = ALU_MUL;
            3'b001: ALUSel = ALU_MULH;
            3'b010: ALUSel = ALU_MULHSU;
            3'b011: ALUSel = ALU_MULHU;
            3'b100: ALUSel = ALU_DIV;
            3'b101: ALUSel = ALU_DIVU;
            3'b110: ALUSel = ALU_REM;
            3'b111: ALUSel = ALU_REMU;
        endcase
    end

    endcase
end
   
       // ===== I-type ALU =====
       OC_I_ALU: begin
         //PCSel  = PC_PC4;
         ImmSel = Imm_I;
         ASel   = 1'b0;
         BSel   = 1'b1;
         RegWEn = 1'b1;
         MemRW  = 1'b0;
         WBSel  = WB_ALU;
         unique case (funct3)
           F3_ADDI      : ALUSel = ALU_ADD;
           F3_SLLI      : ALUSel = ALU_SLL;
           F3_SLTI      : ALUSel = ALU_SLT;
           F3_SLTIU     : ALUSel = ALU_SLTU;
           F3_XORI      : ALUSel = ALU_XOR;
           F3_SRLI_SRAI : ALUSel = (funct7[5]) ? ALU_SRA : ALU_SRL;
           F3_ORI       : ALUSel = ALU_OR;
           F3_ANDI      : ALUSel = ALU_AND;
           default      : ALUSel = ALU_ADD;
         endcase
       end
   
       // ===== I-type LOAD =====
       OC_I_LOAD: begin
         //PCSel  = PC_PC4;
         ImmSel = Imm_I;
         ASel   = 1'b0;
         BSel   = 1'b1;
         RegWEn = 1'b1;
         MemRW  = 1'b0;
         WBSel  = WB_MEM;
         ALUSel = ALU_ADD; // base + ofs
         unique case (funct3)
           F3_LB  : begin
             MemSize = 2'b00;
             MemUnsigned = 1'b0;
           end
           F3_LH  : begin
             MemSize = 2'b01;
             MemUnsigned = 1'b0;
           end
           F3_LW  : begin
             MemSize = 2'b10;
             MemUnsigned = 1'b0;
           end
           F3_LBU : begin
             MemSize = 2'b00;
             MemUnsigned = 1'b1;
           end
           F3_LHU : begin
             MemSize = 2'b01;
             MemUnsigned = 1'b1;
           end
           default: begin
              MemSize = 2'b00;
              MemUnsigned = 1'b0;
           end // safe default, though ideally should never happen
          endcase
       end
   
       // ===== S-type STORE =====
       OC_S: begin
         //PCSel  = PC_PC4;
         ImmSel = Imm_S;
         ASel   = 1'b0;
         BSel   = 1'b1;
         RegWEn = 1'b0;
         MemRW  = 1'b1;
         ALUSel = ALU_ADD; // base + ofs
         unique case (funct3)
           F3_SB : MemSize = 2'b00;
           F3_SH : MemSize = 2'b01;
           F3_SW : MemSize = 2'b10;
           default: begin 
              MemSize = 2'b00; // safe default
           end
         endcase
       end
   
       // ===== B-type BRANCH =====
       OC_B: begin
         ImmSel = Imm_B;
         ASel   = 1'b1;
         BSel   = 1'b1;    // để tính branch_target = PC + imm_B (nếu bạn tính ở ALU)
         ALUSel = ALU_ADD; // hoặc dùng adder riêng cho branch_target
         RegWEn = 1'b0;
         MemRW  = 1'b0;
         WBSel  = WB_ALU;  // don't care
         // branch decision -> PCSel
         unique case (funct3)
           //F3_BEQ  : PCSel =  BrEq      ? PC_ALU : PC_PC4;
           //F3_BNE  : PCSel = ~BrEq      ? PC_ALU : PC_PC4;
           //F3_BLT  : begin BrUn = 1'b0; PCSel =  BrLT      ? PC_ALU : PC_PC4; end
           //F3_BGE  : begin BrUn = 1'b0; PCSel = (~BrLT|BrEq)? PC_ALU : PC_PC4; end
           //F3_BLTU : begin BrUn = 1'b1; PCSel =  BrLT      ? PC_ALU : PC_PC4; end
           //F3_BGEU : begin BrUn = 1'b1; PCSel = (~BrLT|BrEq)? PC_ALU : PC_PC4; end

           F3_BLT  : BrUn = 1'b0; 
           F3_BGE  : BrUn = 1'b0; 
           F3_BLTU : BrUn = 1'b1; 
           F3_BGEU : BrUn = 1'b1; 
           default : BrUn = 1'b0;
         endcase
       end
   
       // ===== U-type LUI =====
       OC_U_LUI: begin
         //PCSel  = PC_PC4;
         ImmSel = Imm_U;
         ASel   = 1'b0;   // không dùng nhưng set cho chắc
         BSel   = 1'b1;   // dùng imm
         ALUSel = ALU_LUI; // alu = B = imm_U
         RegWEn = 1'b1;
         MemRW  = 1'b0;
         WBSel  = WB_ALU;
       end
   
       // ===== U-type AUIPC =====
       OC_U_AUIPC: begin
         //PCSel  = PC_PC4;
         ImmSel = Imm_U;
         ASel   = 1'b1;   // chọn PC vào A (đảm bảo datapath có đường PC->ALU)
         BSel   = 1'b1;   // imm_U
         ALUSel = ALU_ADD;
         RegWEn = 1'b1;
         MemRW  = 1'b0;
         WBSel  = WB_ALU;
       end
   
       // ===== J-type JAL =====
       OC_J: begin
         //PCSel  = PC_ALU; // PC := PC + imm_J
         ImmSel = Imm_J;
         ASel   = 1'b1;   // PC
         BSel   = 1'b1;   // imm_J
         ALUSel = ALU_ADD;
         RegWEn = 1'b1;
         MemRW  = 1'b0;
         WBSel  = WB_PC4; // rd := PC+4
       end
   
       // ===== I-type JALR =====
       OC_I_JALR: begin
         //PCSel  = PC_ALU; // PC := (rs1 + imm_I) & ~1  (clear bit0 ở PC-path)
         ImmSel = Imm_I;
         ASel   = 1'b0;   // rs1
         BSel   = 1'b1;   // imm_I
         ALUSel = ALU_JALR;
         RegWEn = 1'b1;
         MemRW  = 1'b0;
         WBSel  = WB_PC4; // rd := PC+4
       end
   
       default: begin
         //PCSel  = PC_PC4;   // cứ tiến bình thường
         ImmSel = Imm_I;    // không ảnh hưởng ImmGen
         BrUn   = 1'b0;
         ASel   = 1'b0;
         BSel   = 1'b0;
         ALUSel = ALU_ADD;  // giả sử cộng mặc định
         MemRW  = 1'b0;
         RegWEn = 1'b0;     // không ghi thanh ghi
         WBSel  = WB_ALU;   // không ghi gì cả
       end
       
     endcase
   end


endmodule
