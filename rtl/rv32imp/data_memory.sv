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
    output logic [31:0] o_rdata,
    
    // UART Read Port
    input  logic        uart_clk,
    input  logic [31:0] uart_addr,
    output logic [31:0] uart_dataR
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


    // ---------------- UART READ PORT ----------------
    logic [ADDR_BITS-1:0] uart_word_addr;
    assign uart_word_addr = uart_addr[ADDR_BITS+1:2] - BASE_ADDR[ADDR_BITS+1:2];

    logic [31:0] rdata;

    // ---- Explicit ALTSYNCRAM Instantiation (4 parallel 8-bit RAMs for ISMCE support) ----
    
    // RAM 0: Byte 0 (bits 7:0)
    altsyncram #(
        .intended_device_family("Cyclone IV E"),
        .operation_mode("BIDIR_DUAL_PORT"),
        .width_a(8),
        .width_b(8),
        .widthad_a(ADDR_BITS),
        .widthad_b(ADDR_BITS),
        .numwords_a(DEPTH_WORDS),
        .numwords_b(DEPTH_WORDS),
`ifndef NO_DEFAULT_MEM_INIT
//        .init_file("../../sw/apps/matrix-multiplication/pextnor_dmem_0.mif"),
//        .init_file("../../sw/apps/matrix-multiplication/pexttran_dmem_0.mif"),
        .init_file("../../sw/apps/filter-fir/pext_dmem_0.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext1_dmem_0.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext2_dmem_0.mif"),
`endif
        .lpm_type("altsyncram"),
        .outdata_reg_a("UNREGISTERED"),
        .outdata_reg_b("UNREGISTERED")
    ) ram_byte0 (
        .clock0(clk),
        .clock1(uart_clk),
        .address_a(word_addr),
        .data_a(store_wdata[7:0]),
        .wren_a(i_stb & i_we & be[0]),
        .q_a(rdata[7:0]),
        .address_b(uart_word_addr),
        .data_b(8'd0),
        .wren_b(1'b0),
        .q_b(uart_dataR[7:0])
    );

    // RAM 1: Byte 1 (bits 15:8)
    altsyncram #(
        .intended_device_family("Cyclone IV E"),
        .operation_mode("BIDIR_DUAL_PORT"),
        .width_a(8),
        .width_b(8),
        .widthad_a(ADDR_BITS),
        .widthad_b(ADDR_BITS),
        .numwords_a(DEPTH_WORDS),
        .numwords_b(DEPTH_WORDS),
`ifndef NO_DEFAULT_MEM_INIT
//        .init_file("../../sw/apps/matrix-multiplication/pextnor_dmem_1.mif"),
//        .init_file("../../sw/apps/matrix-multiplication/pexttran_dmem_1.mif"),
        .init_file("../../sw/apps/filter-fir/pext_dmem_1.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext1_dmem_1.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext2_dmem_1.mif"),
`endif
        .lpm_type("altsyncram"),
        .outdata_reg_a("UNREGISTERED"),
        .outdata_reg_b("UNREGISTERED")
    ) ram_byte1 (
        .clock0(clk),
        .clock1(uart_clk),
        .address_a(word_addr),
        .data_a(store_wdata[15:8]),
        .wren_a(i_stb & i_we & be[1]),
        .q_a(rdata[15:8]),
        .address_b(uart_word_addr),
        .data_b(8'd0),
        .wren_b(1'b0),
        .q_b(uart_dataR[15:8])
    );

    // RAM 2: Byte 2 (bits 23:16)
    altsyncram #(
        .intended_device_family("Cyclone IV E"),
        .operation_mode("BIDIR_DUAL_PORT"),
        .width_a(8),
        .width_b(8),
        .widthad_a(ADDR_BITS),
        .widthad_b(ADDR_BITS),
        .numwords_a(DEPTH_WORDS),
        .numwords_b(DEPTH_WORDS),
`ifndef NO_DEFAULT_MEM_INIT
//        .init_file("../../sw/apps/matrix-multiplication/pextnor_dmem_2.mif"),
//        .init_file("../../sw/apps/matrix-multiplication/pexttran_dmem_2.mif"),
        .init_file("../../sw/apps/filter-fir/pext_dmem_2.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext1_dmem_2.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext2_dmem_2.mif"),
`endif
        .lpm_type("altsyncram"),
        .outdata_reg_a("UNREGISTERED"),
        .outdata_reg_b("UNREGISTERED")
    ) ram_byte2 (
        .clock0(clk),
        .clock1(uart_clk),
        .address_a(word_addr),
        .data_a(store_wdata[23:16]),
        .wren_a(i_stb & i_we & be[2]),
        .q_a(rdata[23:16]),
        .address_b(uart_word_addr),
        .data_b(8'd0),
        .wren_b(1'b0),
        .q_b(uart_dataR[23:16])
    );

    // RAM 3: Byte 3 (bits 31:24)
    altsyncram #(
        .intended_device_family("Cyclone IV E"),
        .operation_mode("BIDIR_DUAL_PORT"),
        .width_a(8),
        .width_b(8),
        .widthad_a(ADDR_BITS),
        .widthad_b(ADDR_BITS),
        .numwords_a(DEPTH_WORDS),
        .numwords_b(DEPTH_WORDS),
`ifndef NO_DEFAULT_MEM_INIT
//        .init_file("../../sw/apps/matrix-multiplication/pextnor_dmem_3.mif"),
//        .init_file("../../sw/apps/matrix-multiplication/pexttran_dmem_3.mif"),
        .init_file("../../sw/apps/filter-fir/pext_dmem_3.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext1_dmem_3.mif"),
//        .init_file("../../sw/apps/filter-sobel/pext2_dmem_3.mif"),
`endif
        .lpm_type("altsyncram"),
        .outdata_reg_a("UNREGISTERED"),
        .outdata_reg_b("UNREGISTERED")
    ) ram_byte3 (
        .clock0(clk),
        .clock1(uart_clk),
        .address_a(word_addr),
        .data_a(store_wdata[31:24]),
        .wren_a(i_stb & i_we & be[3]),
        .q_a(rdata[31:24]),
        .address_b(uart_word_addr),
        .data_b(8'd0),
        .wren_b(1'b0),
        .q_b(uart_dataR[31:24])
    );

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

    // (Initial block removed because altsyncram uses init_file)

endmodule
