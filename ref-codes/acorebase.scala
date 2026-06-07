// SPDX-License-Identifier: Apache-2.0

// Chisel module ACoreBase
// Inititally written by Verneri Hirvonen (verneri.hirvonen@aalto.fi), 2020-12-28
package acorebase

import chisel3._
import chisel3.util._
import chisel3.experimental._
import chisel3.experimental.BundleLiterals._
import chisel3.stage.{ChiselStage, ChiselGeneratorAnnotation}
import a_core_common._
import amba.axi4l._
import amba.common._
import BusType._

/** ACoreBase IO
  * @param XLEN
  *   Xlen from base integer ISA.
  * @param enable_debug
  *   Generate debug outputs
  * @param enable_rvfi
  *   Enable RISC-V formal verification interface
  */
case class ACoreBaseIO(config: ACoreConfig, enable_rvfi: Boolean) extends Bundle {

  // Instruction fetch port
  val ifetch_req         = Output(Bool())
  val ifetch_gnt         = Input(Bool())
  val ifetch_raddr       = Output(UInt(config.addr_width.W))
  val ifetch_rdata       = Input(UInt(config.data_width.W))
  val ifetch_rdata_valid = Input(Bool())
  val ifetch_fault       = Input(Bool())

  // Core enable
  val core_en = Input(Bool())
  // Core has encountered a trap
  val core_fault = Output(Bool())

  /** LSU port for data memory */
  val dmem = Flipped(MemoryInterface(config.addr_width, config.data_width))

  // Debug interface
  val debug = if (config.debug) Some(DebugIO()) else None

  // RISC-V formal verification interface
  val rvfi  = if (enable_rvfi) Some(RVFIIO(XLEN = config.data_width)) else None

  // HPM freq enable signal
  val load_indicator = Output(Bool())
}

/** A-Core Generator
  * @param config
  *   ACoreConfig configuration class
  * @param enable_rvfi
  *   Enable RV formal interface.
  */
