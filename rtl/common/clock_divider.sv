module Clock_Divider #(
    parameter int DIV = 25_000_000
)(
    input  logic clk_in,
    input  logic rst_n,
    output logic clk_out
);
    localparam int WIDTH = $clog2(DIV);
    logic [WIDTH-1:0] cnt;

    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= '0;
            clk_out <= 1'b0;
        end else begin
            if (cnt == WIDTH'(DIV - 1)) begin
                cnt     <= '0;
                clk_out <= ~clk_out;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
