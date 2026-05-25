`timescale 1ns/1ps

module tb_rv32im_pipeline;
  import rv32_pkg::*;

  logic clk;
  logic rst_n;

  rv32im_pipeline #(
      .IMEM_DEPTH(256),
      .DMEM_DEPTH(4096)
  ) dut (
    .clk(clk),
    .rst_n(rst_n)
  );

  int cycle_count;
  int retired_inst_count;
  bit running;
  bit done;
  bit done_d;

  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  localparam int depth      = 50; // (200byte) Fir
//  localparam int depth      = 1024; // Sobel, Matrix
  localparam int BaseAddr   = 32'h80010000;
  localparam int OAddr      = 32'h800100e8; // fir 
//  localparam int OAddr      = 32'h80011000; // Sobel
//  localparam int OAddr      = 32'h80010804; // Matrix
  localparam int DoneAddr   = 32'h80013ffc; // DMEM 16KB
  localparam int DONE_INDEX = (DoneAddr - BaseAddr) >> 2;

  initial begin
    logic [31:0] golden [depth];
    logic [31:0] result [depth];
    int error;

    #10;

    load_imem("../sw/Filter-Fir/scala_imem.hex");
    load_dmem("../sw/Filter-Fir/scala_dmem.hex");
    load_golden("../sw/Filter-Fir/scala_goldenw.hex", golden);

//    load_imem("../sw/Filter-Sobel/scala_imem.hex");
//    load_dmem("../sw/Filter-Sobel/scala_dmem.hex");
//    load_golden("../sw/Filter-Sobel/scala_goldenw.hex", golden);

//    load_imem("../sw/Matrix-Multiplication/scala_imem.hex");
//    load_dmem("../sw/Matrix-Multiplication/scala_dmem.hex");
//    load_golden("../sw/Matrix-Multiplication/scala_goldenw.hex", golden);

    // Chờ cho cờ done_flag = 1 từ file scala.c đánh dấu kết thúc
    wait (done == 1'b1);
    #20;

    dump_result(depth, BaseAddr, OAddr, "../sw/Filter-Fir/scala_signature.hex");
    load_result("../sw/Filter-Fir/scala_signature.hex", result);

//    dump_result(depth, BaseAddr, OAddr, "../sw/Filter-Sobel/scala_signature.hex");
//    load_result("../sw/Filter-Sobel/scala_signature.hex", result);

//    dump_result(depth, BaseAddr, OAddr, "../sw/Matrix-Multiplication/scala_signature.hex");
//    load_result("../sw/Matrix-Multiplication/scala_signature.hex", result);

    #1;
    compare_result(depth, OAddr, golden, result, error);
    if (error == 0)
      $display(" PASS");
    else
      $display(" FAIL: %0d mismatches", error);
    $finish;
  end

  task load_imem (input string prog_path);
    $readmemh(prog_path, dut.u_imem.rom_array);
  endtask

  task load_dmem (input string prog_path);
    $readmemh(prog_path, dut.u_dmem.ram_array);
  endtask

  task load_golden (input string golden_path, output logic [31:0] golden_o []);
    $readmemh(golden_path, golden_o);
  endtask

  task dump_result (int depth, int BaseAddr, int OAddr, input string result_path);
    int fd;
    int base;
    base = (OAddr - BaseAddr) >> 2;
    fd = $fopen(result_path, "w");
    for (int i = 0; i < depth; i++) begin
      $fdisplay(fd, "%08x", dut.u_dmem.ram_array[base + i]);
    end
    $fclose(fd);
  endtask

  task load_result (input string result_path, output logic [31:0] result_o []);
    $readmemh(result_path, result_o);
  endtask

  task compare_result (int depth, int OAddr, input logic [31:0] golden [], input logic [31:0] result [], output int num_mismatch);
    num_mismatch = 0;
    for (int i = 0; i < depth; i++) begin
      if (golden[i] !== result[i]) begin
        num_mismatch++;
        $display("Mismatch at address %0h: expected %08x, got %08x", OAddr + i*4, golden[i], result[i]);
      end
      else begin 
        $display("Match at address %0h: expected %08x, got %08x", OAddr + i*4, golden[i], result[i]);
      end
    end
  endtask

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_count <= 0;
      retired_inst_count <= 0;
      running <= 0;
      done <= 0;
      done_d <= 0;
    end
    else begin
      running <= 1;
      
      // Instruction Retired Counter (Method 1)
      // Increments when a non-NOP instruction reaches the WB stage
      if (dut.ctrl_WB != CTRL_NOP) begin
        retired_inst_count <= retired_inst_count + 1;
      end

      if (dut.u_dmem.ram_array[DONE_INDEX] == 32'h1) begin
         done <= 1;
      end
      if (running && !done) begin
        cycle_count <= cycle_count + 1;
      end
      done_d <= done;
      if (done && !done_d) begin
        $display("=================================");
        $display("CORE RV32IM EXECUTION COMPLETE!");
        $display("Total simulation cycles = %0d", cycle_count);
        $display("Total instructions retired = %0d", retired_inst_count);
        if (retired_inst_count > 0)
          $display("Final CPI = %0.3f", real'(cycle_count) / retired_inst_count);
        $display("=================================");
      end
    end
  end

endmodule
