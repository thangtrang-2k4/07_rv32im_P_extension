module ImmGen (
               input  logic [24:0] inst_imm,
               input  rv32_pkg::ImmSel_t ImmSel,
               output logic [31:0] imm
              );
   import rv32_pkg::*;

   always_comb begin
      case(ImmSel)
         Imm_I : imm = { {20{inst_imm[24]}}, inst_imm[24:13] };
         Imm_S : imm = { {20{inst_imm[24]}}, inst_imm[24:18], inst_imm[4:0] };
         Imm_B : imm = { {19{inst_imm[24]}}, inst_imm[24], inst_imm[0], inst_imm[23:18], inst_imm[4:1], 1'b0 };
         Imm_U : imm = { inst_imm[24:5], 12'b0 };
         Imm_J : imm = { {11{inst_imm[24]}}, inst_imm[24], inst_imm[12:5], inst_imm[13], inst_imm[23:14], 1'b0 };
         default: imm = 32'b0;
      endcase
   end
endmodule
