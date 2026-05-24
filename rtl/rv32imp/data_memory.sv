module Data_Memory #(
    parameter int DEPTH_WORDS = 16384,
    parameter logic [31:0] BASE_ADDR = 32'h8001_0000
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

    localparam int ADDR_BITS = $clog2(DEPTH_WORDS);

    logic [ADDR_BITS-1:0] word_addr;
    logic [1:0] byte_offset;

    assign word_addr   = i_addr[ADDR_BITS+1:2] - BASE_ADDR[ADDR_BITS+1:2];
    assign byte_offset = i_addr[1:0];

    logic [3:0] be;

    always_comb begin
        be = 4'b0000;
        case (i_size)
            2'b00: begin
                case (byte_offset)
                    2'b00: be = 4'b0001;
                    2'b01: be = 4'b0010;
                    2'b10: be = 4'b0100;
                    2'b11: be = 4'b1000;
                    default: be = 4'b0000;
                endcase
            end
            2'b01: be = byte_offset[1] ? 4'b1100 : 4'b0011;
            2'b10: be = 4'b1111;
            default: be = 4'b0000;
        endcase
    end

    logic [31:0] store_wdata;

    always_comb begin
        case (i_size)
            2'b00: store_wdata = {4{i_wdata[7:0]}};
            2'b01: store_wdata = {2{i_wdata[15:0]}};
            2'b10: store_wdata = i_wdata;
            default: store_wdata = 32'b0;
        endcase
    end

    logic [31:0] rdata;

    (* ramstyle = "M10K" *)
    logic [31:0] ram_array [0:DEPTH_WORDS-1];

    // WRITE: conditional on strobe + write-enable
    always_ff @(posedge clk) begin
        if (i_stb && i_we) begin
            if (be[0]) ram_array[word_addr][ 7: 0] <= store_wdata[ 7: 0];
            if (be[1]) ram_array[word_addr][15: 8] <= store_wdata[15: 8];
            if (be[2]) ram_array[word_addr][23:16] <= store_wdata[23:16];
            if (be[3]) ram_array[word_addr][31:24] <= store_wdata[31:24];
        end
    end

    // READ: unconditional (M10K always reads every cycle)
    always_ff @(posedge clk) begin
        rdata <= ram_array[word_addr];
    end

    logic [1:0] size_q;
    logic [1:0] offset_q;
    logic       unsigned_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_ack      <= 1'b0;
            size_q     <= 2'b0;
            offset_q   <= 2'b0;
            unsigned_q <= 1'b0;
        end else begin
            o_ack <= i_stb;
            if (i_stb) begin
                size_q     <= i_size;
                offset_q   <= byte_offset;
                unsigned_q <= i_unsigned;
            end
        end
    end

    always_comb begin
        o_rdata = 32'b0;
        case (size_q)
            2'b00: begin
                logic [7:0] b;
                case (offset_q)
                    2'b00: b = rdata[7:0];
                    2'b01: b = rdata[15:8];
                    2'b10: b = rdata[23:16];
                    2'b11: b = rdata[31:24];
                    default: b = 8'b0;
                endcase
                o_rdata = unsigned_q ? {24'b0, b} : {{24{b[7]}}, b};
            end
            2'b01: begin
                logic [15:0] h;
                h = offset_q[1] ? rdata[31:16] : rdata[15:0];
                o_rdata = unsigned_q ? {16'b0, h} : {{16{h[15]}}, h};
            end
            2'b10: o_rdata = rdata;
            default: o_rdata = 32'b0;
        endcase
    end

    initial begin
        $readmemh("../../sw/Filter-Fir/pext_dmem.hex", ram_array);
    end

endmodule
