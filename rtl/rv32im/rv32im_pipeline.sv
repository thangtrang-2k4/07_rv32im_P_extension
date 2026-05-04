// ================================================================
// RV32I + M-extension Pipeline CPU (datapath + control) - top level
// ================================================================
`timescale 1ns/1ps

module rv32im_pipeline #(
    parameter int DEPTH_WORDS = 16384  // 64KB (giảm từ 524288)
)(
    input  logic clk,
    input  logic rst_n
);

  import rv32_pkg::*;

  // =========================================================================
  // IF Stage
  // =========================================================================

  logic [31:0] pc_plus4;
  logic [31:0] pc_next;
  logic [31:0] pc;
  ctrl_t ctrl;
  logic [31:0] inst;

  // ------------------------------
  // MUX ALU / PC + 4
  // ------------------------------
  logic [31:0] pc_next_raw;
  logic PCSel;

  assign pc_next_raw = (PCSel) ? alu : pc_plus4;
  assign pc_next     = stall ? pc : pc_next_raw;

  // ------------------------------
  // Program Counter
  // ------------------------------
  Program_Counter u_pc (
    .clk    (clk),
    .rst_n  (rst_n),
    .pc_next(pc_next),
    .pc     (pc)
  );

  // ------------------------------
  // Adder PC + 4
  // ------------------------------
  Adder u_add1 (
    .a (pc),
    .b (32'd4),
    .c (pc_plus4)
  );

  // ------------------------------
  // Instruction Memory
  // ------------------------------
  IMem #(
    .DEPTH_WORDS(DEPTH_WORDS),
    .BASE_ADDR(32'h8000_0000)
  ) u_imem (
    .rst_n (rst_n),
    .addr  (pc),
    .inst  (inst)
  );

  // =========================================================================
  // IF/ID Pipeline Registers
  // =========================================================================

  logic [31:0] pc_ID, inst_ID;

  pipe_reg #(.W(32)) u_pc_ID (
    .clk(clk), .rst_n(rst_n), .en(!stall), .flush(PCSel),
    .d(pc), .bubble(32'b0), .q(pc_ID)
  );

  pipe_reg #(.W(32)) u_inst_ID (
    .clk(clk), .rst_n(rst_n), .en(!stall), .flush(PCSel),
    .d(inst), .bubble(32'h00000013), .q(inst_ID)  // NOP
  );

  // =========================================================================
  // ID Stage
  // =========================================================================

  // Decoder signals
  logic [6:0]  opcode_ID;
  logic [4:0]  rd_ID, rs1_ID, rs2_ID;
  funct3_t     funct3_ID;
  logic [6:0]  funct7_ID;
  logic [24:0] inst_imm_ID;
  logic [31:0] imm;

  // Register file signals
  logic [31:0] dataR1, dataR2;

  // Branch signals
  logic BrEq, BrLT;

  // ------------------------------
  // Decoder
  // ------------------------------
  Decoder u_decoder (
    .inst      (inst_ID),
    .opcode    (opcode_ID),
    .rd        (rd_ID),
    .funct3    (funct3_ID),
    .rs1       (rs1_ID),
    .rs2       (rs2_ID),
    .funct7    (funct7_ID),
    .inst_imm  (inst_imm_ID)
  );

  // ------------------------------
  // Control Logic
  // ------------------------------
  Control_Logic u_ctrl (
    .opcode     (opcode_t'(opcode_ID)),
    .funct3     (funct3_ID),
    .funct7     (funct7_ID),
    .ImmSel     (ctrl.ImmSel),
    .BrUn       (ctrl.BrUn),
    .ASel       (ctrl.ASel),
    .BSel       (ctrl.BSel),
    .ALUSel     (ctrl.ALUSel),
    .MemRW      (ctrl.MemRW),
    .MemUnsigned(ctrl.MemUnsigned),
    .MemSize    (ctrl.MemSize),
    .RegWEn     (ctrl.RegWEn),
    .WBSel      (ctrl.WBSel),
    .rdSel      (ctrl.rdSel)
  );

  // ------------------------------
  // Immediate Generator
  // ------------------------------
  ImmGen u_immgen (
    .inst_imm (inst_imm_ID),
    .ImmSel   (ctrl.ImmSel),
    .imm      (imm)
  );

  // ------------------------------
  // Register File (RV32IM version)
  // ------------------------------
  RegFile_IM #(.WRITE_THROUGH(1'b1)) u_regfile (
    .clk    (clk),
    .rst_n  (rst_n),
    .rsR1   (rs1_ID),
    .rsR2   (rs2_ID),
    .rsW    (rd_WB),
    .dataW  (WBdata),
    .RegWEn (ctrl_WB.RegWEn),
    .dataR1 (dataR1),
    .dataR2 (dataR2)
  );

  // =========================================================================
  // ID/EX Pipeline Registers
  // =========================================================================

  logic [6:0]  opcode_EX;
  logic [4:0]  rs1_EX, rs2_EX, rd_EX;
  funct3_t     funct3_EX;
  logic [31:0] pc_EX, dataR1_EX, dataR2_EX, imm_EX;
  ctrl_t       ctrl_EX;

  pipe_reg #(.W(7))  u_opcode_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(opcode_ID), .bubble(7'b0), .q(opcode_EX));
  pipe_reg #(.W(3))  u_funct3_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(funct3_ID), .bubble(3'b0), .q(funct3_EX));
  pipe_reg #(.W(5))  u_rd_EX     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(rd_ID),     .bubble(5'b0), .q(rd_EX));
  pipe_reg #(.W(5))  u_rs1_EX    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(rs1_ID),    .bubble(5'b0), .q(rs1_EX));
  pipe_reg #(.W(5))  u_rs2_EX    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(rs2_ID),    .bubble(5'b0), .q(rs2_EX));
  pipe_reg #(.W(32)) u_pc_EX     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall),         .d(pc_ID),     .bubble(32'b0), .q(pc_EX));
  pipe_reg #(.W(32)) u_dataR1_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall),         .d(dataR1),    .bubble(32'b0), .q(dataR1_EX));
  pipe_reg #(.W(32)) u_dataR2_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall),         .d(dataR2),    .bubble(32'b0), .q(dataR2_EX));
  pipe_reg #(.W(32)) u_imm_EX    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall),         .d(imm),       .bubble(32'b0), .q(imm_EX));
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(ctrl), .bubble(CTRL_NOP), .q(ctrl_EX));

  // =========================================================================
  // EX Stage
  // =========================================================================

  // Forwarding signals
  logic [1:0] forwardA, forwardB;
  logic [31:0] dataR1_fwd, dataR2_fwd;
  logic [31:0] A, B;

  // ALU signals
  logic [31:0] ResultALU, alu;

  // ------------------------------
  // Forwarding Control Logic (RV32IM version)
  // ------------------------------
  Forwarding_Unit_IM u_fwd_ctrl (
    .RegWEn_MEM (ctrl_MEM.RegWEn),
    .RegWEn_WB  (ctrl_WB.RegWEn),
    .MemRW_MEM  (ctrl_MEM.MemRW),
    .WBSel_MEM  (ctrl_MEM.WBSel),
    .rs1_EX     (rs1_EX),
    .rs2_EX     (rs2_EX),
    .rd_EX      (rd_EX),
    .rd_MEM     (rd_MEM),
    .rd_WB      (rd_WB),
    .forwardA   (forwardA),
    .forwardB   (forwardB)
  );

  // ------------------------------
  // Branch Comparator
  // ------------------------------
  Branch_Comparator #(.WIDTH(32)) u_branch_comp (
    .rs1  (dataR1_fwd),
    .rs2  (dataR2_fwd),
    .BrUn (ctrl_EX.BrUn),
    .BrEq (BrEq),
    .BrLT (BrLT)
  );

  // ------------------------------
  // MUX Forwarding A
  // ------------------------------
  always_comb begin
    unique case (forwardA)
      2'b10:   dataR1_fwd = alu_MEM;
      2'b01:   dataR1_fwd = WBdata;
      default: dataR1_fwd = dataR1_EX;
    endcase
  end
  assign A = (ctrl_EX.ASel) ? pc_EX : dataR1_fwd;

  // ------------------------------
  // MUX Forwarding B
  // ------------------------------
  always_comb begin
    unique case (forwardB)
      2'b10:   dataR2_fwd = alu_MEM;
      2'b01:   dataR2_fwd = WBdata;
      default: dataR2_fwd = dataR2_EX;
    endcase
  end
  assign B = (ctrl_EX.BSel) ? imm_EX : dataR2_fwd;

  // ------------------------------
  // ALU
  // ------------------------------
  ALU u_alu (
    .A      (A),
    .B      (B),
    .ALUSel (ctrl_EX.ALUSel),
    .result (ResultALU)
  );

  // ------------------------------
  // Branch Control
  // ------------------------------
  PC_Selection u_pc_sel (
    .opcode_EX (opcode_t'(opcode_EX)),
    .funct3_EX (funct3_EX),
    .BrEq      (BrEq),
    .BrLT      (BrLT),
    .PCSel     (PCSel)
  );

  // =========================================================================
  // EX/MEM Pipeline Registers
  // =========================================================================

  logic [31:0] pc_MEM, alu_MEM, dataR2_MEM;
  logic [4:0]  rd_MEM;
  ctrl_t       ctrl_MEM;

  pipe_reg #(.W(32)) u_pc_MEM     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(pc_EX),      .bubble(32'b0), .q(pc_MEM));
  pipe_reg #(.W(32)) u_alu_MEM    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(ResultALU),  .bubble(32'b0), .q(alu_MEM));
  pipe_reg #(.W(32)) u_dataR2_MEM (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(dataR2_fwd), .bubble(32'b0), .q(dataR2_MEM));
  pipe_reg #(.W(5))  u_rd_MEM     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(rd_EX),      .bubble(5'd0),  .q(rd_MEM));
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_MEM (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(ctrl_EX), .bubble(CTRL_NOP), .q(ctrl_MEM));

  // =========================================================================
  // MEM Stage
  // =========================================================================

  logic [31:0] mem;

  // ------------------------------
  // Data Memory
  // ------------------------------
  Data_Memory #(
    .DEPTH_WORDS(DEPTH_WORDS),
    .BASE_ADDR(32'h8001_0000)
  ) u_dmem (
    .clk        (clk),
    .rst_n      (rst_n),
    .addr       (alu_MEM),
    .dataW      (dataR2_MEM),
    .MemRW      (ctrl_MEM.MemRW),
    .MemSize    (ctrl_MEM.MemSize),
    .MemUnsigned(ctrl_MEM.MemUnsigned),
    .dataR      (mem)
  );

  // ------------------------------
  // Adder PC + 4 (for JAL)
  // ------------------------------
  logic [31:0] pc_plus4_mem;
  Adder u_add2 (
    .a (pc_MEM),
    .b (32'd4),
    .c (pc_plus4_mem)
  );

  // =========================================================================
  // MEM/WB Pipeline Registers
  // =========================================================================

  logic [31:0] pc_plus4_mem_WB, alu_WB, mem_WB;
  logic [4:0]  rd_WB;
  ctrl_t       ctrl_WB;

  pipe_reg #(.W(32)) u_pc4_WB (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(pc_plus4_mem), .bubble(32'b0), .q(pc_plus4_mem_WB));
  pipe_reg #(.W(32)) u_alu_WB (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(alu_MEM),      .bubble(32'b0), .q(alu_WB));
  pipe_reg #(.W(32)) u_mem_WB (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(mem),          .bubble(32'b0), .q(mem_WB));
  pipe_reg #(.W(5))  u_rd_WB  (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(rd_MEM),       .bubble(5'd0),  .q(rd_WB));
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_WB (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(ctrl_MEM), .bubble(CTRL_NOP), .q(ctrl_WB));

  // =========================================================================
  // WB Stage
  // =========================================================================

  logic [31:0] WBdata;

  // ------------------------------
  // Write-Back MUX
  // ------------------------------
  always_comb begin
    unique case (ctrl_WB.WBSel)
      WB_MEM:  WBdata = mem_WB;
      WB_ALU:  WBdata = alu_WB;
      WB_PC4:  WBdata = pc_plus4_mem_WB;
      default: WBdata = 32'h0;
    endcase
  end

  // =========================================================================
  // Hazard Detection (RV32IM version)
  // =========================================================================

  logic stall;

  Hazard_Detection_IM u_hazard (
    .MemRW_MEM (ctrl_MEM.MemRW),
    .rs1_ID    (rs1_ID),
    .rs2_ID    (rs2_ID),
    .rd_EX     (rd_EX),
    .stall     (stall)
  );

endmodule
