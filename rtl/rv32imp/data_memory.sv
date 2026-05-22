module Data_Memory #(
    parameter int DEPTH_WORDS = 16384,
    parameter logic [31:0] BASE_ADDR = 32'h8001_0000,
    parameter string INIT_FILE = ""
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        i_stb,
    input  logic        i_we,         // 1 = write, 0 = read
    input  logic [31:0] i_addr,
    input  logic [31:0] i_wdata,
    input  logic [1:0]  i_size,       // 00=byte, 01=half, 10=word
    input  logic        i_unsigned,   // load unsigned
    output logic        o_ack,
    output logic [31:0] o_rdata
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
    localparam int ADDR_BITS = $clog2(DEPTH_WORDS);

    logic [ADDR_BITS-1:0] word_addr;
    logic [1:0]  byte_offset;
    logic [1:0]  byte_offset_q;   // registered alongside read data

    assign word_addr   = i_addr[ADDR_BITS+1:2] - BASE_ADDR[ADDR_BITS+1:2];
    assign byte_offset = i_addr[1:0];

    // ---- Byte-enable generation ----
    logic [3:0]  be;

    always_comb begin
        be = 4'b0000;
        case (i_size)
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
        if (i_stb && i_we) begin
            if (be[0]) ram_array[word_addr][ 7: 0] <= i_wdata[ 7: 0];
            if (be[1]) ram_array[word_addr][15: 8] <= (i_size == 2'b00) ? i_wdata[7:0] : i_wdata[15:8];
            if (be[2]) ram_array[word_addr][23:16] <= (i_size == 2'b00) ? i_wdata[7:0] : (i_size == 2'b01) ? i_wdata[7:0] : i_wdata[23:16];
            if (be[3]) ram_array[word_addr][31:24] <= (i_size == 2'b00) ? i_wdata[7:0] : (i_size == 2'b01) ? i_wdata[15:8] : i_wdata[31:24];
        end
    end

    // ---- READ: registered (required for M10K inference) ----
    logic [31:0] rdata;
    logic [1:0]  MemSize_q;
    logic        MemUnsigned_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_ack         <= 1'b0;
            byte_offset_q <= 2'b0;
            MemSize_q     <= 2'b0;
            MemUnsigned_q <= 1'b0;
        end else begin
            o_ack <= i_stb;
            if (i_stb) begin
                byte_offset_q <= byte_offset;   // latch offset alongside data
                MemSize_q     <= i_size;        // latch size to match data latency
                MemUnsigned_q <= i_unsigned;    // latch sign extension flag
            end
        end
    end

    // M10K inference requires read register to NOT have async reset
    always_ff @(posedge clk) begin
        if (i_stb) begin
            rdata <= ram_array[word_addr];
        end
    end

    // ---- Output decode (combinational from registered data) ----
    always_comb begin
        o_rdata = 32'b0;
        case (MemSize_q)
            2'b00: begin
                logic [7:0] b;
                case (byte_offset_q)
                    2'b00:   b = rdata[7:0];
                    2'b01:   b = rdata[15:8];
                    2'b10:   b = rdata[23:16];
                    2'b11:   b = rdata[31:24];
                    default: b = 8'b0;
                endcase
                o_rdata = MemUnsigned_q ? {24'b0, b} : {{24{b[7]}}, b};
            end
            2'b01: begin
                logic [15:0] h;
                h = byte_offset_q[1]
                    ? rdata[31:16]
                    : rdata[15:0];
                o_rdata = MemUnsigned_q ? {16'b0, h} : {{16{h[15]}}, h};
            end
            2'b10: o_rdata = rdata;
            default: o_rdata = 32'b0;
        endcase
    end

`ifdef QUARTUS_INIT
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram_array);
        end
    end
`endif

endmodule
