// SPDX-License-Identifier: Apache-2.0
// Inititally written by Verneri Hirvonen (verneri.hirvonen@aalto.fi), 2021-03-28

package acorebase

import chisel3._
import chisel3.util._
import chisel3.experimental._
import chisel3.iotesters.PeekPokeTester
import chisel3.stage.{ChiselStage, ChiselGeneratorAnnotation}
import a_core_common._

/**
  * F-extension specific signals (inputs and outputs)
  *
  * @param XLEN
  */
class ALUBlockFIO(XLEN: Int = 32) extends Bundle {
  //RV32F extension

  // Inputs
  val in = new Bundle {
    // Data path signals
    val data = new Bundle {
      // Static rounding mode
      val static_rm   = UInt(3.W)
      // Dynamic rounding mode
      val dynamic_rm 	= UInt(3.W)
      // Register file output
      val read_c_data = UInt(XLEN.W)
    }
    // Control signals
    val control = new Bundle {
      // Float operation
      val fpu_op = FPUOp()
      // Rounding mode source (static or dynamic)
      val rm_src  = AluBlockRoundingSrc()
      // FPU enable
      val fpu_en = Bool()
    }
  }
  // Outputs
  val out = new Bundle {
    // Data path signals
    val data = new Bundle {
      // Fault flag
      val fault_data = UInt(5.W)
    }
  }
}

/////////////////////////////////PEXT addition/////////////////////////////////////

/* P Extension specific signals */
class ALUBlockPIO extends Bundle {
  
  // Inputs
  val in = new Bundle {
    //--Data path--//
    val data = new Bundle {
      // data for overflow flag
      val vxsat_in = UInt(1.W)
      // Accumulator input for mac operations
      val acc = UInt(32.W)
    } 
    //--Control signals--//
    val control = new Bundle {
      // P extension operation
      val pext_op = PExtOp()
      // P Extension enable
      val pext_en = Bool()
    }
  }
  // Outputs
  val out = new Bundle {
    //--Data path--//
    val data = new Bundle {
      // Overflow flag
      val vxsat_out = UInt(1.W)
    }
  }
}

/////////////////////////////////////////////////////////////////////

/**
  * ALU Block Input signals
  *
  * @param XLEN
  */
class ALUBlockInputs(XLEN: Int = 32) extends Bundle {
  // data path signals
  val data = new Bundle {
    // Program counter
    val pc           = UInt(XLEN.W)
    // Immediate
    val imm          = UInt(XLEN.W)
    // Regfile outputs
    val read_a_data  = UInt(XLEN.W)
    val read_b_data  = UInt(XLEN.W)
    // Funct3 field from the instruction
    val funct3       = UInt(3.W)
    // Operation code
    val opcode       = Opcode()
    // Signal to stop and clear a multi-cycle process
    val clear = Bool()

    // Extensions
    val f_ext = new ALUBlockFIO(XLEN).in.data		
    val p_ext = new ALUBlockPIO().in.data 		// PEXT addition
  }
  // Control signals
  val control = new Bundle {
    // ALU operation
    val operation        = ALUOp()
    // Source for ALU input
    val operand_a_src    = AluOperandSrc()
    val operand_b_src    = AluOperandSrc()
    // Output selector
    val block_result_src = AluBlockResultSrc()

    val f_ext = new ALUBlockFIO(XLEN).in.control
    val p_ext = new ALUBlockPIO().in.control		// PEXT addition
  }
}

/**
  * ALU Block Output signals
  *
  * @param XLEN
  */
class ALUBlockOutputs(XLEN: Int = 32) extends Bundle {
  // Data path signals
  val data = new Bundle {
    // ALU result
    val result        = UInt(XLEN.W)
    // Branch target (address to jump to if branch is taken)
    val branch_target = UInt(XLEN.W)
    // Flag whether result was zero
    val zero          = Bool()
    // Output from branch comparator
    val branch_taken  = Bool()
    // Exception (something went wrong)
    val exception     = Bool()
    // ALU data is valid
    val valid         = Bool()

    // Extensions
    val f_ext = new ALUBlockFIO(XLEN).out.data
    val p_ext = new ALUBlockPIO().out.data		// PEXT addition
  }
}


