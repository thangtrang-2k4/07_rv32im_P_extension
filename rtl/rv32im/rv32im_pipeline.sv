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
  input  logic rst_n,
  output logic [31:0] o_obs_data
);

  import rv32_pkg::*;
  
  // ── Stall signals ──
  logic load_use_stall;   // from Hazard_Detection
  logic mem_stall;         // from DMemCtrl
  wire pipe_accept = !load_use_stall && !mem_stall;

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
  logic [31:0] alu;

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


  /////////////////////////////
  // EX
  ////////////////////////////

  // rd_WB
  logic [4:0] rd_WB;

  logic [31:0] pc_plus4_mem_WB, alu_WB;

  // Control sang WB
  ctrl_t ctrl_WB;

  // IF

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

  // ── IFetchCtrl ──
  logic        inst_valid, pc_en;
  logic [31:0] fetched_inst, fetched_pc;
  logic        imem_stb, imem_ack;
  logic [31:0] imem_addr, imem_inst;

  IFetchCtrl u_ifetch (
      .clk            (clk),
      .rst_n          (rst_n),
      .i_pc           (pc),
      .i_pc_redirect  (PCSel),
      .i_pipe_accept  (pipe_accept),
      .o_imem_stb     (imem_stb),
      .o_imem_addr    (imem_addr),
      .i_imem_ack     (imem_ack),
      .i_imem_inst    (imem_inst),
      .o_inst_valid   (inst_valid),
      .o_inst         (fetched_inst),
      .o_pc_req       (fetched_pc),
      .o_pc_en        (pc_en)
  );

  // ------------------------------
  // Instruction memory 
  // ------------------------------
  IMem #(
    .DEPTH_WORDS(DEPTH_WORDS),
    .BASE_ADDR(32'h8000_0000)
  )u_imem (
    .clk    (clk),
    .rst_n  (rst_n),
    .i_stb  (imem_stb),
    .i_addr (imem_addr),
    .o_ack  (imem_ack),
    .o_inst (imem_inst)
  );

  // ------------------------------
  // MUX ALU / PC + 4
  // ------------------------------
  always_comb begin
      if (PCSel)
          pc_next = alu;           // branch/jump redirect
      else if (pc_en)
          pc_next = pc_plus4;      // stb issued → advance
      else
          pc_next = pc;            // hold
  end

  // ---------- IF/ID pipeline registers ----------
  // PC_ID, inst_ID
  logic [31:0] pc_ID, inst_ID;

  wire if_id_en    = inst_valid && pipe_accept;
  wire if_id_flush = PCSel;

  pipe_reg #(.W(32)) u_pc_ID (
    .clk(clk), .rst_n(rst_n), .en(if_id_en), .flush(if_id_flush),
    .d(fetched_pc), .bubble(32'b0), .q(pc_ID)
  );

  pipe_reg #(.W(32)) u_inst_ID (
    .clk(clk), .rst_n(rst_n), .en(if_id_en), .flush(if_id_flush),
    .d(fetched_inst), .bubble(32'h00000013), // NOP = ADDI x0,x0,0
    .q(inst_ID)
  );

  logic if_id_valid;

  always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n)
          if_id_valid <= 1'b0;
      else if (PCSel)
          if_id_valid <= 1'b0;                        // branch flush
      else if (mem_stall)
          if_id_valid <= if_id_valid;                  // hold
      else if (if_id_en)
          if_id_valid <= 1'b1;                         // new instruction loaded
      else if (!load_use_stall)
          if_id_valid <= 1'b0;                         // consumed by ID/EX
  end

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
      .MemUnsigned (ctrl.MemUnsigned),
      .MemSize     (ctrl.MemSize),
      .RegWEn      (ctrl.RegWEn),
      .WBSel       (ctrl.WBSel)
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
  wire id_ex_en    = !mem_stall;
  wire id_ex_flush = (!if_id_valid || load_use_stall || PCSel) && !mem_stall;

  // Decoder -> EX
  pipe_reg #(.W(7)) u_opcode_EX (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(opcode_ID),   .bubble(7'b0),          .q(opcode_EX));
  pipe_reg #(.W(3)) u_funct3_EX (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(funct3_ID),   .bubble(3'b0),          .q(funct3_EX));
  pipe_reg #(.W(5)) u_rd_EX     (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(rd_ID),       .bubble(5'b0),          .q(rd_EX));
  pipe_reg #(.W(5)) u_rs1_EX    (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(rs1_ID),      .bubble(5'b0),          .q(rs1_EX));
  pipe_reg #(.W(5)) u_rs2_EX    (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(rs2_ID),      .bubble(5'b0),          .q(rs2_EX));

  pipe_reg #(.W(32)) u_pc_EX     (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(pc_ID),        .bubble(32'b0),         .q(pc_EX));
  pipe_reg #(.W(32)) u_dataR1_EX (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(dataR1),  .bubble(32'b0),         .q(dataR1_EX));
  pipe_reg #(.W(32)) u_dataR2_EX (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(dataR2),  .bubble(32'b0),         .q(dataR2_EX));
  pipe_reg #(.W(32)) u_imm_EX    (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(imm),       .bubble(32'b0),         .q(imm_EX));

  // control -> EX
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_EX   (.clk(clk), .rst_n(rst_n), .en(id_ex_en), .flush(id_ex_flush), .d(ctrl),      .bubble(CTRL_NOP),  .q(ctrl_EX));
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
    .alu    (alu)
  );

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
  wire ex_mem_en    = !mem_stall;
  wire ex_mem_flush = 1'b0;          // NEVER flush — JAL/JALR need writeback

  pipe_reg #(.W(32)) u_pc_MEM     (.clk(clk), .rst_n(rst_n), .en(ex_mem_en), .flush(ex_mem_flush), .d(pc_EX),      .bubble(32'b0), .q(pc_MEM));
  pipe_reg #(.W(32)) u_alu_MEM    (.clk(clk), .rst_n(rst_n), .en(ex_mem_en), .flush(ex_mem_flush), .d(alu),        .bubble(32'b0), .q(alu_MEM));
  pipe_reg #(.W(32)) u_dataR2_MEM (.clk(clk), .rst_n(rst_n), .en(ex_mem_en), .flush(ex_mem_flush), .d(dataR2_fwd), .bubble(32'b0), .q(dataR2_MEM));
  pipe_reg #(.W(5))  u_rd_MEM     (.clk(clk), .rst_n(rst_n), .en(ex_mem_en), .flush(ex_mem_flush), .d(rd_EX),      .bubble(5'd0),  .q(rd_MEM));

  // Control
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_MEM   (.clk(clk), .rst_n(rst_n), .en(ex_mem_en), .flush(ex_mem_flush), .d(ctrl_EX),      .bubble(CTRL_NOP),  .q(ctrl_MEM));
  // MEM

  logic        dmem_stb, dmem_ack;
  logic [31:0] dmem_rdata, dmem_rdata_out;
  logic        dmem_we;
  logic [31:0] dmem_addr, dmem_wdata;
  logic [1:0]  dmem_size;
  logic        dmem_unsigned;

  DMemCtrl u_dmem_ctrl (
      .clk            (clk),
      .rst_n          (rst_n),
      .i_is_load      (ctrl_MEM.WBSel == WB_MEM),
      .i_is_store     (ctrl_MEM.MemRW),
      .i_addr         (alu_MEM),
      .i_wdata        (dataR2_MEM),
      .i_size         (ctrl_MEM.MemSize),
      .i_unsigned     (ctrl_MEM.MemUnsigned),
      .o_dmem_stb     (dmem_stb),
      .o_dmem_we      (dmem_we),
      .o_dmem_addr    (dmem_addr),
      .o_dmem_wdata   (dmem_wdata),
      .o_dmem_size    (dmem_size),
      .o_dmem_unsigned(dmem_unsigned),
      .i_dmem_ack     (dmem_ack),
      .i_dmem_rdata   (dmem_rdata),
      .o_mem_stall    (mem_stall),
      .o_rdata        (dmem_rdata_out)
  );

  // ------------------------------
  // Data Memory (LW/SW 32-bit)
  // ------------------------------
  Data_Memory #(
    .DEPTH_WORDS(DEPTH_WORDS),
    .BASE_ADDR(32'h8001_0000)
  ) u_dmem (
      .clk         (clk),
      .rst_n       (rst_n),
      .i_stb       (dmem_stb),
      .i_we        (dmem_we),
      .i_addr      (dmem_addr),
      .i_wdata     (dmem_wdata),
      .i_size      (dmem_size),
      .i_unsigned  (dmem_unsigned),
      .o_ack       (dmem_ack),
      .o_rdata     (dmem_rdata)
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

  logic [31:0] mem_WB;
  wire mem_wb_en = !mem_stall;

  pipe_reg #(.W(32)) u_pc4_WB  (.clk(clk), .rst_n(rst_n), .en(mem_wb_en), .flush(1'b0), .d(pc_plus4_mem), .bubble(32'b0), .q(pc_plus4_mem_WB));
  pipe_reg #(.W(32)) u_alu_WB  (.clk(clk), .rst_n(rst_n), .en(mem_wb_en), .flush(1'b0), .d(alu_MEM),      .bubble(32'b0), .q(alu_WB));
  pipe_reg #(.W(32)) u_mem_WB  (.clk(clk), .rst_n(rst_n), .en(mem_wb_en), .flush(1'b0), .d(dmem_rdata_out),.bubble(32'b0), .q(mem_WB));
  pipe_reg #(.W(5))  u_rd_WB   (.clk(clk), .rst_n(rst_n), .en(mem_wb_en), .flush(1'b0), .d(rd_MEM),       .bubble(5'd0),  .q(rd_WB));
  // Control
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_WB   (.clk(clk), .rst_n(rst_n), .en(mem_wb_en), .flush(1'b0), .d(ctrl_MEM),      .bubble(CTRL_NOP),  .q(ctrl_WB));
  
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
    .stall(load_use_stall)
  );

  assign o_obs_data = pc ^ alu_MEM ^ dmem_rdata_out ^ WBdata;

endmodule
