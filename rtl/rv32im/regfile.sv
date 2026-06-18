module RegFile #(
  parameter bit WRITE_THROUGH = 1'b1  // Cho phép đọc thấy dữ liệu mới ghi trong cùng chu kỳ
)(
  input  logic        clk,
  input  logic        rst_n,      // Reset active-low

  input  logic [4:0]  rsR1,       // Địa chỉ nguồn 1
  input  logic [4:0]  rsR2,       // Địa chỉ nguồn 2
  input  logic [4:0]  rsW,        // Địa chỉ ghi (write register)
  input  logic [31:0] dataW,      // Dữ liệu ghi
  input  logic        RegWEn,     // Cho phép ghi (Write Enable)

  output logic [31:0] dataR1,     // Dữ liệu đọc 1 (R[rsR1])
  output logic [31:0] dataR2      // Dữ liệu đọc 2 (R[rsR2])
);
  
  //import rv32_pkg::*;
  logic [31:0] rf [0:31];

  // ----------------------------
  //  Ghi đồng bộ + Reset toàn bộ
  // ----------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 32; i++) rf[i] <= '0;  // Reset tất cả về 0
    end else if (RegWEn && (rsW != 0)) begin
      rf[rsW] <= dataW;   // Ghi vào thanh ghi rsW (trừ x0)
    end
  end

  // ----------------------------
  //  Đọc tổ hợp + Write-through bypass
  // ----------------------------
  wire hitR1 = (WRITE_THROUGH && RegWEn && (rsW == rsR1) && (rsW != 0));
  wire hitR2 = (WRITE_THROUGH && RegWEn && (rsW == rsR2) && (rsW != 0));

  assign dataR1 = (rsR1 == 0) ? 32'b0 : (hitR1) ? dataW : rf[rsR1];

  assign dataR2 = (rsR2 == 0) ? 32'b0 : (hitR2) ? dataW : rf[rsR2];

endmodule