class ACoreBase(
    config: ACoreConfig  = ACoreConfig.default,
    enable_rvfi: Boolean = false,
) extends Module {

  val io = IO(ACoreBaseIO(config, enable_rvfi))
  // Don't optimize IO ports away
  dontTouch(io)

  // ======================================= Modules and Blocks =========================================

  // Core modules
  val decoder_block       = Module(new DecoderBlock(config))
  val multiplier          = new MultiplierPipelined(XLEN = config.data_width)
  val mul_s1              = Module(new multiplier.Stage1)
  val mul_s2              = Module(new multiplier.Stage2)
  val divider             = Module(new Divider(XLEN = config.data_width))
  val control             = Module(new Control(config))
  val regfile_block       = Module(new RegFileBlock(config, enable_rvfi = enable_rvfi))
  val pc_block            = Module(new PCBlock(XLEN = config.data_width))
  val branch_predictor    = Module(new PredictNotTaken(XLEN = config.data_width))
  val ppl_ctrl            = Module(new PipelineController(config))
  val trap_ctrl           = Module(new TrapController(XLEN = config.data_width))
  val alu_block           = Module(new ALUBlock(config))
  val csreg_block         = Module(new ControlStatusBlock(config))
  val csrex               = Module(new CSREx(config))
  val illegal_instr_check = Module(new IllegalInstrCheck(config))

  // Debug instruction text
  val debug_instr_text = if (config.debug) Some(Module(new DebugInstrText)) else None

  // Debug connections
  if (config.debug) {
    debug_instr_text.get.io.instr := decoder_block.io.instr
    io.debug.get.instruction_text := debug_instr_text.get.io.instr_text
  }

  // indicates that the processor has encountered an exception sometime in the past
  val fault_reg = RegInit(false.B)

  // Saves if there is a trap during execution
  when(io.core_en && trap_ctrl.io.out.trap) {
    fault_reg := true.B
  }

  io.core_fault := fault_reg

  // HPM load indicator
  io.load_indicator := csreg_block.io.loadOut.load_indicator

  // Pipeline Handshaking signals
  // Valid = data produced by pipeline stage is valid and ready to be propagated
  // Ready = pipeline stage is ready to accept new data
  val ifa_valid  = WireDefault(true.B)
  val ifa_ready  = WireDefault(true.B)
  val ifd_valid  = WireDefault(true.B)
  val ifd_ready  = WireDefault(true.B)
  val id_valid   = WireDefault(true.B)
  val id_ready   = WireDefault(true.B)
  val ex_valid   = WireDefault(true.B)
  val ex_ready   = WireDefault(true.B)
  val mema_valid = WireDefault(true.B)
  val mema_ready = WireDefault(true.B)
  val memd_valid = WireDefault(true.B)
  val memd_ready = WireDefault(true.B)
  val wb_valid   = WireDefault(true.B)
  val wb_ready   = WireDefault(true.B)

  // Pipeline controller init signals
  ppl_ctrl.io.in.rs1_addr.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.rs2_addr.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.rs3_addr.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.rs1_select.getElements.foreach(_ := RegFileSelect.INT)
  ppl_ctrl.io.in.rs2_select.getElements.foreach(_ := RegFileSelect.INT)
  ppl_ctrl.io.in.rs3_select.getElements.foreach(_ := RegFileSelect.INT)
  ppl_ctrl.io.in.rd_select.getElements.foreach(_ := RegFileSelect.INT)
  ppl_ctrl.io.in.rd_addr.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.rd_wr_en.getElements.foreach(_ := false.B)
  ppl_ctrl.io.in.rd_wdata.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.rd_wdata_valid.getElements.foreach(_ := false.B)
  ppl_ctrl.io.in.csr_wdata.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.csr_dest_addr.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.csr_src_addr.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.csr_src_data.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.csr_wr_en.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.fflags.getElements.foreach(_ := 0.U)
  ppl_ctrl.io.in.mepc_busy.getElements.foreach(_ := false.B)
  ppl_ctrl.io.in.rm_select.getElements.foreach(_ := AluBlockRoundingSrc.SRM)
  ppl_ctrl.io.in.op_gens_fflags.getElements.foreach(_ := false.B)
  ppl_ctrl.io.in.ovflag.getElements.foreach(_ := 0.U)				// PEXT addition
  ppl_ctrl.io.in.op_gens_ovflag.getElements.foreach(_ := false.B)		// PEXT addition

  // ================================== Connections between modules ====================================
    
  // csr block event to control
  csreg_block.io.eventIn.event_en_m <> control.io.csr_block_event.event_en_m
  csreg_block.io.eventIn.event_en_f <> control.io.csr_block_event.event_en_f
  csreg_block.io.eventIn.event_en_b <> control.io.csr_block_event.event_en_b
  csreg_block.io.eventIn.event_en_j <> control.io.csr_block_event.event_en_j

  // IF-address stage
  // New program counter (PC) is loaded and moved to Program Memory input

  val ifa_ifd_next = Wire(new IFtoID(config.data_width, config.pc_init))

  val ifa_ifd_reg = RegEnable(ifa_ifd_next, init = ifa_ifd_next.default, enable = ifd_ready)

  // Fetch new instruction is IFD is ready to accept new data and this stage is not being flushed
  io.ifetch_req := ifd_ready && !ppl_ctrl.io.out.flush.ifa_ifd
  // Stage is valid if grant is given
  ifa_valid := io.ifetch_gnt && !ppl_ctrl.io.out.stall.ifa_ifd

  val core_en_delayed = RegNext(io.core_en)

  // Program counter registers and wires
  val pc       = WireInit(config.pc_init.U(32.W))
  val pc_2_reg = RegInit(config.pc_init.U(32.W))
  val pc_4_reg = RegInit(config.pc_init.U(32.W))
  val pc_2     = pc + 2.U
  val pc_4     = pc + 4.U

  pc_2_reg := pc_block.io.out.pc_2
  pc_4_reg := pc_block.io.out.pc_4

  // Detects a short 16b instruction
  val short_instr = {
    if (config.extension_set.contains(ISAExtension.C))
      (io.ifetch_rdata(1, 0) =/= 3.U)
    else
      false.B
  }
  
  pc := Mux(short_instr, pc_2_reg, pc_4_reg)

  io.ifetch_raddr := pc

  pc_block.io.in.pc_2            := pc_2
  pc_block.io.in.pc_4            := pc_4
  pc_block.io.in.pc              := pc
  pc_block.io.in.pc_select.stall := !ifa_valid

  // Propagate data if next stage is ready, data here is valid, and current stage is not being flushed
  when(ifd_ready && ifa_valid && !ppl_ctrl.io.out.flush.ifa_ifd) {
    ifa_ifd_next.ifetch_rdata := ifa_ifd_next.default.ifetch_rdata
    ifa_ifd_next.pc           := pc
    ifa_ifd_next.pc_2         := pc_2
    ifa_ifd_next.pc_4         := pc_4
    ifa_ifd_next.pc_next      := ifa_ifd_next.default.pc_next
    ifa_ifd_next.trap_ctrl_en := !trap_ctrl.io.out.trap
    ifa_ifd_next.wr_disable   := trap_ctrl.io.out.trap
    ifa_ifd_next.ret          := true.B
    ifa_ifd_next.nop          := false.B

    ifa_ifd_next.state_vector.foreach(_ := false.B)
  }.otherwise {
    // Otherwise transmit a NOP (no operation)
    ifa_ifd_next := ifa_ifd_next.default
  }

  // IF-data stage
  // Output from Program Memory is moved to pipeline register
  // The data is checked for validness and if it is a short 16 bit instruction

  val ifd_id_next = Wire(new IFtoID(config.data_width, config.pc_init))
  val ifd_id_reg  = RegEnable(ifd_id_next, init = ifd_id_next.default, enable = id_ready)

  // Register to store valid status
  val valid_reg = RegInit(false.B)
  // Register to store short status
  val short_reg = RegInit(false.B)
  // Temporary register to store ifetch data if necessary
  val temp_ifetch_rdata_reg = RegInit(0.U(config.data_width.W))

  // Data at IFD is valid if the read data is valid or it is a no-operation (caused by flush)
  ifd_valid := (io.ifetch_rdata_valid || valid_reg || ifa_ifd_reg.nop || ppl_ctrl.io.out.flush.ifa_ifd) && !ppl_ctrl.io.out.stall.ifd_id
  // IFD is ready to receive data if data here is valid and next stage is ready
  ifd_ready := ifd_valid && id_ready

  // If next stage is not ready to receive data, but data here is valid,
  // store the data and validness in a temporary register
  // The valid signal is only a pulse regardless of the length of req,
  // therefore it needs to be saved in case of stalls
  when(!id_ready && io.ifetch_rdata_valid && !ppl_ctrl.io.out.flush.ifd_id) {
    temp_ifetch_rdata_reg := Mux(ppl_ctrl.io.out.flush.ifd_id, ifd_id_next.default.ifetch_rdata, io.ifetch_rdata)
    valid_reg             := true.B
    short_reg             := short_instr
  } .elsewhen(ppl_ctrl.io.out.flush.ifd_id) {
    valid_reg := false.B
  }

  when(id_ready && ifd_valid && !ppl_ctrl.io.out.flush.ifd_id) {
    // In case IFA sends a no-operation, do not use ifetch_rdata
    ifd_id_next.ifetch_rdata := Mux(
      io.ifetch_rdata_valid,
      io.ifetch_rdata,
      Mux(valid_reg, temp_ifetch_rdata_reg, ifd_id_next.default.ifetch_rdata)
    )
    ifd_id_next.pc           := ifa_ifd_reg.pc
    ifd_id_next.ret          := ifa_ifd_reg.ret
    ifd_id_next.state_vector := ifa_ifd_reg.state_vector
    ifd_id_next.trap_ctrl_en := ifa_ifd_reg.trap_ctrl_en && !trap_ctrl.io.out.trap
    ifd_id_next.wr_disable   := ifa_ifd_reg.wr_disable || trap_ctrl.io.out.trap
    valid_reg                := false.B
    temp_ifetch_rdata_reg    := ifd_id_next.default.ifetch_rdata
    ifd_id_next.pc_2         := ifd_id_next.default.pc_2
    ifd_id_next.pc_4         := ifd_id_next.default.pc_4
    ifd_id_next.pc_next      := Mux(Mux(valid_reg, short_reg, short_instr), ifa_ifd_reg.pc_2, ifa_ifd_reg.pc_4)
    ifd_id_next.nop          := ifd_id_next.default.nop

    ifd_id_next.state_vector(ExceptionCauses.INSTR_ACCESS_FAULT.asUInt) := io.ifetch_fault
  }.otherwise {
    ifd_id_next := ifd_id_next.default
  }

  // ID stage
  // Instruction is decoded and control signals are generated
  // Register file is read
  // Control-Status register (CSR) is read if necessary
  // The instruction is checked for illegal instruction
  // Register and CSR data is forwarded if possible

  val id_ex_next = Wire((new IDtoEX(config.data_width, config.default_misa)))
  val id_ex_reg  = RegEnable(id_ex_next, init = id_ex_next.default, enable = ex_ready)

  // This stage can be stalled in case of a load hazard
  // If the stage is flushed, then it must not be stalled
  id_valid := ppl_ctrl.io.out.flush.id_ex || !ppl_ctrl.io.out.stall.id_ex
  id_ready := id_valid && ex_ready

  decoder_block.io.instr_bits := ifd_id_reg.ifetch_rdata

  regfile_block.io.readIn.data.rs1_addr := decoder_block.io.rs1
  regfile_block.io.readIn.data.rs2_addr := decoder_block.io.rs2
  regfile_block.io.readIn.control <> control.io.regfile_block_read

  control.io.rd      := decoder_block.io.rd
  control.io.rs1     := decoder_block.io.rs1
  control.io.rs2     := decoder_block.io.rs2		// PEXT addition	
  control.io.opcode  := decoder_block.io.opcode
  control.io.funct3  := decoder_block.io.funct3
  control.io.funct7  := decoder_block.io.funct7
  control.io.funct12 := decoder_block.io.funct12

  ppl_ctrl.io.in.jump := control.io.jump

  csreg_block.io.readIn.data.csr_raddr := decoder_block.io.funct12
  csreg_block.io.readIn.control <> control.io.csr_block_read

  // Forwarding F-extension enable bit
  val current_f_en = Mux(
    ppl_ctrl.io.out.forward_misa, 
    ppl_ctrl.io.out.misa_forward_data(5), 
    csreg_block.io.dataOut.f_en
  )      

  // Forwarding P-extension enable bit		// PEXT addition
  val current_p_en = Mux(
    ppl_ctrl.io.out.forward_misa, 
    ppl_ctrl.io.out.misa_forward_data(15), 
    csreg_block.io.dataOut.p_en
  )   

  illegal_instr_check.io.in.f_op           := control.io.alu_block.f_ext.fpu_en
  illegal_instr_check.io.in.rm_src         := control.io.alu_block.f_ext.rm_src
  illegal_instr_check.io.in.rm             := csreg_block.io.dataOut.rm
  illegal_instr_check.io.in.illegal_opcode := control.io.illegal_instr
  illegal_instr_check.io.in.f_en           := current_f_en
  illegal_instr_check.io.in.p_op           := control.io.alu_block.p_ext.pext_en	// PEXT addition
  illegal_instr_check.io.in.p_en           := current_p_en				// PEXT addition

  // Extension-specific
  regfile_block.io.readIn.data.rs3_addr := Mux(										// PEXT edit
                                              control.io.regfile_block_read.rs3_out_src === RegFileSelect.FLOAT,
                                              decoder_block.io.f_ext.rs3,
                                              decoder_block.io.rd)  
  control.io.f_ext.fpu_rs2                    := decoder_block.io.rs2

  when(ex_ready && id_valid && !ppl_ctrl.io.out.flush.id_ex) {

    id_ex_next.rs1     := decoder_block.io.rs1
    id_ex_next.rs2     := decoder_block.io.rs2
    id_ex_next.rs3     := Mux(										// PEXT edit
                              control.io.regfile_block_read.rs3_out_src === RegFileSelect.FLOAT,
                              decoder_block.io.f_ext.rs3,
                              decoder_block.io.rd) 
    id_ex_next.rd      := decoder_block.io.rd
    id_ex_next.imm     := decoder_block.io.imm
    id_ex_next.opcode  := decoder_block.io.opcode
    id_ex_next.funct3  := decoder_block.io.funct3
    id_ex_next.funct7  := decoder_block.io.funct7
    id_ex_next.funct12 := decoder_block.io.funct12
    // Register data is forwarded in case of data hazards, see PipelineController
    id_ex_next.rs1_rdata := Mux(
      ppl_ctrl.io.out.forward_vec(0),
      ppl_ctrl.io.out.rs_forward_data_vec(0),
      regfile_block.io.readOut.data.rs1_rdata
    )
    id_ex_next.rs2_rdata := Mux(
      ppl_ctrl.io.out.forward_vec(1),
      ppl_ctrl.io.out.rs_forward_data_vec(1),
      regfile_block.io.readOut.data.rs2_rdata
    )
    id_ex_next.rs3_rdata := Mux(
      ppl_ctrl.io.out.forward_vec(2),
      ppl_ctrl.io.out.rs_forward_data_vec(2),
      regfile_block.io.readOut.data.rs3_rdata
    )
    id_ex_next.csr_rdata := Mux(
      ppl_ctrl.io.out.forward_csr,
      ppl_ctrl.io.out.csr_forward_data,
      csreg_block.io.dataOut.csr_rdata
    )
    id_ex_next.csr_raddr := decoder_block.io.funct12
    id_ex_next.csr_waddr := decoder_block.io.funct12
    // Dynamic rounding mode bits get forwarded too
    id_ex_next.rm := Mux(
      ppl_ctrl.io.out.forward_drm, 
      ppl_ctrl.io.out.drm_forward_data, 
      csreg_block.io.dataOut.rm
    )
    id_ex_next.f_en := current_f_en
    id_ex_next.p_en := current_p_en		// PEXT addition
    id_ex_next.pc              := ifd_id_reg.pc
    id_ex_next.pc_next         := ifd_id_reg.pc_next
    id_ex_next.mret            := control.io.mret
    id_ex_next.mepc_busy       := control.io.mepc_busy
    id_ex_next.mem_read_req    := control.io.lsu.req_info.ren
    id_ex_next.state_vector    := ifd_id_reg.state_vector
    id_ex_next.trap_ctrl_en    := ifd_id_reg.trap_ctrl_en && !trap_ctrl.io.out.trap
    id_ex_next.wr_disable      := ifd_id_reg.wr_disable || trap_ctrl.io.out.trap
    id_ex_next.ret             := ifd_id_reg.ret
    id_ex_next.jump            := control.io.jump
    id_ex_next.rd_src          := control.io.rd_src
    
    // Control signals generated by control are stored in their own signal bundles
    id_ex_next.regfile_write_control <> control.io.regfile_block_write
    id_ex_next.alublock_control <> control.io.alu_block
    id_ex_next.lsu_control <> control.io.lsu
    id_ex_next.csrblock_read_control <> control.io.csr_block_read
    id_ex_next.csrblock_write_control <> control.io.csr_block_write
    id_ex_next.csr_ex_control <> control.io.csr_ex
    id_ex_next.muldiv_op := control.io.muldiv_op

    id_ex_next.state_vector(ExceptionCauses.ILLEGAL_INSTR.asUInt) := illegal_instr_check.io.out.illegal_instr
    id_ex_next.state_vector(ExceptionCauses.BREAKPOINT.asUInt)    := control.io.breakpoint
  }.otherwise {
    id_ex_next := id_ex_next.default
    id_ex_next.f_en := current_f_en
    id_ex_next.p_en := current_p_en		// PEXT addition
  }

  // EX stage
  // ALU performs its operation
  // CSR data is manipulated
  // Branch and jump target addresses are calculated

  val ex_mema_next = Wire(new EXtoMEM(config.data_width))
  val ex_mema_reg  = RegEnable(ex_mema_next, init = ex_mema_next.default, enable = mema_ready)

  ex_valid := !ppl_ctrl.io.out.stall.ex_mema && (alu_block.io.out.data.valid || mul_s1.io.out.valid || divider.io.out.valid)
  ex_ready := ex_valid && mema_ready

  alu_block.io.in.data.pc          := id_ex_reg.pc
  alu_block.io.in.data.imm         := id_ex_reg.imm
  alu_block.io.in.data.read_a_data := id_ex_reg.rs1_rdata
  alu_block.io.in.data.read_b_data := id_ex_reg.rs2_rdata
  alu_block.io.in.data.funct3      := id_ex_reg.funct3
  alu_block.io.in.data.opcode      := id_ex_reg.opcode
  alu_block.io.in.data.clear       := trap_ctrl.io.out.trap
  alu_block.io.in.control <> id_ex_reg.alublock_control

  
  mul_s1.io.in.op        := id_ex_reg.muldiv_op
  mul_s1.io.in.operand_a := id_ex_reg.rs1_rdata
  mul_s1.io.in.operand_b := id_ex_reg.rs2_rdata
  
  divider.io.in.bits.operand_a := id_ex_reg.rs1_rdata
  divider.io.in.bits.operand_b := id_ex_reg.rs2_rdata
  divider.io.in.bits.op        := id_ex_reg.muldiv_op
  divider.io.in.bits.clear     := trap_ctrl.io.out.trap
  divider.io.in.valid          := true.B

  ppl_ctrl.io.in.branch := alu_block.io.out.data.branch_taken

  csrex.io.in.data.csr_rdata := id_ex_reg.csr_rdata
  csrex.io.in.data.rs1       := id_ex_reg.rs1
  csrex.io.in.data.rs1_rdata := id_ex_reg.rs1_rdata
  csrex.io.in.data.csr_waddr := id_ex_reg.funct12
  csrex.io.in.control <> id_ex_reg.csr_ex_control

  // Extension-specific
  alu_block.io.in.data.f_ext.read_c_data := id_ex_reg.rs3_rdata
  alu_block.io.in.data.f_ext.static_rm   := id_ex_reg.funct3
  alu_block.io.in.data.f_ext.dynamic_rm  := id_ex_reg.rm
  alu_block.io.in.control.f_ext.fpu_en   := id_ex_reg.f_en
  alu_block.io.in.data.p_ext.vxsat_in    := csreg_block.io.dataOut.csr_rdata(0)	// PEXT addition - routing of vxsat_in between csr and alu
  alu_block.io.in.control.p_ext.pext_en  := id_ex_reg.p_en			// PEXT addition
  alu_block.io.in.data.p_ext.acc         := id_ex_reg.rs3_rdata			// PEXT addition
  

  // Mux for data that is going to destination register
  val ex_rd_wdata = MuxCase(0.U, Seq(
    (id_ex_reg.rd_src === RegFileSrc.ALU_RESULT) -> alu_block.io.out.data.result,
    (id_ex_reg.rd_src === RegFileSrc.DIV_RESULT) -> divider.io.out.bits.result,
    (id_ex_reg.rd_src === RegFileSrc.CSR_RESULT) -> id_ex_reg.csr_rdata,
    (id_ex_reg.rd_src === RegFileSrc.IMM)        -> id_ex_reg.imm,
    (id_ex_reg.rd_src === RegFileSrc.PC_4)       -> id_ex_reg.pc_next,
  ))

  val ex_rd_wdata_valid = MuxCase(0.U, Seq(
    (id_ex_reg.rd_src === RegFileSrc.ALU_RESULT) -> alu_block.io.out.data.valid,
    (id_ex_reg.rd_src === RegFileSrc.DIV_RESULT) -> divider.io.out.valid,
    (id_ex_reg.rd_src === RegFileSrc.CSR_RESULT) -> true.B,
    (id_ex_reg.rd_src === RegFileSrc.IMM)        -> true.B,
    (id_ex_reg.rd_src === RegFileSrc.PC_4)       -> true.B,
  ))


  when(mema_ready && ex_valid && !ppl_ctrl.io.out.flush.ex_mema) {
    ex_mema_next.rs1             := id_ex_reg.rs1
    ex_mema_next.rd              := id_ex_reg.rd
    ex_mema_next.opcode          := id_ex_reg.opcode
    ex_mema_next.funct3          := id_ex_reg.funct3
    ex_mema_next.funct12         := id_ex_reg.funct12
    ex_mema_next.pc              := id_ex_reg.pc
    ex_mema_next.rs1_rdata       := id_ex_reg.rs1_rdata
    ex_mema_next.rs2_rdata       := id_ex_reg.rs2_rdata
    ex_mema_next.mem_read_req    := id_ex_reg.mem_read_req
    ex_mema_next.mret            := id_ex_reg.mret
    ex_mema_next.mepc_busy       := id_ex_reg.mepc_busy
    ex_mema_next.state_vector    := id_ex_reg.state_vector
    ex_mema_next.csr_wdata       := csrex.io.out.data.csr_wdata
    ex_mema_next.csr_raddr       := id_ex_reg.csr_raddr
    ex_mema_next.csr_waddr       := id_ex_reg.csr_waddr
    ex_mema_next.rd_wdata        := ex_rd_wdata
    ex_mema_next.rd_wdata_valid  := ex_rd_wdata_valid
    ex_mema_next.rd_src          := id_ex_reg.rd_src
    ex_mema_next.wr_disable      := id_ex_reg.wr_disable || trap_ctrl.io.out.trap
    ex_mema_next.ret             := id_ex_reg.ret

    ex_mema_next.trap_ctrl_en := id_ex_reg.trap_ctrl_en && !trap_ctrl.io.out.trap

    ex_mema_next.state_vector(ExceptionCauses.INSTR_ADDR_MISALIG.asUInt) := alu_block.io.out.data.exception

    ex_mema_next.mul_s1_to_s2 <> mul_s1.io.out
    ex_mema_next.alu_data <> alu_block.io.out.data
    ex_mema_next.alu_data.result := alu_block.io.out.data.result
    ex_mema_next.regfile_write_control <> id_ex_reg.regfile_write_control
    ex_mema_next.lsu_control <> id_ex_reg.lsu_control
    ex_mema_next.csrblock_write_control <> id_ex_reg.csrblock_write_control
  }.otherwise {
    ex_mema_next := ex_mema_next.default
  }

  // MEM-address stage
  // Read or write address is moved to Load-Store Unit (LSU)
  // Exceptions are checked - LSU write is stopped if there exists any

  val mema_memd_next = Wire(new MEMtoWB(config.data_width))
  val mema_memd_reg  = RegEnable(mema_memd_next, init = mema_memd_next.default, enable = memd_ready)

  // If req is high but gnt is low, and there was not a misaligned address, stage is stalled until gnt goes high
  mema_valid := !((io.dmem.req && !io.dmem.gnt) 
                  && !io.dmem.rd_misalig 
                  && !io.dmem.wr_misalig) && !ppl_ctrl.io.out.stall.mema_memd
  mema_ready := mema_valid && memd_ready

  // Check if there have been exceptions
  // Needed to stop possible write to memory
  val fault_at_mema = ex_mema_reg.state_vector.contains(true.B)

  io.dmem.info.op_width    := MemOpWidth(ex_mema_reg.funct3(1, 0))
  io.dmem.info.wdata       := ex_mema_reg.rs2_rdata
  io.dmem.info.op_unsigned := ex_mema_reg.funct3(2)
  io.dmem.info.addr        := ex_mema_reg.alu_data.result
  io.dmem.info.wmask       := 0.U
  // Dont read or write if there is an exception or trap condition
  io.dmem.req      := ex_mema_reg.lsu_control.req && !fault_at_mema && !ex_mema_reg.wr_disable && memd_valid
  io.dmem.info.ren := ex_mema_reg.lsu_control.req_info.ren
  io.dmem.info.wen := ex_mema_reg.lsu_control.req_info.wen
  io.dmem.atomic_req := ex_mema_reg.lsu_control.req_info.atomic

  mul_s2.io.in <> ex_mema_reg.mul_s1_to_s2

  val mema_rd_wdata = Mux(ex_mema_reg.rd_src === RegFileSrc.MULT_RESULT, mul_s2.io.out.bits.result, ex_mema_reg.rd_wdata)

  val mema_rd_wdata_valid = Mux(ex_mema_reg.rd_src === RegFileSrc.MULT_RESULT, mul_s2.io.out.valid, ex_mema_reg.rd_wdata_valid)

  when(memd_ready && mema_valid && !ppl_ctrl.io.out.flush.mema_memd) {
    mema_memd_next.rs1             := ex_mema_reg.rs1
    mema_memd_next.csr_wdata       := ex_mema_reg.csr_wdata
    mema_memd_next.csr_raddr       := ex_mema_reg.csr_raddr
    mema_memd_next.csr_waddr       := ex_mema_reg.csr_waddr
    mema_memd_next.opcode          := ex_mema_reg.opcode
    mema_memd_next.rd              := ex_mema_reg.rd
    mema_memd_next.funct12         := ex_mema_reg.funct12
    mema_memd_next.rs1_rdata       := ex_mema_reg.rs1_rdata
    mema_memd_next.pc              := ex_mema_reg.pc
    mema_memd_next.mem_read_req    := ex_mema_reg.mem_read_req
    mema_memd_next.mret            := ex_mema_reg.mret
    mema_memd_next.mepc_busy       := ex_mema_reg.mepc_busy
    mema_memd_next.state_vector    := ex_mema_reg.state_vector
    mema_memd_next.wr_disable      := ex_mema_reg.wr_disable || trap_ctrl.io.out.trap
    mema_memd_next.trap_ctrl_en    := ex_mema_reg.trap_ctrl_en && !trap_ctrl.io.out.trap
    mema_memd_next.ret             := ex_mema_reg.ret
    mema_memd_next.rd_wdata        := mema_rd_wdata
    mema_memd_next.rd_wdata_valid  := mema_rd_wdata_valid
    mema_memd_next.rd_src          := ex_mema_reg.rd_src
    mema_memd_next.alu_data <> ex_mema_reg.alu_data
    mema_memd_next.alu_data.result := Mux(mul_s2.io.out.valid, mul_s2.io.out.bits.result, ex_mema_reg.alu_data.result)
    mema_memd_next.regfile_write_control <> ex_mema_reg.regfile_write_control
    mema_memd_next.csrblock_write_control <> ex_mema_reg.csrblock_write_control

    // Dummy values not used anywhere
    mema_memd_next.trap   := false.B
    mema_memd_next.mepc   := 0.U
    mema_memd_next.mcause := 0.U

    mema_memd_next.state_vector(ExceptionCauses.LOAD_ADDR_MISALIG.asUInt)  := io.dmem.rd_misalig
    mema_memd_next.state_vector(ExceptionCauses.STORE_ADDR_MISALIG.asUInt) := io.dmem.wr_misalig

  }.otherwise {
    mema_memd_next := mema_memd_next.default
  }

  // MEM-data stage
  // Data coming from LSU is moved to pipeline register
  // The validness is checked
  // Traps are handled by Trap Controller

  val memd_wb_next = Wire(new MEMtoWB(config.data_width))
  val memd_wb_reg  = RegEnable(memd_wb_next, init = memd_wb_next.default, enable = wb_ready)

  // If read request and data not valid, wait for valid
  memd_valid := (!(!io.dmem.rdata.valid && mema_memd_reg.mem_read_req && !trap_ctrl.io.out.trap) && !ppl_ctrl.io.out.stall.memd_wb)

  memd_ready := memd_valid && wb_ready

  // Trap Controller connections
  trap_ctrl.io.in.state_vector := mema_memd_reg.state_vector
  trap_ctrl.io.in.pc           := mema_memd_reg.pc
  trap_ctrl.io.in.mtvec        := csreg_block.io.trapOut.mtvec
  trap_ctrl.io.in.en           := mema_memd_reg.trap_ctrl_en

  trap_ctrl.io.in.state_vector(ExceptionCauses.STORE_ACCESS_FAULT.asUInt) := io.dmem.wr_fault
  trap_ctrl.io.in.state_vector(ExceptionCauses.LOAD_ACCESS_FAULT.asUInt)  := io.dmem.rd_fault

  val memd_rd_wdata = Mux(mema_memd_reg.rd_src === RegFileSrc.MEM_DATA, io.dmem.rdata.bits, mema_memd_reg.rd_wdata)

  val memd_rd_wdata_valid = Mux(mema_memd_reg.rd_src === RegFileSrc.MEM_DATA, io.dmem.rdata.valid, mema_memd_reg.rd_wdata_valid)

  when(wb_ready && memd_valid && !ppl_ctrl.io.out.flush.memd_wb) {
    memd_wb_next.rs1             := mema_memd_reg.rs1
    memd_wb_next.rd              := mema_memd_reg.rd
    memd_wb_next.funct12         := mema_memd_reg.funct12
    memd_wb_next.rs1_rdata       := mema_memd_reg.rs1_rdata
    memd_wb_next.pc              := mema_memd_reg.pc
    memd_wb_next.opcode          := mema_memd_reg.opcode
    memd_wb_next.mem_read_req    := mema_memd_reg.mem_read_req
    memd_wb_next.csr_wdata       := mema_memd_reg.csr_wdata
    memd_wb_next.csr_raddr       := mema_memd_reg.csr_raddr
    memd_wb_next.csr_waddr       := mema_memd_reg.csr_waddr
    memd_wb_next.mret            := mema_memd_reg.mret
    memd_wb_next.mepc_busy       := mema_memd_reg.mepc_busy
    memd_wb_next.mcause          := trap_ctrl.io.out.mcause
    memd_wb_next.mepc            := trap_ctrl.io.out.mepc
    memd_wb_next.trap            := trap_ctrl.io.out.trap
    memd_wb_next.state_vector    := mema_memd_reg.state_vector
    memd_wb_next.wr_disable      := mema_memd_reg.wr_disable || trap_ctrl.io.out.trap
    memd_wb_next.ret             := mema_memd_reg.ret
    memd_wb_next.rd_wdata        := memd_rd_wdata
    memd_wb_next.rd_src          := mema_memd_reg.rd_src
    memd_wb_next.rd_wdata_valid  := memd_rd_wdata_valid

    memd_wb_next.alu_data <> mema_memd_reg.alu_data
    memd_wb_next.regfile_write_control <> mema_memd_reg.regfile_write_control
    memd_wb_next.csrblock_write_control <> mema_memd_reg.csrblock_write_control

    // Dummy values
    memd_wb_next.trap_ctrl_en := false.B
  }.otherwise {
    memd_wb_next        := memd_wb_next.default
    memd_wb_next.mcause := trap_ctrl.io.out.mcause
    memd_wb_next.mepc   := trap_ctrl.io.out.mepc
    memd_wb_next.trap   := trap_ctrl.io.out.trap
  }

  // WB stage
  // Data is written to register file
  // Data is written to CSRs
  // In the case of trap or trap return (mret), source for new PC is selected

  // Displaying PC helps in the waveform view
  if (config.debug) {
    dontTouch(memd_wb_reg.pc)
  }

  wb_ready := true.B

  regfile_block.io.writeIn.data.rd_wdata := memd_wb_reg.rd_wdata
  regfile_block.io.writeIn.data.rd_waddr := memd_wb_reg.rd

  csreg_block.io.writeIn.data.csr_waddr  := memd_wb_reg.csr_waddr
  csreg_block.io.writeIn.data.csr_wdata  := memd_wb_reg.csr_wdata
  csreg_block.io.writeIn.data.fault_data := memd_wb_reg.alu_data.f_ext.fault_data
  csreg_block.io.writeIn.data.vxsat_out  := memd_wb_reg.alu_data.p_ext.vxsat_out	// PEXT additions

  csreg_block.io.trapIn.mcause := memd_wb_reg.mcause
  csreg_block.io.trapIn.mepc   := memd_wb_reg.mepc
  csreg_block.io.trapIn.trap   := memd_wb_reg.trap

  regfile_block.io.writeIn.control <> memd_wb_reg.regfile_write_control

  regfile_block.io.writeIn.control.wr_en := memd_wb_reg.regfile_write_control.wr_en && !memd_wb_reg.wr_disable

  csreg_block.io.writeIn.control <> memd_wb_reg.csrblock_write_control
  csreg_block.io.writeIn.control.write_en   := memd_wb_reg.csrblock_write_control.write_en && !memd_wb_reg.wr_disable
  csreg_block.io.writeIn.control.instret_en := memd_wb_reg.ret

  pc_block.io.in.pc_select.jump_target := alu_block.io.out.data.result
  pc_block.io.in.pc_select.branch_target := alu_block.io.out.data.branch_target
  pc_block.io.in.pc_select.branch_target_predicted := branch_predictor.io.out.pc_predicted
  pc_block.io.in.pc_select.branch := ppl_ctrl.io.out.load_branch_addr
  pc_block.io.in.pc_select.branch_predicted := branch_predictor.io.out.predict_branch
  pc_block.io.in.pc_select.jump := ppl_ctrl.io.out.load_jump_addr

  pc_block.io.in.mepc                := csreg_block.io.trapOut.mepc
  pc_block.io.in.pc_select.load_mepc := ppl_ctrl.io.out.load_mepc

  pc_block.io.in.mtvec          := csreg_block.io.trapOut.mtvec
  pc_block.io.in.pc_select.trap := memd_wb_reg.trap


  branch_predictor.io.in.branch_result := alu_block.io.out.data.branch_taken
  branch_predictor.io.in.branch_target := alu_block.io.out.data.branch_target
  branch_predictor.io.in.pc            := pc

  // Core enable signal - if this is false, all stages are stalled
  ppl_ctrl.io.in.core_en    := io.core_en

  // Pipeline Controller connections for register and CSR forwarding
  ppl_ctrl.io.in.rs1_addr.id_ex      := decoder_block.io.rs1
  ppl_ctrl.io.in.rs2_addr.id_ex      := decoder_block.io.rs2
  ppl_ctrl.io.in.rs3_addr.id_ex      := Mux(										// PEXT edit
                                            control.io.regfile_block_read.rs3_out_src === RegFileSelect.FLOAT,
                                            decoder_block.io.f_ext.rs3,
                                            decoder_block.io.rd) 
  ppl_ctrl.io.in.rs1_select.id_ex    := control.io.regfile_block_read.rs1_out_src
  ppl_ctrl.io.in.rs2_select.id_ex    := control.io.regfile_block_read.rs2_out_src
  // rs3 can come only from float regfile. EDIT: based on the current instruction reg file src
  ppl_ctrl.io.in.rs3_select.id_ex    := control.io.regfile_block_read.rs3_out_src                // PEXT edit    RegFileSelect.FLOAT
  ppl_ctrl.io.in.rd_addr.ex_mema     := ex_mema_next.rd
  ppl_ctrl.io.in.rd_addr.mema_memd   := mema_memd_next.rd
  ppl_ctrl.io.in.rd_addr.memd_wb     := memd_wb_next.rd
  ppl_ctrl.io.in.rd_select.ex_mema   := ex_mema_next.regfile_write_control.wr_reg_select
  ppl_ctrl.io.in.rd_select.mema_memd := mema_memd_next.regfile_write_control.wr_reg_select
  ppl_ctrl.io.in.rd_select.memd_wb   := memd_wb_next.regfile_write_control.wr_reg_select
  ppl_ctrl.io.in.rd_wr_en.ex_mema    := ex_mema_next.regfile_write_control.wr_en
  ppl_ctrl.io.in.rd_wr_en.mema_memd  := mema_memd_next.regfile_write_control.wr_en
  ppl_ctrl.io.in.rd_wr_en.memd_wb    := memd_wb_next.regfile_write_control.wr_en

  ppl_ctrl.io.in.rd_wdata.ex_mema         := ex_mema_next.rd_wdata
  ppl_ctrl.io.in.rd_wdata.mema_memd       := mema_memd_next.rd_wdata
  ppl_ctrl.io.in.rd_wdata.memd_wb         := memd_wb_next.rd_wdata
  ppl_ctrl.io.in.rd_wdata_valid.ex_mema   := ex_mema_next.rd_wdata_valid
  ppl_ctrl.io.in.rd_wdata_valid.mema_memd := mema_memd_next.rd_wdata_valid
  ppl_ctrl.io.in.rd_wdata_valid.memd_wb   := memd_wb_next.rd_wdata_valid

  ppl_ctrl.io.in.mepc_busy.ex_mema        := ex_mema_next.mepc_busy
  ppl_ctrl.io.in.mepc_busy.mema_memd      := mema_memd_next.mepc_busy
  ppl_ctrl.io.in.mepc_busy.memd_wb        := memd_wb_next.mepc_busy
  ppl_ctrl.io.in.mepc_busy.wb             := memd_wb_reg.mepc_busy

  ppl_ctrl.io.in.csr_src_addr.id_ex := id_ex_next.csr_raddr
  ppl_ctrl.io.in.csr_src_data.id_ex := csreg_block.io.dataOut.csr_rdata

  ppl_ctrl.io.in.csr_dest_addr.ex_mema   := ex_mema_next.csr_waddr
  ppl_ctrl.io.in.csr_dest_addr.mema_memd := mema_memd_next.csr_waddr
  ppl_ctrl.io.in.csr_dest_addr.memd_wb   := memd_wb_next.csr_waddr
  ppl_ctrl.io.in.csr_wdata.ex_mema       := ex_mema_next.csr_wdata
  ppl_ctrl.io.in.csr_wdata.mema_memd     := mema_memd_next.csr_wdata
  ppl_ctrl.io.in.csr_wdata.memd_wb       := memd_wb_next.csr_wdata
  ppl_ctrl.io.in.csr_wr_en.ex_mema       := ex_mema_next.csrblock_write_control.write_en
  ppl_ctrl.io.in.csr_wr_en.mema_memd     := mema_memd_next.csrblock_write_control.write_en
  ppl_ctrl.io.in.csr_wr_en.memd_wb       := memd_wb_next.csrblock_write_control.write_en

  ppl_ctrl.io.in.fflags.ex_mema           := ex_mema_next.alu_data.f_ext.fault_data
  ppl_ctrl.io.in.fflags.mema_memd         := mema_memd_next.alu_data.f_ext.fault_data
  ppl_ctrl.io.in.fflags.memd_wb           := memd_wb_next.alu_data.f_ext.fault_data
  ppl_ctrl.io.in.op_gens_fflags.ex_mema   := ex_mema_next.csrblock_write_control.fault_en
  ppl_ctrl.io.in.op_gens_fflags.mema_memd := mema_memd_next.csrblock_write_control.fault_en
  ppl_ctrl.io.in.op_gens_fflags.memd_wb   := memd_wb_next.csrblock_write_control.fault_en
  
  ppl_ctrl.io.in.ovflag.ex_mema           := ex_mema_next.alu_data.p_ext.vxsat_out		// PEXT additions
  ppl_ctrl.io.in.ovflag.mema_memd         := mema_memd_next.alu_data.p_ext.vxsat_out
  ppl_ctrl.io.in.ovflag.memd_wb           := memd_wb_next.alu_data.p_ext.vxsat_out
  ppl_ctrl.io.in.op_gens_ovflag.ex_mema   := ex_mema_next.csrblock_write_control.ov_en
  ppl_ctrl.io.in.op_gens_ovflag.mema_memd := mema_memd_next.csrblock_write_control.ov_en
  ppl_ctrl.io.in.op_gens_ovflag.memd_wb   := memd_wb_next.csrblock_write_control.ov_en

  ppl_ctrl.io.in.rm_select.id_ex := id_ex_next.alublock_control.f_ext.rm_src

  ppl_ctrl.io.in.trap := trap_ctrl.io.out.trap
  ppl_ctrl.io.in.mret := control.io.mret

  // ===================================== RISC-V Formal Interface ======================================

  // FIXME: Fix RVFI after memory interconnect refactor

  if (enable_rvfi) {
    //
    // rvfi.get.valid  := true.B   // this is a single-cycle design so every clock cycle retires an instruction
    // rvfi.get.order  := insn_counter
    // rvfi.get.insn   := instruction_bytes
    // rvfi.get.trap   := control.io.exception
    // rvfi.get.halt   := 0.U
    // rvfi.get.intr   := 0.U
    // rvfi.get.mode   := 3.U      // machine mode
    // rvfi.get.ixl    := 1.U      // 32-bit

    // rvfi.get.rs1_addr   := regfile_block.io.rvfi_rs1_addr.get
    // rvfi.get.rs2_addr   := regfile_block.io.rvfi_rs2_addr.get
    // rvfi.get.rs1_rdata  := regfile_block.io.rvfi_rs1_rdata.get
    // rvfi.get.rs2_rdata  := regfile_block.io.rvfi_rs2_rdata.get
    // rvfi.get.wr_addr    := regfile_block.io.rvfi_wr_addr.get
    // rvfi.get.wr_data   := regfile_block.io.rvfi_wr_data.get

    // rvfi.get.pc_rdata := pc_block.io.rvfi_pc_rdata.get
    // rvfi.get.pc_wdata := pc_block.io.rvfi_pc_wdata.get

    // rvfi.get.mem_addr   := lsu.io.rvfi_mem_addr.get
    // rvfi.get.mem_rmask  := lsu.io.rvfi_mem_rmask.get
    // rvfi.get.mem_wmask  := lsu.io.rvfi_mem_wmask.get
    // rvfi.get.mem_rdata  := lsu.io.rvfi_mem_rdata.get
    // rvfi.get.mem_wdata  := lsu.io.rvfi_mem_wdata.get
  }

}

