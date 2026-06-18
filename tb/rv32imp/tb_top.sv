`timescale 1ns/1ps

`include "rv32_if.sv"
`include "rv32_trans.sv"
`include "rv32_monitor.sv"
`include "rv32_scoreboard.sv"
`include "rv32_env.sv"
`include "rv32_test.sv"

module tb_top;
  import rv32_pkg::*;

  logic clk;
  logic rst_n;
  
  rv32_if vif(clk, rst_n);
  
  rv32imp_pipeline #(
      .IMEM_DEPTH(256),
      .DMEM_DEPTH(4096)
  ) dut (
    .clk(clk),
    .rst_n(rst_n)
  );

  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end
  
  localparam int BaseAddr   = 32'h80010000;
  localparam int DoneAddr   = 32'h80013ffc; 
  localparam int DONE_INDEX = (DoneAddr - BaseAddr) >> 2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      vif.cycle_count <= 0;
      vif.retired_inst_count <= 0;
      vif.done <= 0;
    end else begin
      if (dut.ctrl_WB != CTRL_NOP) begin
        vif.retired_inst_count <= vif.retired_inst_count + 1;
      end
      if (dut.u_dmem.ram_array[DONE_INDEX] == 32'h1) begin
         vif.done <= 1;
      end
      if (!vif.done) begin
        vif.cycle_count <= vif.cycle_count + 1;
      end
    end
  end

  initial begin
    rv32_test t;
    #1;
    t = new(vif);
    t.build();
    t.run();
    $finish;
  end

endmodule
