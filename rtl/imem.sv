module IMem #(
    parameter int DEPTH_WORDS = 16384
    //parameter logic [31:0] BASE_ADDR = 32'h8000_0000
)(
    input  logic        rst_n,
    input  logic [31:0] addr,
    output logic [31:0] inst
);

    // Force Quartus infer block RAM
    (* ramstyle = "M10K" *)
    logic [31:0] inst_mem [0:DEPTH_WORDS - 1];

    logic [31:0] word_addr;

    assign word_addr = addr[31:2];   // word aligned
    //assign word_addr = (addr - BASE_ADDR) >> 2;
    //assign word_addr = addr >> 2;

    always_comb begin
        if (!rst_n)
            inst = 32'h00000013; // NOP
        else if (word_addr < DEPTH_WORDS)
//        else if (addr >= BASE_ADDR && word_addr < DEPTH_WORDS)
            inst = inst_mem[word_addr];
        else
            inst = 32'h00000013; // NOP
    end

//    // Load program
//    initial begin
//        $readmemh("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/fir_filter/fir2.hex", inst_mem);
//    end
//    initial begin
//        string program_path;
//    
//        if (!$value$plusargs("program=%s", program_path)) begin
//            $display("ERROR: No +program specified!");
//            $finish;
//        end
//    
//        $display("Loading program: %s", program_path);
//        $readmemh(program_path, inst_mem);
//    end
////initial begin
////    string path;
////    int file;
////
////    file = $fopen("../rtl/imem_path.txt", "r");
////
////    if (!file) begin
////        $display("ERROR: Cannot open imem_path.txt");
////        $finish;
////    end
////
////    $fgets(path, file);
////    $fclose(file);
////
////    // remove '\n'
////    if (path.len() > 0 && path[path.len()-1] == 8'h0A)
////        path = path.substr(0, path.len()-2);
////
////    // remove '\r'
////    if (path.len() > 0 && path[path.len()-1] == 8'h0D)
////        path = path.substr(0, path.len()-2);
////
////    $display("Loading instruction memory from: '%s'", path);
////
////    $readmemh(path, inst_mem);
////
////    $display("Instruction memory loaded.");
////end
endmodule