/** Generates verilog */
object ACoreBase extends App with OptionParser {

  // Parse command-line arguments
  val default_opts: Map[String, String] = Map(
    "-core_config" -> "",
    "-isa_string"  -> "",
    "-debug"       -> "",
    "-rvfi"        -> "false"
  )

  val help = Seq(
    ("-core_config", "String",  "A-Core configuration YAML file."),
    ("-isa_string",  "String",  "Manually set isa_string (e.g. \"rv32imfc\")."),
    ("-debug",       "Boolean", "Enable debug signals."),
    ("-rvfi",        "Boolean", "Enable RISC-V Formal Interface. Default \"false\"")
  )

  val (options, arguments) = getopts(default_opts, args.toList, help)

  val core_config_file = options("-core_config")

  val core_config: ACoreConfig = core_config_file match {
    case "" => ACoreConfig.default
    case c  => ACoreConfig.loadFromFile(c)
  }

  val isa_string = options("-isa_string")
  
  if (isa_string != "") {
    core_config.extension_set = ACoreConfig.parseExtensionSet(isa_string)
  }

  val debug = options("-debug")
  if (debug != "") {
    core_config.debug = debug.toBoolean
  }

  core_config.validate()

  println(core_config)

  // Generate verilog
  val annos = Seq(ChiselGeneratorAnnotation(() =>
    new ACoreBase(
      config = core_config,
      enable_rvfi = options("-rvfi").toBoolean
    )
  ))

  (new ChiselStage).execute(arguments.toArray, annos)
}
