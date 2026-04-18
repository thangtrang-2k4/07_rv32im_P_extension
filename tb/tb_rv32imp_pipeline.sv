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

    logic [31:0] golden [7];
    logic [31:0] result [7];

    int error;

    #10;
    load_imem("../sw/Filter-Sobel/imem.hex");
    load_dmem("../sw/Filter-Sobel/dmem.hex");

    load_golden("../sw/Filter-Sobel/golden1.hex", golden);

    #1000000;
    dump_result("../sw/Filter-Sobel/signature.hex");
    load_result("../sw/Filter-Sobel/signature.hex", result);
    #1;
    compare_result(golden, result, error);
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
  task dump_result (input string result_path);
  
    int fd;
    int base;
    
    // Ánh xạ địa chỉ (addr) sang chỉ số mảng (word_addr) dựa quy tắc trong data_memory.sv:
    // word_addr = (addr - BASE_ADDR) >> 2
    // Với addr = 32'h8001_001C, BASE_ADDR = 32'h8001_0000
    base = (32'h8001001C - 32'h80010000) >> 2;
    
    fd = $fopen(result_path, "w");
  
    // Khối output có kích thước là 0x19 byte (25 bytes), tương đương 7 words (7 * 4 = 28 bytes)
    for (int i = 0; i < 7; i++) begin
      $fdisplay(fd, "%08x", dut.u_dmem.ram_array[base + i]);
    end
  
    $fclose(fd);
  
  endtask

  task load_result (input string result_path, output logic [31:0] result_o []);
    $readmemh(result_path, result_o);
  endtask

  task compare_result (input logic [31:0] golden [], input logic [31:0] result [], output int num_mismatch);
    num_mismatch = 0;
    for (int i = 0; i < 7; i++) begin
      if (golden[i] !== result[i]) begin
        num_mismatch++;
        $display("Mismatch at address %0h: expected %08x, got %08x", 32'h8001001C + i*4, golden[i], result[i]);
      end
      else begin 
        $display("Match at address %0h: expected %08x, got %08x", 32'h8001001C + i*4, golden[i], result[i]);
      end
    end
  endtask
endmodule



//`timescale 1ns/1ps
//
//module tb_rv32imp_pipeline;
//
//  logic clk;
//  logic rst_n;
//
//  rv32imp_pipeline #(
//      .DEPTH_WORDS(524288)
//  ) dut (
//    .clk(clk),
//    .rst_n(rst_n)
//  );
//
//  // CLOCK
//  initial clk = 0;
//  always #5 clk = ~clk;
//
//  // RESET
//  initial begin
//    rst_n = 0;
//    #20 rst_n = 1;
//  end
//
//  // =========================
//  // MAIN TEST
//  // =========================
//  initial begin
//
//    logic [31:0] golden [200];
//    logic [31:0] result [200];
//    int error;
//
//    // -------- LOAD --------
//    #10;
//    load_golden("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/fir_filter/golden1.hex", golden);
//
//    // -------- RUN --------
//    #1000000;   // đủ để chạy xong FIR
//
//    // -------- DUMP --------
//    dump_result("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/fir_filter/result.hex");
//
//    // -------- CHECK --------
//    load_result("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/fir_filter/result.hex", result);
//    #1;
//    compare_result(golden, result, error);
//
//    if (error == 0)
//      $display("✅ PASS");
//    else
//      $display("❌ FAIL: %0d mismatches", error);
//
//    $finish;
//  end
//
//
//  // =========================
//  // LOAD GOLDEN
//  // =========================
//  task load_golden (input string path, output logic [31:0] golden_o []);
//    $readmemh(path, golden_o);
//  endtask
//
//  // =========================
//  // DUMP RESULT
//  // =========================
//  task dump_result (input string path);
//    int fd;
//    int base;
//
//    base = 232;  // 👉 output bắt đầu từ mem[8]
//
//    fd = $fopen(path, "w");
//
//    for (int i = 0; i < 200; i++) begin
//      $fdisplay(fd, "%08x", dut.u_dmem.mem[base + i]);
//    end
//
//    $fclose(fd);
//
//    $display("Result dumped!");
//  endtask
//
//  // =========================
//  // LOAD RESULT
//  // =========================
//  task load_result (input string path, output logic [31:0] result_o []);
//    $readmemh(path, result_o);
//  endtask
//
//  // =========================
//  // COMPARE
//  // =========================
//  task compare_result (
//    input logic [31:0] golden [],
//    input logic [31:0] result [],
//    output int num_mismatch
//  );
//    num_mismatch = 0;
//
//    for (int i = 0; i < 200; i++) begin
//      if (golden[i] !== result[i]) begin
//        num_mismatch++;
//        $display("Mismatch [%0d]: expected %h, got %h",
//                 i, golden[i], result[i]);
//      end
//      else $display("Match [%0d]: expected %h, got %h",
//                 i, golden[i], result[i]);
//    end
//  endtask
//
//  int cycle_count;
//  bit running;
//  bit done;
//  bit done_d;   // giữ trạng thái trước
//  
//  always @(posedge clk or negedge rst_n) begin
//    if (!rst_n) begin
//      cycle_count <= 0;
//      running <= 0;
//      done <= 0;
//      done_d <= 0;
//    end
//    else begin
//      running <= 1;
//  
//      // detect done
//     if (^dut.u_dmem.mem[232 + 199] !== 1'bx &&
//    dut.u_dmem.mem[232 + 199] != 0)
//  done <= 1; 
//
//      // đếm cycle
//      if (running && !done)
//        cycle_count <= cycle_count + 1;
//  
//      // lưu trạng thái cũ
//done_d <= done;
//  
//      // 🔥 IN RA 1 LẦN DUY NHẤT
//      if (done && !done_d) begin
//        $display("=================================");
//        $display("FIR DONE!");
//        $display("Total cycles = %0d", cycle_count);
//        $display("=================================");
//      end
//    end
//  end
//  
////  // =========================
////  // DEBUG (rất hữu ích)
////  // =========================
////  always @(posedge clk) begin
////    if (rst_n) begin
////      $display("OUT = %0d %0d %0d %0d",
////        dut.u_dmem.mem[232],
////        dut.u_dmem.mem[233],
////        dut.u_dmem.mem[234],
////        dut.u_dmem.mem[235]);
////    end
////  end
//
//endmodule
