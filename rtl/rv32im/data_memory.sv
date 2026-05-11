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
    logic [31:0] ram_array [0:DEPTH_WORDS-1];

    // ---- Address decode ----
    logic [$clog2(DEPTH_WORDS)-1:0] word_addr;
    logic [1:0]  byte_offset;
    logic [1:0]  byte_offset_q;   // registered alongside read data

    assign word_addr   = (addr - BASE_ADDR) >> 2;
    assign byte_offset = addr[1:0];

    // ---- Byte-enable generation ----
    logic [3:0]  be;

    always_comb begin
        be = 4'b0000;
        case (MemSize)
            2'b00: begin // Byte
                case (byte_offset)
                    2'b00: be = 4'b0001;
                    2'b01: be = 4'b0010;
                    2'b10: be = 4'b0100;
                    2'b11: be = 4'b1000;
                    default: be = 4'b0000;
                endcase
            end
            2'b01: begin // Half-word
                if (byte_offset[1] == 1'b0) begin
                    be = 4'b0011;
                end else begin
                    be = 4'b1100;
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
            if (be[0]) ram_array[word_addr][ 7: 0] <= dataW[ 7: 0];
            if (be[1]) ram_array[word_addr][15: 8] <= (MemSize == 2'b00) ? dataW[7:0] : dataW[15:8];
            if (be[2]) ram_array[word_addr][23:16] <= (MemSize == 2'b00) ? dataW[7:0] : (MemSize == 2'b01) ? dataW[7:0] : dataW[23:16];
            if (be[3]) ram_array[word_addr][31:24] <= (MemSize == 2'b00) ? dataW[7:0] : (MemSize == 2'b01) ? dataW[15:8] : dataW[31:24];
        end
    end

    // ---- READ: registered (required for M10K inference) ----
    logic [31:0] rdata;

    always_ff @(posedge clk) begin
        rdata         <= ram_array[word_addr];
        byte_offset_q <= byte_offset;   // latch offset alongside data
    end

    // ---- Output decode (combinational from registered data) ----
    always_comb begin
        dataR = 32'b0;
        case (MemSize)
            2'b00: begin
                logic [7:0] b;
                case (byte_offset_q)
                    2'b00:   b = rdata[7:0];
                    2'b01:   b = rdata[15:8];
                    2'b10:   b = rdata[23:16];
                    2'b11:   b = rdata[31:24];
                    default: b = 8'b0;
                endcase
                dataR = MemUnsigned ? {24'b0, b} : {{24{b[7]}}, b};
            end
            2'b01: begin
                logic [15:0] h;
                h = byte_offset_q[1]
                    ? rdata[31:16]
                    : rdata[15:0];
                dataR = MemUnsigned ? {16'b0, h} : {{16{h[15]}}, h};
            end
            2'b10: dataR = rdata;
            default: dataR = 32'b0;
        endcase
    end

    // ---- Initialisation ----
    initial begin
        $readmemh("../../sw/Filter-Fir/scala_dmem.hex", ram_array);
    end

endmodule
