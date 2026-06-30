module tx #(
        parameter integer DBIT    = 'd8, 
        parameter integer DB_TICK = 'd16,
        parameter integer SB_TICK = 'd16
        ) (
        input  logic            clk,
        input  logic            rst_n,
        input  logic            tick,
        input  logic            tx_start,
        input  logic [DBIT-1:0] din,

        output logic            tx,
        output logic            tx_done_tick
        );

    import uart_pkg::*;

    localparam integer TICK_CNT_W = $clog2(SB_TICK);
    localparam integer DATA_CNT_W = $clog2(DBIT);
    
    state_type             state_reg, state_next;
    logic [TICK_CNT_W-1:0] tick_cnt_reg, tick_cnt_next;
    logic [DATA_CNT_W-1:0] d_cnt_reg, d_cnt_next;
    logic [DBIT-1:0]       d_reg, d_next;
    logic                  tx_reg, tx_next;

    //logic                  tx_done_tick_next, tx_done_tick_reg;


    always_comb begin
        state_next = state_reg;
        tick_cnt_next = tick_cnt_reg;
        d_cnt_next = d_cnt_reg;
        d_next = d_reg;
        tx_next = tx_reg;
        //tx_done_tick_next = 1'b0;
        tx_done_tick = 1'b0;

        case(state_reg)
            IDLE : begin
                tx_next = '1;
                if(tx_start) begin
                    tick_cnt_next = '0;
                    d_next = din;
                    state_next = START;
                end
            end
            START : begin
                tx_next = '0;
                if(tick) begin 
                    if(tick_cnt_reg == DB_TICK-1) begin
                        tick_cnt_next = '0;
                        d_cnt_next = '0;
                        state_next = DATA;
                    end
                    else 
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                end
            end
            DATA : begin
                tx_next = d_reg[d_cnt_reg];
                if(tick) begin 
                    if(tick_cnt_reg == DB_TICK-1) begin
                        tick_cnt_next = '0;
                        if(d_cnt_reg == DBIT-1) begin
                            tick_cnt_next = '0;
                            d_cnt_next = '0;
                            state_next = STOP;
                        end
                        else begin
                            d_cnt_next = d_cnt_reg + 1'b1;
                        end
                    end
                    else 
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                end
            end
            STOP : begin
                tx_next = 1'b1;
                if(tick) begin 
                    if(tick_cnt_reg == DB_TICK-1) begin
                        tick_cnt_next = '0;
                        tx_done_tick = 1'b1;
                        //tx_done_tick_next = 1'b1;
                        state_next = IDLE;
                    end
                    else 
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state_reg        <= IDLE;
            tick_cnt_reg     <= '0;
            d_cnt_reg        <= '0;
            d_reg            <= '0;
            tx_reg           <= '1;
            //tx_done_tick_reg <= '0;
        end
        else begin
            state_reg        <= state_next;
            tick_cnt_reg     <= tick_cnt_next;
            d_cnt_reg        <= d_cnt_next;
            d_reg            <= d_next;
            tx_reg           <= tx_next;
            //tx_done_tick_reg <= tx_done_tick_next;
        end
    end

    assign tx = tx_reg;
    //assign tx_done_tick = tx_done_tick_reg;

endmodule
