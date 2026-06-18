module Devider (
  input  logic [31:0]               A,
  input  logic [31:0]               B,
  input  rv32_pkg::ALUSel_t         ALUSel,
  output logic [31:0]               alu
);
  import rv32_pkg::*;
  
  logic signed [63:0] quot_ss;
  logic signed [63:0] quot_su;
  logic        [63:0] quot_uu;  
  
  logic signed [63:0] A_ext_s;
  logic signed [63:0] B_ext_s;
  logic        [63:0] A_ext_u;
  logic        [63:0] B_ext_u; 

  always_comb begin
      A_ext_s = {{32{A[31]}}, A};   // sign extend
      B_ext_s = {{32{B[31]}}, B};

      A_ext_u = {32'b0, A};         // zero extend
      B_ext_u = {32'b0, B};

      quot_ss = (B != 0) ? (A_ext_s / B_ext_s) : -1; // signed division, handle divide by zero
      quot_su = (B != 0) ? (A_ext_s / B_ext_u) : -1; // signed/unsigned division
      quot_uu = (B != 0) ? (A_ext_u / B_ext_u) : -1; // unsigned division
  end

  always_comb begin
    alu = 32'd0;                     // giá trị mặc định an toàn
    unique case (ALUSel)
      ALU_DIV:    alu = quot_ss[31:0];
      ALU_DIVU:   alu = quot_uu[31:0];
      default: alu = 32'd0;           // các trường hợp khác không sử dụng divider
    endcase
  end