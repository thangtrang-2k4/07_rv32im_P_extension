module Data_Memory #(
    parameter int DEPTH_WORDS = 16384
    //parameter logic [31:0] BASE_ADDR = 32'h8000_0000
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] addr,
    input  logic [31:0] dataW,
    input  logic        MemRW,        // 1 = write, 0 = read
    input  logic [1:0]  MemSize,      // 00=byte, 01=half, 10=word
    input  logic        MemUnsigned,  // load unsigned
    output logic [31:0] dataR
);

    // Force Block RAM inference
    (* ramstyle = "M10K" *)
    logic [31:0] mem [0:DEPTH_WORDS-1];

    logic [31:0] word;
    logic [31:0] word_addr;
    logic [1:0]  byte_offset;


    logic [7:0] selected_byte;
    logic [15:0] selected_half;

    assign word_addr   = addr[31:2];
    //assign byte_offset = addr[1:0];
    //assign word_addr   = (addr - BASE_ADDR) >> 2;
    //assign word_addr   = addr >> 2;
    assign byte_offset = addr[1:0];

    // ---------------- READ ----------------
    always_comb begin
        //if (addr >= BASE_ADDR && word_addr < DEPTH_WORDS)
        if (word_addr < DEPTH_WORDS)
            word = mem[word_addr];
        else
            word = 32'b0;

        if (!MemRW) begin
            case (MemSize)

                // -------- LB / LBU --------
                2'b00: begin
                    case (byte_offset)
                        2'b00: selected_byte = word[7:0];
                        2'b01: selected_byte = word[15:8];
                        2'b10: selected_byte = word[23:16];
                        2'b11: selected_byte = word[31:24];
                    endcase

                    dataR = MemUnsigned
                            ? {24'b0, selected_byte}
                            : {{24{selected_byte[7]}}, selected_byte};
                end

                // -------- LH / LHU --------
                2'b01: begin

                    if (byte_offset[1] == 1'b0)
                        selected_half = word[15:0];
                    else
                        selected_half = word[31:16];

                    dataR = MemUnsigned
                            ? {16'b0, selected_half}
                            : {{16{selected_half[15]}}, selected_half};
                end

                // -------- LW --------
                2'b10: begin
                    dataR = word;
                end

                default: dataR = 32'b0;
            endcase
        end
        else begin
            dataR = 32'b0;
        end
    end

    // ---------------- WRITE ----------------
    always_ff @(posedge clk) begin
        //if (MemRW && addr >= BASE_ADDR && word_addr < DEPTH_WORDS) begin
          if (MemRW && word_addr < DEPTH_WORDS) begin

            case (MemSize)
    
                2'b00: begin
                    case (byte_offset)
                        2'b00: mem[word_addr][7:0]   <= dataW[7:0];
                        2'b01: mem[word_addr][15:8]  <= dataW[7:0];
                        2'b10: mem[word_addr][23:16] <= dataW[7:0];
                        2'b11: mem[word_addr][31:24] <= dataW[7:0];
                    endcase
                end
    
                2'b01: begin
                    if (byte_offset[1] == 1'b0)
                        mem[word_addr][15:0]  <= dataW[15:0];
                    else
                        mem[word_addr][31:16] <= dataW[15:0];
                end
    
                2'b10: mem[word_addr] <= dataW;
    
            endcase
        end
    end
    initial begin
         $readmemh("/home/trangthang/Workspace/02_Project/01_GitHub/07_rv32im_P_extension/sw/fir_filter/dmem2.hex", mem);
    end
//    always_ff @(posedge clk) begin
//        if (MemRW && (word_addr < DEPTH_WORDS)) begin
//        //if (MemRW && addr >= BASE_ADDR && word_addr < DEPTH_WORDS) begin
//            case (MemSize)
//
//                // -------- SB --------
//                2'b00: begin
//                    case (byte_offset)
//                        2'b00: mem[word_addr][7:0]   <= dataW[7:0];
//                        2'b01: mem[word_addr][15:8]  <= dataW[7:0];
//                        2'b10: mem[word_addr][23:16] <= dataW[7:0];
//                        2'b11: mem[word_addr][31:24] <= dataW[7:0];
//                    endcase
//                end
//
//                // -------- SH --------
//                2'b01: begin
//                    if (byte_offset[1] == 1'b0)
//                        mem[word_addr][15:0]  <= dataW[15:0];
//                    else
//                        mem[word_addr][31:16] <= dataW[15:0];
//                end
//
//                // -------- SW --------
//                2'b10: begin
//                    mem[word_addr] <= dataW;
//                end
//
//            endcase
//        end
//    end
//final begin
//    int fd;
//    fd = $fopen("DUT-rv32im_core.signature", "w");
//
//    for (int i = 0; i < 256; i++) begin
//        $fdisplay(fd, "%08x", mem[i]);
//    end
//
//    $fclose(fd);
//end
//    initial begin
//        for (int i = 0; i < DEPTH_WORDS; i++)
//            mem[i] = 32'hDEADBEEF;;
//    end
endmodule
