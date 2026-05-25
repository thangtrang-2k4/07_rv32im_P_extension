module Data_Memory #(
    parameter int DEPTH_WORDS = 16384,
    parameter logic [31:0] BASE_ADDR = 32'h8001_0000
)(
    input  logic        clk,
    input  logic [31:0] addr,
    input  logic [31:0] dataW,
    input  logic        MemRW,
    input  logic [1:0]  MemSize,
    input  logic        MemUnsigned,
    output logic [31:0] dataR
);

    localparam int ADDR_BITS = $clog2(DEPTH_WORDS);

    (* ramstyle = "M10K" *)
    logic [31:0] ram_array [0:DEPTH_WORDS-1];

    // ---- Address decode ----
    logic [ADDR_BITS-1:0] word_addr;
    logic [1:0] byte_offset;

    assign word_addr   = addr[ADDR_BITS+1:2] - BASE_ADDR[ADDR_BITS+1:2];
    assign byte_offset = addr[1:0];

    // ---- Byte-enable + per-lane write data ----
    logic [3:0] be;
    logic [7:0] wdata_b0, wdata_b1, wdata_b2, wdata_b3;

    always_comb begin
        be       = 4'b0000;
        wdata_b0 = dataW[7:0];
        wdata_b1 = dataW[15:8];
        wdata_b2 = dataW[23:16];
        wdata_b3 = dataW[31:24];

        case (MemSize)
            2'b00: begin // Byte store
                case (byte_offset)
                    2'b00: begin be = 4'b0001; wdata_b0 = dataW[7:0]; end
                    2'b01: begin be = 4'b0010; wdata_b1 = dataW[7:0]; end
                    2'b10: begin be = 4'b0100; wdata_b2 = dataW[7:0]; end
                    2'b11: begin be = 4'b1000; wdata_b3 = dataW[7:0]; end
                    default: be = 4'b0000;
                endcase
            end
            2'b01: begin // Half-word store
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
            2'b10: begin // Word store
                be = 4'b1111;
            end
            default: be = 4'b0000;
        endcase
    end

    // ---- WRITE: registered, per-byte enable ----
    always_ff @(posedge clk) begin
        if (MemRW) begin
            if (be[0]) ram_array[word_addr][ 7: 0] <= wdata_b0;
            if (be[1]) ram_array[word_addr][15: 8] <= wdata_b1;
            if (be[2]) ram_array[word_addr][23:16] <= wdata_b2;
            if (be[3]) ram_array[word_addr][31:24] <= wdata_b3;
        end
    end

    // ---- READ: combinational ----
    logic [31:0] rdata;
    assign rdata = ram_array[word_addr];

    // ---- Output decode: combinational ----
    always_comb begin
        dataR = 32'b0;
        case (MemSize)
            2'b00: begin
                logic [7:0] b;
                case (byte_offset)
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
                h = byte_offset[1] ? rdata[31:16] : rdata[15:0];
                dataR = MemUnsigned ? {16'b0, h} : {{16{h[15]}}, h};
            end
            2'b10: dataR = rdata;
            default: dataR = 32'b0;
        endcase
    end

    // Load program
    initial begin
        $readmemh("../../sw/Filter-Fir/pext_dmem.hex", ram_array);
    end

endmodule
