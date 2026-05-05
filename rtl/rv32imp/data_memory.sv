module Data_Memory #(
    parameter int DEPTH_WORDS = 16384,
    parameter logic [31:0] BASE_ADDR = 32'h8001_0000
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

    // ----------------------------------------------------------------
    // Force Block RAM (M10K) inference.
    // Key rules for Quartus to infer M10K with byte-enable:
    //   1. Write must be registered (always_ff).
    //   2. Sub-word writes must use per-byte if-enable, NOT bit-slice assign.
    //   3. Read must be registered (always_ff).
    //   4. No range-check conditions on the address inside the RAM access.
    // ----------------------------------------------------------------
    (* ramstyle = "M10K" *)
    logic [7:0] ram_b0 [0:DEPTH_WORDS-1];   // Byte 0 (bits  7: 0)
    (* ramstyle = "M10K" *)
    logic [7:0] ram_b1 [0:DEPTH_WORDS-1];   // Byte 1 (bits 15: 8)
    (* ramstyle = "M10K" *)
    logic [7:0] ram_b2 [0:DEPTH_WORDS-1];   // Byte 2 (bits 23:16)
    (* ramstyle = "M10K" *)
    logic [7:0] ram_b3 [0:DEPTH_WORDS-1];   // Byte 3 (bits 31:24)

    // ---- Address decode ----
    logic [$clog2(DEPTH_WORDS)-1:0] word_addr;
    logic [1:0]  byte_offset;
    logic [1:0]  byte_offset_q;   // registered alongside read data

    assign word_addr   = (addr - BASE_ADDR) >> 2;
    assign byte_offset = addr[1:0];

    // ---- Byte-enable generation ----
    logic [3:0]  be;
    logic [7:0]  wdata_b0, wdata_b1, wdata_b2, wdata_b3;

    always_comb begin
        be       = 4'b0000;
        wdata_b0 = dataW[7:0];
        wdata_b1 = dataW[15:8];
        wdata_b2 = dataW[23:16];
        wdata_b3 = dataW[31:24];

        case (MemSize)
            2'b00: begin // Byte
                case (byte_offset)
                    2'b00: begin be = 4'b0001; wdata_b0 = dataW[7:0]; end
                    2'b01: begin be = 4'b0010; wdata_b1 = dataW[7:0]; end
                    2'b10: begin be = 4'b0100; wdata_b2 = dataW[7:0]; end
                    2'b11: begin be = 4'b1000; wdata_b3 = dataW[7:0]; end
                    default: be = 4'b0000;
                endcase
            end
            2'b01: begin // Half-word
                if (byte_offset[1] == 1'b0) begin
                    be       = 4'b0011;
                    wdata_b0 = dataW[7:0];
                    wdata_b1 = dataW[15:8];
                end else begin
                    be       = 4'b1100;
                    wdata_b2 = dataW[7:0];
                    wdata_b3 = dataW[15:8];
                end
            end
            2'b10: begin // Word
                be = 4'b1111;
            end
            default: be = 4'b0000;
        endcase
    end

    // ---- WRITE: registered, per-byte enable ----
    always_ff @(posedge clk) begin
        if (MemRW) begin
            if (be[0]) ram_b0[word_addr] <= wdata_b0;
            if (be[1]) ram_b1[word_addr] <= wdata_b1;
            if (be[2]) ram_b2[word_addr] <= wdata_b2;
            if (be[3]) ram_b3[word_addr] <= wdata_b3;
        end
    end

    // ---- READ: registered (required for M10K inference) ----
    logic [7:0] rdata_b0, rdata_b1, rdata_b2, rdata_b3;

    always_ff @(posedge clk) begin
        rdata_b0    <= ram_b0[word_addr];
        rdata_b1    <= ram_b1[word_addr];
        rdata_b2    <= ram_b2[word_addr];
        rdata_b3    <= ram_b3[word_addr];
        byte_offset_q <= byte_offset;   // latch offset alongside data
    end

    // ---- Output decode (combinational from registered data) ----
    always_comb begin
        dataR = 32'b0;
        case (MemSize)
            2'b00: begin
                logic [7:0] b;
                case (byte_offset_q)
                    2'b00:   b = rdata_b0;
                    2'b01:   b = rdata_b1;
                    2'b10:   b = rdata_b2;
                    2'b11:   b = rdata_b3;
                    default: b = 8'b0;
                endcase
                dataR = MemUnsigned ? {24'b0, b} : {{24{b[7]}}, b};
            end
            2'b01: begin
                logic [15:0] h;
                h = byte_offset_q[1]
                    ? {rdata_b3, rdata_b2}
                    : {rdata_b1, rdata_b0};
                dataR = MemUnsigned ? {16'b0, h} : {{16{h[15]}}, h};
            end
            2'b10: dataR = {rdata_b3, rdata_b2, rdata_b1, rdata_b0};
            default: dataR = 32'b0;
        endcase
    end

    // ---- Initialisation ----
    initial begin
        $readmemh("../../sw/Filter-Fir/scala_dmem.hex", ram_b0);
        $readmemh("../../sw/Filter-Fir/scala_dmem.hex", ram_b1);
        $readmemh("../../sw/Filter-Fir/scala_dmem.hex", ram_b2);
        $readmemh("../../sw/Filter-Fir/scala_dmem.hex", ram_b3);
    end

endmodule