/**
* ALU Block class
* @param config ACoreConfig configuration class
*/
class ALUBlock(config: ACoreConfig) extends Module {

  // Inputs and Outputs
  val io = IO(new Bundle {
    val in  = Input(new ALUBlockInputs(config.data_width))
    val out = Output(new ALUBlockOutputs(config.data_width))

    val debug_operand_a = if (config.debug) Some(Output(UInt(config.data_width.W))) else None
    val debug_operand_b = if (config.debug) Some(Output(UInt(config.data_width.W))) else None
  })

  // Submodules
  val alu = Module(new ALU(XLEN=config.data_width))
  val branch_comp = Module(new BranchComp(XLEN=config.data_width))
  val fpu_block = if (config.extension_set.contains(ISAExtension.F)) Some(Module(new FPUBlock(XLEN=config.data_width))) else None
  val pext_alu = if (config.extension_set.contains(ISAExtension.P)) Some(Module(new PExtALU())) else None 	// PEXT addition

  // mux wires (default to RegFile read port A on both muxes)
  val operand_a = WireDefault(io.in.data.read_a_data)
  val operand_b = WireDefault(io.in.data.read_a_data)

  io.out.data.exception := false.B
  io.out.data.f_ext.fault_data := "b00000".U
  io.out.data.valid := true.B
  io.out.data.p_ext.vxsat_out := "b0".U			// PEXT addition

  // operand A mux
  when (io.in.control.operand_a_src === AluOperandSrc.RS1) {
    operand_a := io.in.data.read_a_data
  } .elsewhen (io.in.control.operand_a_src === AluOperandSrc.RS2) {
    operand_a := io.in.data.read_b_data
  } .elsewhen (io.in.control.operand_a_src === AluOperandSrc.IMM) {
    operand_a := io.in.data.imm
  } .elsewhen (io.in.control.operand_a_src === AluOperandSrc.PC) {
    operand_a := io.in.data.pc
  }
  // operand B mux
  when (io.in.control.operand_b_src === AluOperandSrc.RS1) {
    operand_b := io.in.data.read_a_data
  } .elsewhen (io.in.control.operand_b_src === AluOperandSrc.RS2) {
    operand_b := io.in.data.read_b_data
  } .elsewhen (io.in.control.operand_b_src === AluOperandSrc.IMM) {
    operand_b := io.in.data.imm
  } .elsewhen (io.in.control.operand_b_src === AluOperandSrc.PC) {
    operand_b := io.in.data.pc
  }

  // Valid signal mux
  when (io.in.control.block_result_src === AluBlockResultSrc.ALU_OUT) {
    io.out.data.valid := true.B
  } .elsewhen (io.in.control.block_result_src === AluBlockResultSrc.SPFP_OUT) {
    io.out.data.valid := true.B
  } .elsewhen (io.in.control.block_result_src === AluBlockResultSrc.PEXT_OUT) {		// PEXT addition
    io.out.data.valid := true.B
  } .otherwise {
    io.out.data.valid := false.B
  }


  // ALU module connections
  alu.io.op    := io.in.control.operation
  alu.io.a     := operand_a
  alu.io.b     := operand_b
  io.out.data.zero := alu.io.zero

  // Branch comparator
  branch_comp.io.alu_result := alu.io.out
  branch_comp.io.alu_zero   := alu.io.zero
  branch_comp.io.funct3     := io.in.data.funct3
  branch_comp.io.opcode     := io.in.data.opcode
  branch_comp.io.imm        := io.in.data.imm
  branch_comp.io.pc         := io.in.data.pc
  io.out.data.branch_taken  := branch_comp.io.branch_taken
  io.out.data.branch_target := branch_comp.io.branch_target


  if (config.extension_set.contains(ISAExtension.C)) {
    // Misaligned accesses cannot happen if C-extension is on
    io.out.data.exception := false.B
  } else {
    // If instruction address is misaligned and a conditional branch is taken,
    // throw an exception
    when (branch_comp.io.branch_taken && io.in.data.imm(1,0).orR === true.B) {
      io.out.data.exception := true.B
    }
 } 


