// ================================================================
// RV32I Pipline CPU (datapath + control) - top level
// 
// 
// 
// 
// ================================================================
`timescale 1ns/1ps
module rv32im_pipeline #(
    parameter int DEPTH_WORDS = 524288  // 1MB
)(
  input  logic clk,
  input  logic rst_n
  
  //input  logic [7:0] sw,
  //output logic [7:0] led

  // single_cycle.sv: khai báo port
  //output logic [31:0] a0_out
  //output logic [31:0] debug_pc
);

  import rv32_pkg::*;
  
  /////////////////////////////
  // IF
  /////////////////////////////

  // Adder
  logic [31:0] pc_plus4;

  // MUX ALU / PC + 4
  logic [31:0] pc_next;

  // Program Counter
  logic [31:0] pc;
  
  // Control Logic       
  ctrl_t ctrl;

  // Instruction Memory
  logic [31:0] inst;
  
  /////////////////////////////
  // ID
  /////////////////////////////

  // Decoder
  logic [6:0]  opcode_ID;
  logic [4:0]  rd_ID;
  funct3_t     funct3_ID;
  logic [4:0]  rs1_ID;
  logic [4:0]  rs2_ID;
  logic [6:0]  funct7_ID; 
  logic [24:0] inst_imm_ID;

  // Immediate Generator
  logic [31:0] imm;
  
  // Register File
  logic [31:0] dataR1, dataR2;

  // Branch Comparator
  logic BrEq, BrLT;

  // Branch Control
  logic PCSel;

  /////////////////////////////
  // EX
  /////////////////////////////

  // Decoder -> EX
  logic [6:0] opcode_EX;
  logic [4:0] rs1_EX, rs2_EX;
  logic [4:0] rd_EX;
  funct3_t funct3_EX;

  // PC_EX, rs1_EX, rs2_EX, imm_EX, rd_EX, inst_EX
  logic [31:0] pc_EX, dataR1_EX, dataR2_EX, imm_EX;

  // giữ control tới EX
  ctrl_t ctrl_EX;

  // Forwarding Control Logic
  logic [1:0] forwardA, forwardB;

  // MUX Forwarding 
  logic [31:0] dataR1_fwd, dataR2_fwd;

  // MUX A / B
  logic [31:0] A, B;

  // ALU
  logic [31:0] ResultALU, ResultALUP, alu;

  /////////////////////////////
  // EX
  /////////////////////////////

  // rd_MEM
  logic [4:0] rd_MEM;

  // PC4_MEM, alu_MEM, rs2_MEM + branch info cho MEM
  logic [31:0] pc_MEM, alu_MEM, dataR2_MEM;

  // Control sang MEM
  ctrl_t ctrl_MEM;

  // Data Memory
  logic [31:0] mem;

  // MUX Write Back
  logic [31:0] WBdata;

  // Hazards Detect
  logic stall;

  /////////////////////////////
  // EX
  ////////////////////////////

  // rd_WB
  logic [4:0] rd_WB;

  // PC4_WB, alu_WB, mem_WB + control tới WB
  logic [31:0] pc_plus4_mem_WB, alu_WB, mem_WB;

  // Control sang WB
  ctrl_t ctrl_WB;



  // IF

  // ------------------------------
  // MUX ALU / PC + 4
  // ------------------------------
  //assign pc_next = (ctrl.PCSel == PC_PC4) ? pc_plus4 : alu;

  logic [31:0] pc_next_raw;
  
  assign pc_next_raw   = (PCSel ) ? alu : pc_plus4;
  assign pc_next = stall ? pc : pc_next_raw;

  //assign debug_pc = pc;

  // ------------------------------
  // Program Counter
  // ------------------------------
  Program_Counter u_pc (
    .clk    (clk),
    .rst_n  (rst_n),
    .pc_next(pc_next),
    .pc   (pc)
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
  // Instruction memory 
  // ------------------------------
  IMem #(
    .DEPTH_WORDS(DEPTH_WORDS),
    .BASE_ADDR(32'h8000_0000)   // 🔥 thêm dòng này
  )u_imem (
    .rst_n (rst_n),
    .addr  (pc),
    .inst  (inst)
  );

  // ---------- IF/ID pipeline registers ----------
  // PC_ID, inst_ID
  logic [31:0] pc_ID, inst_ID;

  // baseline: luôn en=1, flush=0 (chưa có stall/flush)
  pipe_reg #(.W(32)) u_pc_ID (
    .clk(clk), .rst_n(rst_n), .en(!stall), .flush(PCSel),
    .d(pc), .bubble(32'b0), .q(pc_ID)
  );

  pipe_reg #(.W(32)) u_inst_ID (
    .clk(clk), .rst_n(rst_n), .en(!stall), .flush(PCSel),
    .d(inst), .bubble(32'h00000013), // NOP = ADDI x0,x0,0
    .q(inst_ID)
  );

  // ID

  // ------------------------------
  // Decoder
  // ------------------------------
  Decoder u_decoder (
    .inst   (inst_ID),
    .opcode  (opcode_ID),
    .rd      (rd_ID),
    .funct3  (funct3_ID),
    .rs1     (rs1_ID),
    .rs2     (rs2_ID),
    .funct7  (funct7_ID),
    .inst_imm(inst_imm_ID)
  );

  // ------------------------------
  // Control Logic
  // ------------------------------
  Control_Logic u_ctrl (
      .opcode (opcode_t'(opcode_ID)),
      .funct3 (funct3_ID),
      .funct7 (funct7_ID),
  
      .ImmSel      (ctrl.ImmSel),
      .BrUn        (ctrl.BrUn),
      .ASel        (ctrl.ASel),
      .BSel        (ctrl.BSel),
      .ALUSel      (ctrl.ALUSel),
      .MemRW       (ctrl.MemRW),
      .MemUnsigned (ctrl.MemUnsigned),   // THÊM
      .MemSize     (ctrl.MemSize),       // THÊM
      .RegWEn      (ctrl.RegWEn),
      .WBSel       (ctrl.WBSel),
      .rdSel       (ctrl.rdSel)
  );

  // ------------------------------
  // Immediate Generator
  // ------------------------------
  ImmGen u_immgen (
    .inst_imm   (inst_imm_ID),
    .ImmSel (ctrl.ImmSel),
    .imm    (imm)
  );

  // ------------------------------
  // Register File
  // ------------------------------
  RegFile #(.WRITE_THROUGH(1'b1)) u_regfile (
    .clk   (clk),
    .rst_n (rst_n),
    .rsR1  (rs1_ID),
    .rsR2  (rs2_ID),
    .rsW   (rd_WB),
    .dataW (WBdata),
    .RegWEn(ctrl_WB.RegWEn),
    .dataR1(dataR1),
    .dataR2(dataR2)
  );

  // ---------- ID/EX pipeline registers ----------

  // Decoder -> EX
  pipe_reg #(.W(7)) u_opcode_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(opcode_ID),   .bubble(7'b0),          .q(opcode_EX));
  pipe_reg #(.W(3)) u_funct3_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(funct3_ID),   .bubble(3'b0),          .q(funct3_EX));
  pipe_reg #(.W(5)) u_rd_EX     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(rd_ID),       .bubble(5'b0),          .q(rd_EX));
  pipe_reg #(.W(5)) u_rs1_EX    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(rs1_ID),      .bubble(5'b0),          .q(rs1_EX));
  pipe_reg #(.W(5)) u_rs2_EX    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(rs2_ID),      .bubble(5'b0),          .q(rs2_EX));

  // baseline: en=1, flush=0
  pipe_reg #(.W(32)) u_pc_EX     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(pc_ID),        .bubble(32'b0),         .q(pc_EX));
  pipe_reg #(.W(32)) u_dataR1_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(dataR1),  .bubble(32'b0),         .q(dataR1_EX));
  pipe_reg #(.W(32)) u_dataR2_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(dataR2),  .bubble(32'b0),         .q(dataR2_EX));
  pipe_reg #(.W(32)) u_imm_EX    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(imm),       .bubble(32'b0),         .q(imm_EX));

  // control -> EX
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_EX   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(ctrl),      .bubble(CTRL_NOP),  .q(ctrl_EX));
  // EX

  // ------------------------------
  // Forwarding Control Logic
  // ------------------------------
  Forwarding_Unit u_fwd_ctrl (
    .RegWEn_MEM(ctrl_MEM.RegWEn),
    .RegWEn_WB(ctrl_WB.RegWEn),
    .MemRW_MEM(ctrl_MEM.MemRW),
    .WBSel_MEM(ctrl_MEM.WBSel),
    .rs1_EX(rs1_EX),
    .rs2_EX(rs2_EX),
    .rd_MEM(rd_MEM),
    .rd_WB(rd_WB),
    .forwardA(forwardA),
    .forwardB(forwardB)
  );
  // ------------------------------
  // Branch Comparator
  // ------------------------------
  Branch_Comparator #(.WIDTH(32)) u_branch_comp (
    .rs1 (dataR1_fwd),
    .rs2 (dataR2_fwd),
    .BrUn(ctrl_EX.BrUn),
    .BrEq(BrEq),
    .BrLT(BrLT)
  );


  // ------------------------------
  // MUX A/B
  // ------------------------------
  always_comb begin
    unique case (forwardA)  // 00 RF, 10 EX/MEM, 01 MEM/WB
      2'b10: dataR1_fwd = alu_MEM;
      2'b01: dataR1_fwd = WBdata;
      default: dataR1_fwd = dataR1_EX;
    endcase
  end
  // ASel MUX: 0 -> rs1; 1 -> PC
  assign A = (ctrl_EX.ASel) ? pc_EX : dataR1_fwd;

  
  always_comb begin
    unique case (forwardB)
      2'b10: dataR2_fwd = alu_MEM;
      2'b01: dataR2_fwd = WBdata;
      default: dataR2_fwd = dataR2_EX;
    endcase
  end
  // BSel MUX: 0 -> rs2; 1 -> imm
  assign B = (ctrl_EX.BSel) ? imm_EX : dataR2_fwd;

  // ------------------------------
  // ALU
  // ------------------------------
  ALU u_alu (
    .A      (A),
    .B      (B),
    .ALUSel (ctrl_EX.ALUSel),
    .result    (ResultALU)
  );

  // ------------------------------
  // ALUP
  // ------------------------------
  ALUP u_alup (
    .A      (A),
    .B      (B),
    .ALUSel (ctrl_EX.ALUSel),
    .result    (ResultALUP)
  );
  
  always_comb begin
    unique case (ctrl_EX.rdSel)
      ALU_RESULT: alu = ResultALU;
      ALUP_RESULT: alu = ResultALUP;
      default: alu = 32'h0;
    endcase
  end
  // ------------------------------
  // Branch Control
  // ------------------------------
  PC_Selection u_pc_sel (
    .opcode_EX(opcode_t'(opcode_EX)),
    .funct3_EX(funct3_EX),
    .BrEq(BrEq),
    .BrLT(BrLT),
    .PCSel(PCSel)
  );

  // ---------- EX/MEM pipeline registers ----------


  pipe_reg #(.W(32)) u_pc_MEM     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(pc_EX),      .bubble(32'b0), .q(pc_MEM));
  pipe_reg #(.W(32)) u_alu_MEM    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(alu),        .bubble(32'b0), .q(alu_MEM));
  pipe_reg #(.W(32)) u_dataR2_MEM (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(dataR2_fwd), .bubble(32'b0), .q(dataR2_MEM));
  pipe_reg #(.W(5))  u_rd_MEM     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(rd_EX),      .bubble(5'd0),  .q(rd_MEM));

  // Control
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_MEM   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(ctrl_EX),      .bubble(CTRL_NOP),  .q(ctrl_MEM));
  // MEM

  // ------------------------------
  // Data Memory (LW/SW 32-bit)
  // ------------------------------
  Data_Memory #(
    .DEPTH_WORDS(DEPTH_WORDS),
    .BASE_ADDR(32'h8000_0000)   // 🔥 thêm dòng này
  ) u_dmem (
    .clk   (clk),
    .rst_n (rst_n),
    .addr  (alu_MEM),        // address từ ALU
    .dataW (dataR2_MEM),     // store dữ liệu từ rs2
    .MemRW (ctrl_MEM.MemRW),      // 1: write, 0: read
    .MemSize(ctrl_MEM.MemSize),
    .MemUnsigned(ctrl_MEM.MemUnsigned),
    .dataR (mem)  // read data
	 
	//.sw    (sw),
    //.led   (led)
  );

  // ------------------------------
  // Adder PC + 4
  // ------------------------------
  logic [31:0] pc_plus4_mem;
  Adder u_add2 (
    .a (pc_MEM),
    .b (32'd4),
    .c (pc_plus4_mem)
  );

  // ---------- MEM/WB pipeline registers ----------


  pipe_reg #(.W(32)) u_pc4_WB  (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(pc_plus4_mem), .bubble(32'b0), .q(pc_plus4_mem_WB));
  pipe_reg #(.W(32)) u_alu_WB  (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(alu_MEM),      .bubble(32'b0), .q(alu_WB));
  pipe_reg #(.W(32)) u_mem_WB  (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(mem),          .bubble(32'b0), .q(mem_WB));
  pipe_reg #(.W(5))  u_rd_WB   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(rd_MEM),       .bubble(5'd0),  .q(rd_WB));
  // Control
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_WB   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(ctrl_MEM),      .bubble(CTRL_NOP),  .q(ctrl_WB));
  // ------------------------------
  // Write-Back MUX
  // WBSel: 00->MEM, 01->ALU, 10->PC+4
  // ------------------------------
  always_comb begin
    unique case (ctrl_WB.WBSel)
      WB_MEM: WBdata = mem_WB;
      WB_ALU: WBdata = alu_WB;
      WB_PC4: WBdata = pc_plus4_mem_WB;
      default: WBdata = 32'h0;
    endcase
  end

  // ------------------------------
  // Hazards Detect
  // ------------------------------
  Hazard_Detection u_hazard (
    .opcode_ID(opcode_t'(opcode_ID)),
    .rs1_ID(rs1_ID),
    .rs2_ID(rs2_ID),
    .opcode_EX(opcode_t'(opcode_EX)),
    .rd_EX(rd_EX),
    .stall(stall)
  );


//  // Mirror a0 (x10) mỗi khi ghi WB vào x10
//  always_ff @(posedge clk or negedge rst_n) begin
//    if (!rst_n) a0_out <= 32'd0;
//    else if (RegWEn && (inst[11:7] == 5'd10))  // rd == x10
//      a0_out <= WBdata;
//  end

// ================================================================
// FULL PIPELINE DEBUG
// ================================================================
//always_ff @(posedge clk) begin
//  if (rst_n) begin
//    $display("--------------------------------------------------");
//    $display("PC_IF  = %h  INST_IF = %h", pc, inst);
//    $display("PC_ID  = %h  OPCODE_ID = %h", pc_ID, opcode_ID);
//    $display("PC_EX  = %h  ALU = %h  BrEq=%b BrLT=%b PCSel=%b",
//              pc_EX, alu, BrEq, BrLT, PCSel);
//    $display("PC_MEM = %h  MemRW=%b  ADDR=%h  DATAW=%h",
//              pc_MEM, ctrl_MEM.MemRW, alu_MEM, dataR2_MEM);
//    $display("PC_WB  = %h  RD=%0d  WBdata=%h  RegWEn=%b",
//              pc_plus4_mem_WB, rd_WB, WBdata, ctrl_WB.RegWEn);
//    $display("STALL=%b", stall);
//  end
//end
endmodule
