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





  int cycle_count;
  bit running;
  bit done;
  bit done_d;

  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  localparam int depth      = 1024;
  localparam int BaseAddr   = 32'h80010000;
  localparam int OAddr      = 32'h80011000;
  localparam int DoneAddr   = 32'h8001fffc;
  localparam int DONE_INDEX = (DoneAddr - BaseAddr) >> 2;

  initial begin
    logic [31:0] golden [depth];
    logic [31:0] result [depth];
    int error;

    #10;
    load_imem("../sw/Filter-Sobel/scala_imem.hex");
    load_dmem("../sw/Filter-Sobel/scala_dmem.hex");

    load_golden("../sw/Filter-Sobel/scala_goldenw.hex", golden);

    // Chờ cho cờ done_flag = 1 từ file scala.c đánh dấu kết thúc
    wait (done == 1'b1);
    #20;

    dump_result(depth, BaseAddr, OAddr, "../sw/Filter-Sobel/scala_signature.hex");
    load_result("../sw/Filter-Sobel/scala_signature.hex", result);
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
  task dump_result (int depth, int BaseAddr, int OAddr, input string result_path);
  
    int fd;
    int base;
    
    // Ánh xạ địa chỉ (addr) sang chỉ số mảng (word_addr) dựa quy tắc trong data_memory.sv:
    // word_addr = (addr - BASE_ADDR) >> 2
    // Với addr = 32'h8001_001C, BASE_ADDR = 32'h8001_0000
    base = (OAddr - BaseAddr) >> 2;
    
    fd = $fopen(result_path, "w");
  
    // Khối output có kích thước là 0x19 byte (25 bytes), tương đương 7 words (7 * 4 = 28 bytes)
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
      running <= 0;
      done <= 0;
      done_d <= 0;
    end
    else begin
      running <= 1;

      // Detect done flag memory write 
      // Địa chỉ done_flag = 0x80011000, Data Memory BASE_ADDR = 0x80010000
      // => word index = (0x80011000 - 0x80010000) >> 2 = 1024
      if (dut.u_dmem.ram_array[DONE_INDEX] == 32'h1) begin
         done <= 1;
      end

      // Đếm chu kỳ
      if (running && !done) begin
        cycle_count <= cycle_count + 1;
      end

      // Lưu trạng thái
      done_d <= done;

      // Báo cáo chu kỳ khi hoàn thành
      if (done && !done_d) begin
        $display("=================================");
        $display("SOBEL FILTER COMPLETE!");
        $display("Total simulation cycles = %0d", cycle_count);
        $display("=================================");
      end
    end
  end

endmodule
