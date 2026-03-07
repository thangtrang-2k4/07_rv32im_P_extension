module Clock_Divider #(
    parameter int DIV = 25_000_000    // toggle mỗi 25M xung → ~1 Hz (50MHz)
)(
    input  logic clk_in,
    input  logic rst_n,
    output logic clk_out
);
    logic [$clog2(DIV)-1:0] cnt;

    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= '0;
            clk_out <= 1'b0;
        end else begin
            if (cnt == DIV-1) begin
                cnt     <= '0;
                clk_out <= ~clk_out;   // đổi trạng thái → f_out ≈ f_in / (2*DIV)
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
