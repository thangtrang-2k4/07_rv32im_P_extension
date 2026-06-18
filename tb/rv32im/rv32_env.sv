class rv32_env;
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
