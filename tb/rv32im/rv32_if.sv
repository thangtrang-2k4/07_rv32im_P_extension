interface rv32_if (input logic clk, input logic rst_n);
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
