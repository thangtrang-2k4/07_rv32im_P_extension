module Mutiplier (
  input  logic [31:0]               A,
  input  logic [31:0]               B,
  input  rv32_pkg::ALUSel_t         ALUSel,
  output logic [31:0]               alu
);
  import rv32_pkg::*;
  
  logic signed [63:0] prod_ss;
  logic signed [63:0] prod_su;
  logic        [63:0] prod_uu;  
  
  logic signed [63:0] A_ext_s;
  logic signed [63:0] B_ext_s;
  logic        [63:0] A_ext_u;
  logic        [63:0] B_ext_u; 

  always_comb begin
      A_ext_s = {{32{A[31]}}, A};   // sign extend
      B_ext_s = {{32{B[31]}}, B};

      A_ext_u = {32'b0, A};         // zero extend
      B_ext_u = {32'b0, B};

      prod_ss = A_ext_s * B_ext_s;  // signed × signed
      prod_su = A_ext_s * B_ext_u;  // signed × unsigned
      prod_uu = A_ext_u * B_ext_u;  // unsigned × unsigned
  end

  always_comb begin
    alu = 32'd0;                     // giá trị mặc định an toàn
    unique case (ALUSel)
      ALU_MUL:    alu = A * B;
      ALU_MULH:   alu = prod_ss[63:32];
      ALU_MULHSU: alu = prod_su[63:32];
      ALU_MULHU:  alu = prod_uu[63:32];
      default: alu = 32'd0;           // các trường hợp khác không sử dụng multiplier
    endcase
  end