  if (config.extension_set.contains(ISAExtension.C)) {
    // Misaligned accesses cannot happen if C-extension is on
    io.out.data.exception := false.B
  } else {
    // If instruction address is misaligned for an unconditional jump,   
    // throw an exception
    when (io.in.data.opcode.isOneOf(Opcode.JAL, Opcode.JALR) && alu.io.out(1,0).orR) {
      io.out.data.exception := true.B
    }
 }

  // default to outputting ALU result
  io.out.data.result := alu.io.out


  // F extension
  if (config.extension_set.contains(ISAExtension.F)) {
    when (io.in.control.f_ext.fpu_en) {

      // FPUBlock connections
      fpu_block.get.io.control.op       := io.in.control.f_ext.fpu_op
      fpu_block.get.io.data.a           := io.in.data.read_a_data
      fpu_block.get.io.data.b           := io.in.data.read_b_data
      fpu_block.get.io.data.c           := io.in.data.f_ext.read_c_data
      io.out.data.f_ext.fault_data       := fpu_block.get.io.data.fault_data
      val rm = WireDefault(0.U(3.W))

      when (io.in.control.f_ext.rm_src === AluBlockRoundingSrc.SRM) {
        rm := io.in.data.f_ext.static_rm
      }.otherwise{
        rm := io.in.data.f_ext.dynamic_rm
      }

      when (rm === "b001".U) {
        fpu_block.get.io.control.rm := RoundingMode.RTZ
      } .elsewhen (rm === "b010".U) {
        fpu_block.get.io.control.rm := RoundingMode.RDN
      } .elsewhen (rm === "b011".U) {
        fpu_block.get.io.control.rm := RoundingMode.RUP
      } .elsewhen (rm === "b100".U) {
        fpu_block.get.io.control.rm := RoundingMode.RMM
      } .otherwise {
        fpu_block.get.io.control.rm := RoundingMode.RNE
      }

      // select final result from ALU or FPUBlock
      when (io.in.control.block_result_src === AluBlockResultSrc.SPFP_OUT) {
        io.out.data.result := fpu_block.get.io.data.out
      }
    } .otherwise {
      fpu_block.get.io.control.op := FPUOp.NULL
      fpu_block.get.io.data.a := 0.U
      fpu_block.get.io.data.b := 0.U
      fpu_block.get.io.data.c := 0.U
      fpu_block.get.io.control.rm := RoundingMode.NULL
      io.out.data.f_ext.fault_data := 0.U
    }
  }

//////////////////////////////////////////PEXT addition///////////////////////////////

  if (config.extension_set.contains(ISAExtension.P)) {
    when (io.in.control.p_ext.pext_en) {
      // PExtALU connections
      pext_alu.get.io.operation             := io.in.control.p_ext.pext_op
      pext_alu.get.io.Rs1                   := operand_a
      pext_alu.get.io.Rs2                   := operand_b
      pext_alu.get.io.acc		    := io.in.data.p_ext.acc
      pext_alu.get.io.vxsat_in              := io.in.data.p_ext.vxsat_in
      io.out.data.p_ext.vxsat_out       := pext_alu.get.io.vxsat_out

      // select final result from ALU or PExtALU
      when (io.in.control.block_result_src === AluBlockResultSrc.PEXT_OUT) {
        io.out.data.result := pext_alu.get.io.Rd
      }
    } .otherwise {
      pext_alu.get.io.operation := PExtOp.NULL
      pext_alu.get.io.Rs1 := 0.U
      pext_alu.get.io.Rs2 := 0.U
      pext_alu.get.io.acc := 0.U
      pext_alu.get.io.vxsat_in := 0.U
      io.out.data.p_ext.vxsat_out := 0.U
    }
  } 
/////////////////////////////////////////////////////////////////////////

  // debug connections
  if (config.debug) {
    io.debug_operand_a.get := operand_a
    io.debug_operand_b.get := operand_b
  }
}

/** Generates verilog */
object ALUBlock extends App {
  val annos = Seq(ChiselGeneratorAnnotation(() => new ALUBlock(
    config = ACoreConfig.default
  )))
  (new ChiselStage).execute(args, annos)
}
