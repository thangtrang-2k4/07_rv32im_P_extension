import os

def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

for core in ['rv32im', 'rv32imp']:
    base_dir = f'd:/01_Projects/2025-12_Graduation_Thesis/02-rv32im-pext/tb/{core}'
    os.makedirs(base_dir, exist_ok=True)
    
    # 1. rv32_if.sv
    if_sv = '''interface rv32_if (input logic clk, input logic rst_n);
  logic done;
  int cycle_count;
  int retired_inst_count;
  
  task load_imem(string path);
    $readmemh(path, tb_top.dut.u_imem.rom_array);
  endtask
  
  task load_dmem(string path);
    $readmemh(path, tb_top.dut.u_dmem.ram_array);
  endtask
  
  task dump_result(int depth, int base_addr, int o_addr, string path);
    int fd = $fopen(path, "w");
    int base = (o_addr - base_addr) >> 2;
    for (int i=0; i<depth; i++) begin
      $fdisplay(fd, "%08x", tb_top.dut.u_dmem.ram_array[base+i]);
    end
    $fclose(fd);
  endtask
endinterface
'''
    write_file(f'{base_dir}/rv32_if.sv', if_sv)

    # 2. rv32_trans.sv
    trans_sv = '''class rv32_trans;
  string imem_path;
  string dmem_path;
  string golden_path;
  string result_path;
  int depth;
  int OAddr;
  int BaseAddr = 32'h80010000;
endclass
'''
    write_file(f'{base_dir}/rv32_trans.sv', trans_sv)

    # 3. rv32_monitor.sv
    mon_sv = '''class rv32_monitor;
  virtual rv32_if vif;
  rv32_trans tr;
  
  function new(virtual rv32_if vif, rv32_trans tr);
    this.vif = vif;
    this.tr = tr;
  endfunction
  
  task run();
    wait(vif.done == 1'b1);
    #20;
    $display("=================================");
    $display("CORE EXECUTION COMPLETE!");
    $display("Total simulation cycles = %0d", vif.cycle_count);
    $display("Total instructions retired = %0d", vif.retired_inst_count);
    if (vif.retired_inst_count > 0)
      $display("Final CPI = %0.3f", real'(vif.cycle_count) / vif.retired_inst_count);
    $display("=================================");
  endtask
endclass
'''
    write_file(f'{base_dir}/rv32_monitor.sv', mon_sv)

    # 4. rv32_scoreboard.sv
    scb_sv = '''class rv32_scoreboard;
  virtual rv32_if vif;
  rv32_trans tr;
  logic [31:0] golden [];
  logic [31:0] result [];
  
  function new(virtual rv32_if vif, rv32_trans tr);
    this.vif = vif;
    this.tr = tr;
  endfunction
  
  task run();
    int error = 0;
    wait(vif.done == 1'b1);
    #25; 
    
    vif.dump_result(tr.depth, tr.BaseAddr, tr.OAddr, tr.result_path);
    
    golden = new[tr.depth];
    result = new[tr.depth];
    
    $readmemh(tr.golden_path, golden);
    $readmemh(tr.result_path, result);
    
    for (int i=0; i<tr.depth; i++) begin
      if (golden[i] !== result[i]) begin
        error++;
        $display("Mismatch at address %0h: expected %08x, got %08x", tr.OAddr + i*4, golden[i], result[i]);
      end else begin
        $display("Match at address %0h: expected %08x, got %08x", tr.OAddr + i*4, golden[i], result[i]);
      end
    end
    
    if (error == 0)
      $display("\\n >>> SCOREBOARD PASS <<< \\n");
    else
      $display("\\n >>> SCOREBOARD FAIL: %0d mismatches <<< \\n", error);
  endtask
endclass
'''
    write_file(f'{base_dir}/rv32_scoreboard.sv', scb_sv)

    # 5. rv32_env.sv
    env_sv = '''class rv32_env;
  rv32_monitor mon;
  rv32_scoreboard scb;
  virtual rv32_if vif;
  rv32_trans tr;
  
  function new(virtual rv32_if vif, rv32_trans tr);
    this.vif = vif;
    this.tr = tr;
    mon = new(vif, tr);
    scb = new(vif, tr);
  endfunction
  
  task run();
    fork
      mon.run();
      scb.run();
    join
  endtask
endclass
'''
    write_file(f'{base_dir}/rv32_env.sv', env_sv)

    # 6. rv32_test.sv
    test_sv = '''class rv32_test;
  rv32_env env;
  rv32_trans tr;
  virtual rv32_if vif;
  
  function new(virtual rv32_if vif);
    this.vif = vif;
    tr = new();
  endfunction
  
  task build();
    if (!$value$plusargs("IMEM=%s", tr.imem_path)) $fatal(1, "Missing +IMEM");
    if (!$value$plusargs("DMEM=%s", tr.dmem_path)) $fatal(1, "Missing +DMEM");
    if (!$value$plusargs("GOLDEN=%s", tr.golden_path)) $fatal(1, "Missing +GOLDEN");
    if (!$value$plusargs("RESULT=%s", tr.result_path)) $fatal(1, "Missing +RESULT");
    if (!$value$plusargs("DEPTH=%d", tr.depth)) $fatal(1, "Missing +DEPTH");
    if (!$value$plusargs("OADDR=%x", tr.OAddr)) $fatal(1, "Missing +OADDR");
    
    env = new(vif, tr);
  endtask
  
  task run();
    vif.load_imem(tr.imem_path);
    vif.load_dmem(tr.dmem_path);
    env.run();
  endtask
endclass
'''
    write_file(f'{base_dir}/rv32_test.sv', test_sv)

    # 7. tb_top.sv
    top_sv = f'''`timescale 1ns/1ps

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
  
  {core}_pipeline #(
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
'''
    write_file(f'{base_dir}/tb_top.sv', top_sv)

print('All SV OOP files generated for rv32im and rv32imp.')
