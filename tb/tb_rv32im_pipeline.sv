timescale 1ns/1ps

module tb_rv32imp_pipeline;
  logic clk;
  logic rst_n;

  rv32imp_pipeline dut #(
      .DEPTH_WORDS(524288)
  )(
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

  task load_prog (input string prog_path);
    $readmemh(prog_path, dut.imem.inst_mem);
  endtask

  task load_golden (input string golden_path, output logic [31:0] golden_o [])
    $readmemh(golden_path, golden_o);
  endtask

  task dump_result (input string result_path);
    $writememh(result_path, dut.data_memory.mem);
  endtask

  task load_result (input string result_path, output logic [31:0] result_o []);
    $readmemh(result_path, result_o);
  endtask

  task compare_result (input logic [31:0] golden [], input logic [31:0] result [], output int num_mismatch);
    num_mismatch = 0;
    for (int i = 0; i < 16; i++) begin
      if (golden[i] !== result[i]) begin
        num_mismatch++;
        $display("Mismatch at address %0d: expected %h, got %h", i*4, golden[i], result[i]);
      end
    end
  endtask
endmodule