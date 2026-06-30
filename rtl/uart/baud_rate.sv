module baud_rate #(
        parameter M = 163
        ) (
        input  logic clk,
        input  logic rst_n,

        output logic tick
        );
    import uart_pkg::*;
    localparam int N = $clog2(M);


    baud_state    state_reg, state_next;
    logic [N-1:0] r_reg, r_next;
    always_comb begin
        state_next = state_reg;
        r_next     = r_reg;
        tick       = 1'b0;
    
        case (state_reg)
            RESET: begin
                r_next     = '0;
                state_next = COUNT;
            end
    
            COUNT: begin
                if (r_reg == M-2) begin
                    r_next = r_reg + 1'b1;
                    state_next = TICK;
                end else begin
                    r_next = r_reg + 1'b1;
                end
            end
    
            TICK: begin
                if (r_reg == M-1) begin
                    tick       = 1'b1;
                    r_next     = '0;
                    state_next = COUNT;
                end else begin
                    r_next = r_reg + 1'b1;
                end
            end
        endcase
    end
    //always_comb begin
    //    state_next = state_reg;
    //    r_next     = r_reg;
    //    tick       = 1'b0;
    //
    //    case (state_reg)
    //        RESET: begin
    //            r_next     = '0;
    //            state_next = COUNT;
    //        end
    //
    //        COUNT: begin
    //            if (r_reg == M-1) begin
    //                r_next     = '0;
    //                state_next = TICK;
    //            end else begin
    //                r_next = r_reg + 1'b1;
    //            end
    //        end
    //
    //        TICK: begin
    //            tick       = 1'b1;   // 1-cycle pulse
    //            state_next = COUNT;
    //        end
    //    endcase
    //end
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state_reg <= RESET;
            r_reg     <= 1'b0;
        end
        else begin
            state_reg <= state_next;
            r_reg     <= r_next;
        end
    end
endmodule
