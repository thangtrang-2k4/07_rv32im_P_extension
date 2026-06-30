module rx #(
        parameter integer DBIT = 8,
        parameter integer DB_TICK = 16,
        parameter integer SB_TICK = 16
        ) (
        input  logic clk,
        input  logic rst_n,
        input  logic rx,
        input  logic tick,

        output logic [DBIT-1:0] dout,
        output logic rx_done_tick
        );
    import uart_pkg::*;
    
    localparam integer TICK_CNT_W = $clog2(DB_TICK);
    localparam integer DATA_CNT_W = $clog2(DBIT);
    
    state_type                  state_next, state_reg;
    logic      [TICK_CNT_W-1:0] tick_cnt_reg, tick_cnt_next;
    logic      [DBIT-1:0]       d_reg, d_next;
    logic      [DATA_CNT_W-1:0] d_cnt_reg, d_cnt_next;
    logic                       rx_done_tick_next, rx_done_tick_reg;

    always_comb begin
        state_next = state_reg;
        tick_cnt_next = tick_cnt_reg;
        d_next = d_reg;
        d_cnt_next = d_cnt_reg;

        rx_done_tick_next = '0;
        case (state_reg)
            IDLE : begin
                if(!rx) begin 
                    tick_cnt_next = 1'b0;
                    state_next = START;
                end    
            end
            START : begin
                if (tick) begin
                    if (tick_cnt_reg == (DB_TICK/2)-1) begin
                        if (!rx) begin
                            tick_cnt_next = '0;
                            d_cnt_next = '0;
                            state_next = DATA;
                        end
                        else begin
                            state_next = IDLE;
                        end
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
            DATA : begin
                if(tick) begin
                    if(tick_cnt_reg == DB_TICK-1) begin 
                        tick_cnt_next = 1'b0;
                        d_next = {rx, d_reg[DBIT-1:1]};
                        if(d_cnt_reg == DBIT-1) begin
                            d_cnt_next = 1'b0;
                            state_next = STOP;
                        end
                        else begin
                            d_cnt_next = d_cnt_reg+1'b1;
                        end
                    end    
                    else begin
                        tick_cnt_next = tick_cnt_reg+1'b1;
                    end
                end
            end
            STOP : begin
                if (tick) begin
                    if (tick_cnt_reg == (SB_TICK)-1) begin
                        tick_cnt_next = '0;
                        if (rx)
                            rx_done_tick_next = 1'b1;
                        state_next = IDLE;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
        endcase
    end
    
    always_ff @(posedge clk) begin 
        if(!rst_n) begin
            state_reg    <= IDLE;
            tick_cnt_reg <= 'b0;
            d_reg        <= 'b0;
            d_cnt_reg    <= 'b0;
            rx_done_tick_reg <= '0;
        end
        else begin
            state_reg    <= state_next;
            tick_cnt_reg <= tick_cnt_next;
            d_reg        <= d_next;
            d_cnt_reg    <= d_cnt_next;
            rx_done_tick_reg <= rx_done_tick_next;
        end
    end

    assign dout = d_reg;
    assign rx_done_tick = rx_done_tick_reg;
endmodule
