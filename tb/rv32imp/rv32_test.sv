class rv32_test;
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
