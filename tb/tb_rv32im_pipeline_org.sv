`timescale 1ns/1ps

module tb_rv32imp_pipeline;
  
  logic clk;
  logic rst_n;
  
  rv32imp_pipeline #(
    .DEPTH_WORDS(2048)
  ) dut (
    .clk(clk),  
    .rst_n(rst_n)
  
    //input  logic [7:0] sw,
    //output logic [7:0] led

    // single_cycle.sv: khai báo port
    //output logic [31:0] a0_out

  );

  initial clk = '0;

  always #5 clk = ~clk;
  
  initial begin 
    clk = 0;
    rst_n =0;
    #10 rst_n = 1;
    #1200 $finish;
  end

endmodule
