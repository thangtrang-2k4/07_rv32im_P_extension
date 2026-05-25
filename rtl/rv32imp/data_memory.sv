module Data_Memory #(
    parameter int DEPTH_WORDS = 4096,
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

    // ---- Byte-enable + aligned write data (M10K-compatible) ----
    logic [3:0] be;
    logic [31:0] wdata_aligned;

    always_comb begin
        be           = 4'b0000;
        wdata_aligned = 32'b0;

        case (MemSize)
            2'b00: begin // Byte store — shift dataW[7:0] to correct lane
                case (byte_offset)
                    2'b00: begin be = 4'b0001; wdata_aligned = {24'b0, dataW[7:0]};                       end
                    2'b01: begin be = 4'b0010; wdata_aligned = {16'b0, dataW[7:0], 8'b0};                  end
                    2'b10: begin be = 4'b0100; wdata_aligned = {8'b0,  dataW[7:0], 16'b0};                 end
                    2'b11: begin be = 4'b1000; wdata_aligned = {dataW[7:0], 24'b0};                        end
                    default: begin be = 4'b0000; wdata_aligned = 32'b0; end
                endcase
            end
            2'b01: begin // Half-word store
                if (byte_offset[1] == 1'b0) begin
                    be            = 4'b0011;
                    wdata_aligned = {16'b0, dataW[15:0]};
                end else begin
                    be            = 4'b1100;
                    wdata_aligned = {dataW[15:0], 16'b0};
                end
            end
            2'b10: begin // Word store
                be            = 4'b1111;
                wdata_aligned = dataW;
            end
            default: begin
                be            = 4'b0000;
                wdata_aligned = 32'b0;
            end
        endcase
    end

    // ---- WRITE: M10K-compatible pattern ----
    always_ff @(posedge clk) begin
        if (MemRW) begin
            if (be[0]) ram_array[word_addr][ 7: 0] <= wdata_aligned[ 7: 0];
            if (be[1]) ram_array[word_addr][15: 8] <= wdata_aligned[15: 8];
            if (be[2]) ram_array[word_addr][23:16] <= wdata_aligned[23:16];
            if (be[3]) ram_array[word_addr][31:24] <= wdata_aligned[31:24];
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
