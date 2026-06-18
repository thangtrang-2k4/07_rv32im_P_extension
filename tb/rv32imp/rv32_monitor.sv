class rv32_monitor;
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
