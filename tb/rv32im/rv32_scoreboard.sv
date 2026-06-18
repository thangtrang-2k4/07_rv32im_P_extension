class rv32_scoreboard;
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
      $display("\n >>> SCOREBOARD PASS <<< \n");
    else
      $display("\n >>> SCOREBOARD FAIL: %0d mismatches <<< \n", error);
  endtask
endclass
