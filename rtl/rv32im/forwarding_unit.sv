module Forwarding_Unit (
  input  logic             RegWEn_MEM,
  input  logic             RegWEn_WB,
  input  logic             MemRW_MEM,         // 1=store, 0=read (theo định nghĩa của bạn)
  input  rv32_pkg::WBSel_t WBSel_MEM,    // enum WB_MEM/WB_ALU/WB_PC4...
  input  logic [19:15]     rs1_EX,    // rs1 của instruction ở EX
  input  logic [24:20]     rs2_EX,    // rs2 của instruction
  input  logic [11:7]      rd_MEM,
  input  logic [11:7]      rd_WB,
  output logic [1:0]       forwardA,
  output logic [1:0]       forwardB
);
  import rv32_pkg::*;

  // Cho phép lấy từ EX/MEM CHỈ khi kết quả ghi về là từ ALU
  logic allow_exmem_fwd;
  assign allow_exmem_fwd = RegWEn_MEM && (WBSel_MEM == WB_ALU);
  
  always_comb begin
    forwardA = 2'b00;
    forwardB = 2'b00;
    // A
    if (allow_exmem_fwd && (rd_MEM!=5'd0) && (rd_MEM==rs1_EX))
      forwardA = 2'b10;                    // ALU result @EX/MEM
    else if (RegWEn_WB && (rd_WB!=5'd0) && (rd_WB==rs1_EX))
      forwardA = 2'b01;                    // LOAD/JAL/JALR/ALU @MEM/WB
    else
      forwardA = 2'b00;
  
    // B
    if (allow_exmem_fwd && (rd_MEM!=5'd0) && (rd_MEM==rs2_EX))
      forwardB = 2'b10;
    else if (RegWEn_WB && (rd_WB!=5'd0) && (rd_WB==rs2_EX))
      forwardB = 2'b01;
    else
      forwardB = 2'b00;
  end
endmodule
