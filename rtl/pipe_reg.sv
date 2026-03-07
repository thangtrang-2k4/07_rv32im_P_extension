module pipe_reg #(
  parameter int W = 32
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         en,       // 1 = cập nhật bình thường
  input  logic         flush,    // 1 = nạp bubble
  input  logic [W-1:0] d,
  input  logic [W-1:0] bubble,   // giá trị NOP/bubble
  output logic [W-1:0] q
);
  //always_ff @(posedge clk or negedge rst_n) begin
  //  if (!rst_n)      q <= bubble;
  //  else if (flush)  q <= bubble;
  //  else if (en)     q <= d;
  //  else q <= q;
  //end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)      q <= bubble;   // reset async
    else if (flush)  q <= bubble;   // ƯU TIÊN 1: nếu flush=1 ở đúng cạnh ↑ → q := bubble
    else if (en)     q <= d;        // ƯU TIÊN 2: nếu flush=0 và en=1 → q := d
    else q <= q;
  end
endmodule
