`timescale 1ns/1ps

module tb_rv32imp_pipeline;
  logic clk;
  logic rst_n;

  rv32imp_pipeline #(
      .DEPTH_WORDS(524288)
  ) dut (
    .clk(clk),
    .rst_n(rst_n)

    //input  logic [7:0] sw,
    //output logic [7:0] led

    // single_cycle.sv: khai báo port
    //output logic [31:0] a0_out
    //output logic [31:0] debug_pc
  );

  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  initial begin

    logic [31:0] golden [13];
    logic [31:0] result [13];

    int error;

    #10;
    load_prog("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/p_ext_byte/pext_byte.hex");
    load_golden("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/p_ext_byte/golden.hex", golden);

    #1000000;
    dump_result("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/p_ext_byte/result.hex");
    load_result("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/p_ext_byte/result.hex", result);
    #1;
    compare_result(golden, result, error);
    if (error == 0)
      $display(" PASS");
    else
      $display(" FAIL: %0d mismatches", error);
    $finish;
  end
  task load_prog (input string prog_path);
    $readmemh(prog_path, dut.u_imem.inst_mem);
  endtask

  task load_golden (input string golden_path, output logic [31:0] golden_o []);
    $readmemh(golden_path, golden_o);
  endtask
//  task dump_result (input string result_path);
//    
//      int fd;
//      int base;
//      base = 1024; // 🔥 đúng mapping
//    
//      fd = $fopen(result_path, "w");
//    
//      for (int i = 0; i < 16; i++) begin
//        $fdisplay(fd, "%08x", dut.u_dmem.mem[base + i]);
//      end
//    
//      $fclose(fd);
//    
//  endtask
  task dump_result (input string result_path);
  
    int fd;
  //  int base;
//    base = 304; // 🔥 mapping address → index
  int base;
base = 32'h00000130 >> 2;
    fd = $fopen(result_path, "w");
  
    for (int i = 0; i < 13; i++) begin
      $fdisplay(fd, "%h", dut.u_dmem.mem[base + i]);
    end
  
    $fclose(fd);
  
  endtask

  task load_result (input string result_path, output logic [31:0] result_o []);
    $readmemh(result_path, result_o);
  endtask

  task compare_result (input logic [31:0] golden [], input logic [31:0] result [], output int num_mismatch);
    num_mismatch = 0;
    for (int i = 0; i < 13; i++) begin
      if (golden[i] !== result[i]) begin
        num_mismatch++;
        $display("Mismatch at address %0h: expected %h, got %h", 32'h800000e0 + i*4, golden[i], result[i]);
      end
      else begin 
        $display("Match at address %0h: expected %h, got %h", 32'h800000e0 + i*4, golden[i], result[i]);
      end
    end
  endtask
endmodule
