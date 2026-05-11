module ALU (
  input  logic [31:0]               A,
  input  logic [31:0]               B,
  input  rv32_pkg::ALUSel_t         ALUSel,
  output logic [31:0]               alu
);
  import rv32_pkg::*;
  
//`ifdef ENABLE_M_EXT
  logic signed [63:0] prod_ss;
  logic signed [63:0] prod_su;
  logic        [63:0] prod_uu;

  logic signed [63:0] A_ext_s;
  logic signed [63:0] B_ext_s;
  logic        [63:0] A_ext_u;
  logic        [63:0] B_ext_u;

  always_comb begin
      A_ext_s = {{32{A[31]}}, A};
      B_ext_s = {{32{B[31]}}, B};
      A_ext_u = {32'b0, A};
      B_ext_u = {32'b0, B};
      prod_ss = A_ext_s * B_ext_s;
      prod_su = A_ext_s * B_ext_u;
      prod_uu = A_ext_u * B_ext_u;
  end
//`endif

  logic [4:0] shamt;
  assign shamt = B[4:0];

  always_comb begin
    alu = 32'd0;                     // giá trị mặc định an toàn
    unique case (ALUSel)
      ALU_ADD : alu = A + B;
      ALU_SUB : alu = A - B;

      ALU_SLT  : alu = {31'b0, $signed(A) <  $signed(B)};   // signed compare
      ALU_SLTU : alu = {31'b0, $unsigned(A) < $unsigned(B)}; // unsigned compare

      ALU_AND : alu = A & B;
      ALU_OR  : alu = A | B;
      ALU_XOR : alu = A ^ B;

      ALU_SLL : alu = A <<  shamt;
      ALU_SRL : alu = $unsigned(A) >>  shamt;  // logical right
      ALU_SRA : alu = $signed(A)   >>> shamt;  // arithmetic right

      ALU_LUI : alu = B;

      ALU_JALR : alu = (A + B) & 32'hFFFF_FFFE;
      
//`ifdef ENABLE_M_EXT
      ALU_MUL:    alu = A * B;
      ALU_MULH:   alu = prod_ss[63:32];
      ALU_MULHSU: alu = prod_su[63:32];
      ALU_MULHU:  alu = prod_uu[63:32];

      ALU_DIV: begin
          if (B == 0)                                        alu = 32'hFFFF_FFFF;
          else if (A == 32'h8000_0000 && B == 32'hFFFF_FFFF) alu = 32'h8000_0000;
          else                                               alu = $signed(A) / $signed(B);
      end

      ALU_DIVU: begin
          if (B == 0) alu = 32'hFFFF_FFFF;
          else        alu = A / B;
      end

      ALU_REM: begin
          if (B == 0)                                        alu = A;
          else if (A == 32'h8000_0000 && B == 32'hFFFF_FFFF) alu = 32'h0;
          else                                               alu = $signed(A) % $signed(B);
      end

      ALU_REMU: begin
          if (B == 0) alu = A;
          else        alu = A % B;
      end
//`endif // ENABLE_M_EXT
      default :  alu = 32'd0;

    endcase
  end
endmodule
