module Hazard_Detection (
  input  rv32_pkg::opcode_t opcode_ID,   // instruction ở ID
  input  logic [19:15]      rs1_ID,    // rs1 của instruction ở ID
  input  logic [24:20]      rs2_ID,    // rs2 của

  input  rv32_pkg::opcode_t opcode_EX,   // instruction ở EX
  input  logic [11:7]       rd_EX,    // rd của instruction ở EX
  output logic        stall
);
  import rv32_pkg::*;

  logic use_rs1_ID, use_rs2_ID;
  always_comb begin
    unique case (opcode_ID)
      OC_R      : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // R-type
      OC_S      : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // STORE
      OC_B      : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // BRANCH

      OC_I_ALU  : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b0; end // I-ALU
      OC_I_LOAD : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b0; end // LOAD (base rs1)
      OC_I_JALR : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b0; end // JALR

      OC_U_LUI  : begin use_rs1_ID = 1'b0; use_rs2_ID = 1'b0; end // LUI
      OC_U_AUIPC: begin use_rs1_ID = 1'b0; use_rs2_ID = 1'b0; end // AUIPC
      OC_J      : begin use_rs1_ID = 1'b0; use_rs2_ID = 1'b0; end // JAL

      default   : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // bảo thủ
    endcase
  end

  // ---- Điều kiện stall load-use chuẩn ----
  // Chỉ khi: EX là LOAD & rd_EX != x0 & ID thực sự đọc rs đụng rd_EX
  assign stall = (opcode_EX == OC_I_LOAD) &&
                 (rd_EX != 5'd0) &&
                 ( (use_rs1_ID && (rd_EX == rs1_ID)) ||
                   (use_rs2_ID && (rd_EX == rs2_ID)) );

endmodule
