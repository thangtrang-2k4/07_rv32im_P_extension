`timescale 1ns/1ps

module tb_rv32imp_signature;
  import rv32_pkg::*;

  localparam int IMEM_WORDS = 4096;
  localparam int DMEM_WORDS = 4096;
  localparam int MAX_SIG_WORDS = 1024;
  localparam logic [31:0] DMEM_BASE = 32'h8001_0000;
  localparam logic [31:0] DONE_ADDR = 32'h8001_3ffc;
  localparam int DONE_INDEX = (DONE_ADDR - DMEM_BASE) >> 2;

  logic clk;
  logic rst_n;

  rv32imp_pipeline #(
      .IMEM_DEPTH(IMEM_WORDS),
      .DMEM_DEPTH(DMEM_WORDS)
  ) dut (
      .clk(clk),
      .rst_n(rst_n)
  );

  string imem_path = "";
  string dmem_path = "none";
  string golden_path = "";
  string result_path = "result.hex";
  int sig_words = 1;
  logic [31:0] sig_addr = DMEM_BASE;

  logic [31:0] golden [0:MAX_SIG_WORDS-1];
  logic [31:0] result [0:MAX_SIG_WORDS-1];

  int cycle_count;
  int retired_inst_count;
  bit running;
  bit done;
  bit done_d;

  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    int error;
    int fd;
    int base_index;

    rst_n = 1'b0;
    #1;

    if (!$value$plusargs("IMEM=%s", imem_path))
      $fatal(1, "Missing +IMEM=<path>");
    void'($value$plusargs("DMEM=%s", dmem_path));
    if (!$value$plusargs("GOLDEN=%s", golden_path))
      $fatal(1, "Missing +GOLDEN=<path>");
    void'($value$plusargs("RESULT=%s", result_path));
    void'($value$plusargs("SIG_WORDS=%d", sig_words));
    void'($value$plusargs("SIG_ADDR=%h", sig_addr));

    if (sig_words <= 0 || sig_words > MAX_SIG_WORDS)
      $fatal(1, "SIG_WORDS out of range: %0d", sig_words);

    for (int i = 0; i < IMEM_WORDS; i++) begin
      dut.u_imem.rom_array[i] = 32'h00000013;
    end
    for (int i = 0; i < DMEM_WORDS; i++) begin
      dut.u_dmem.ram_array[i] = 32'h00000000;
    end
    for (int i = 0; i < MAX_SIG_WORDS; i++) begin
      golden[i] = 32'hxxxx_xxxx;
      result[i] = 32'hxxxx_xxxx;
    end

    $readmemh(imem_path, dut.u_imem.rom_array);
    if (dmem_path != "none")
      $readmemh(dmem_path, dut.u_dmem.ram_array);
    $readmemh(golden_path, golden);

    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    wait (done == 1'b1);
    repeat (5) @(posedge clk);

    base_index = (sig_addr - DMEM_BASE) >> 2;
    fd = $fopen(result_path, "w");
    if (fd == 0)
      $fatal(1, "Cannot open result file: %s", result_path);

    for (int i = 0; i < sig_words; i++) begin
      result[i] = dut.u_dmem.ram_array[base_index + i];
      $fdisplay(fd, "%08x", result[i]);
    end
    $fclose(fd);

    error = 0;
    for (int i = 0; i < sig_words; i++) begin
      if (golden[i] !== result[i]) begin
        error++;
        $display("Mismatch[%0d] @ %08x: expected %08x, got %08x",
                 i, sig_addr + i*4, golden[i], result[i]);
      end else begin
        $display("Match[%0d] @ %08x: %08x", i, sig_addr + i*4, result[i]);
      end
    end

    if (error == 0)
      $display("PASS: %0d signature words matched", sig_words);
    else
      $fatal(1, "FAIL: %0d signature mismatches", error);

    $finish;
  end

  initial begin
    repeat (200000) @(posedge clk);
    if (!done)
      $fatal(1, "Timeout waiting for done flag");
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_count <= 0;
      retired_inst_count <= 0;
      running <= 1'b0;
      done <= 1'b0;
      done_d <= 1'b0;
    end else begin
      running <= 1'b1;

      if (dut.ctrl_WB != CTRL_NOP)
        retired_inst_count <= retired_inst_count + 1;

      if (dut.u_dmem.ram_array[DONE_INDEX] == 32'h1)
        done <= 1'b1;

      if (running && !done)
        cycle_count <= cycle_count + 1;

      done_d <= done;
      if (done && !done_d) begin
        $display("=================================");
        $display("CORE RV32IMP SIGNATURE TEST DONE");
        $display("Total simulation cycles = %0d", cycle_count);
        $display("Total instructions retired = %0d", retired_inst_count);
        if (retired_inst_count > 0)
          $display("Final CPI = %0.3f", real'(cycle_count) / retired_inst_count);
        $display("=================================");
      end
    end
  end
endmodule
