module sram_dump_uart #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    // Note: This is the WORD address (Byte Address / 4)
    parameter BASE_ADDR  = 16'h0080, 
    // Number of 32-bit samples to read
    parameter COUNT      = 64        
)(
    input  logic clk,
    input  logic rst_n,

    input  logic start,
    output logic active,
    output logic done,

    // SRAM interface (Read-only)
    output logic [ADDR_WIDTH-1:0] ram_addr,
    input  logic [DATA_WIDTH-1:0] ram_rdata,

    // UART TX FIFO interface
    input  logic       uart_tx_full,
    output logic       uart_wr_en,
    output logic [7:0] uart_wr_data
);

    typedef enum logic [3:0] {
        S_IDLE,
        S_READ_ADDR,
        S_WAIT_DATA,
        S_SEND_HEX,
        S_SEND_NL,
        S_SEND_D,
        S_SEND_O,
        S_SEND_N,
        S_SEND_E,
        S_SEND_DONE_NL,
        S_DONE
    } state_t;

    state_t state, state_next;
    
    logic [31:0] word_buf, word_buf_next;
    logic [15:0] index, index_next;
    logic [2:0]  hex_pos, hex_pos_next;
    
    logic [ADDR_WIDTH-1:0] ram_addr_next;
    logic       active_next;
    logic       done_next;
    logic       uart_wr_en_next;
    logic [7:0] uart_wr_data_next;

    // Function to convert 4-bit nibble to ASCII hex character
    function logic [7:0] hex_char(input logic [3:0] v);
        begin
            if (v < 10)
                hex_char = 8'h30 + {4'd0, v};         // '0'-'9'
            else
                hex_char = 8'h41 + {4'd0, (v - 10)};  // 'A'-'F'
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            word_buf     <= '0;
            index        <= '0;
            hex_pos      <= 3'd7;
            ram_addr     <= '0;
            active       <= 1'b0;
            done         <= 1'b0;
            uart_wr_en   <= 1'b0;
            uart_wr_data <= '0;
        end else begin
            state        <= state_next;
            word_buf     <= word_buf_next;
            index        <= index_next;
            hex_pos      <= hex_pos_next;
            ram_addr     <= ram_addr_next;
            active       <= active_next;
            done         <= done_next;
            uart_wr_en   <= uart_wr_en_next;
            uart_wr_data <= uart_wr_data_next;
        end
    end

    always_comb begin
        // Default assignments to prevent latches
        state_next        = state;
        word_buf_next     = word_buf;
        index_next        = index;
        hex_pos_next      = hex_pos;
        ram_addr_next     = ram_addr;
        active_next       = active;
        done_next         = done;
        uart_wr_en_next   = 1'b0; 
        uart_wr_data_next = uart_wr_data;

        case (state)
            S_IDLE: begin
                active_next = 1'b0;
                done_next   = 1'b0;
                if (start) begin
                    active_next = 1'b1;
                    index_next  = '0;
                    state_next  = S_READ_ADDR;
                end
            end

            S_READ_ADDR: begin
                ram_addr_next = BASE_ADDR + index;
                state_next    = S_WAIT_DATA;
            end

            S_WAIT_DATA: begin
                // SRAM requires 1 clock cycle to output data after address is registered.
                // The data will be captured precisely when transitioning to S_SEND_HEX.
                word_buf_next = ram_rdata;
                hex_pos_next  = 3'd7;
                state_next    = S_SEND_HEX;
            end

            S_SEND_HEX: begin
                if (!uart_tx_full) begin
                    // Extract the correct 4-bit nibble and convert to ASCII
                    uart_wr_data_next = hex_char( (word_buf >> (hex_pos * 4)) & 4'hF );
                    uart_wr_en_next   = 1'b1; // Push to FIFO
                    
                    if (hex_pos == 0) begin
                        state_next = S_SEND_NL;
                    end else begin
                        hex_pos_next = hex_pos - 1'b1;
                    end
                end
            end

            S_SEND_NL: begin
                if (!uart_tx_full) begin
                    uart_wr_data_next = 8'h0A; // '\n' (Newline)
                    uart_wr_en_next   = 1'b1;

                    if (index == COUNT - 1) begin
                        state_next = S_SEND_D;
                    end else begin
                        index_next = index + 1'b1;
                        state_next = S_READ_ADDR;
                    end
                end
            end

            // Send "DONE\n" indicator when finished dumping
            S_SEND_D: begin
                if (!uart_tx_full) begin
                    uart_wr_data_next = 8'h44; // 'D'
                    uart_wr_en_next   = 1'b1;
                    state_next        = S_SEND_O;
                end
            end
            S_SEND_O: begin
                if (!uart_tx_full) begin
                    uart_wr_data_next = 8'h4F; // 'O'
                    uart_wr_en_next   = 1'b1;
                    state_next        = S_SEND_N;
                end
            end
            S_SEND_N: begin
                if (!uart_tx_full) begin
                    uart_wr_data_next = 8'h4E; // 'N'
                    uart_wr_en_next   = 1'b1;
                    state_next        = S_SEND_E;
                end
            end
            S_SEND_E: begin
                if (!uart_tx_full) begin
                    uart_wr_data_next = 8'h45; // 'E'
                    uart_wr_en_next   = 1'b1;
                    state_next        = S_SEND_DONE_NL;
                end
            end
            S_SEND_DONE_NL: begin
                if (!uart_tx_full) begin
                    uart_wr_data_next = 8'h0A; // '\n'
                    uart_wr_en_next   = 1'b1;
                    state_next        = S_DONE;
                end
            end

            S_DONE: begin
                active_next = 1'b0;
                done_next   = 1'b1;
                // Wait for start to be deasserted before returning to IDLE
                if (!start) begin
                    state_next = S_IDLE;
                end
            end

            default: state_next = S_IDLE;
        endcase
    end
endmodule
