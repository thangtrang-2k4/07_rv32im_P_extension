// ================================================================
// Branch_Control.sv
// Quyết định nhảy (taken) và tính địa chỉ đích (target)
// ================================================================
module pc_selection (
  input  rv32_pkg::opcode_t  opcode_EX,
  input  rv32_pkg::funct3_t  funct3_EX,
  input  logic               BrEq,
  input  logic               BrLT,
  output logic               PCSel
);
  import rv32_pkg::*;

  always_comb begin
    PCSel  = 1'b0;

    unique case (opcode_EX)
      OC_B: begin
        unique case (funct3_EX)
          //F3_BEQ : PCSel =  BrEq;
          //F3_BNE : PCSel = ~BrEq;
          //F3_BLT : PCSel =  BrLT;
          //F3_BGE : PCSel = (~BrLT) | BrEq;
          //F3_BLTU: PCSel =  BrLT;
          //F3_BGEU: PCSel = (~BrLT) | BrEq;
          F3_BEQ  : PCSel =  BrEq      ? 1'b1 : 1'b0;
          F3_BNE  : PCSel = ~BrEq      ? 1'b1 : 1'b0;
          F3_BLT  : PCSel =  BrLT      ? 1'b1 : 1'b0;
          F3_BGE  : PCSel = (~BrLT|BrEq)? 1'b1 : 1'b0;
          F3_BLTU : PCSel =  BrLT      ? 1'b1 : 1'b0;
          F3_BGEU : PCSel = (~BrLT|BrEq)? 1'b1 : 1'b0;
          default: PCSel  = 1'b0;
        endcase
      end

      OC_J: begin
        PCSel  = 1'b1;        
      end

      OC_I_JALR: begin
        PCSel  = 1'b1;
      end

      default: PCSel  = 1'b0;
    endcase
  end
endmodule
