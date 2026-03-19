module ALU (
  input  logic [31:0]               A,
  input  logic [31:0]               B,
  input  rv32_pkg::ALUSel_t         ALUSel,
  output logic [31:0]               result
);
  import rv32_pkg::*;
  
  logic signed [63:0] prod_ss;
  logic signed [63:0] prod_su;
  logic        [63:0] prod_uu;  
  
  logic signed [63:0] A_ext_s;
  logic signed [63:0] B_ext_s;
  logic        [63:0] A_ext_u;
  logic        [63:0] B_ext_u; 
  
  logic [4:0] shamt;                 // chỉ lấy 5 bit thấp như RV32I
  assign shamt = B[4:0];

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
   

      //ALU_SUB : alu = A - B;

      ALU_SLT  : result = {31'b0, $signed(A) <  $signed(B)};   // signed compare
      ALU_SLTU :  = {31'b0, $unsigned(A) < $unsigned(B)}; // unsigned compare

      ALU_AND : result = A & B;
      ALU_OR  : result = A | B;
      ALU_XOR : result = A ^ B;

      ALU_SLL : result = A <<  shamt;
      ALU_SRL : result = $unsigned(A) >>  shamt;  // logical right
      ALU_SRA : result = $signed(A)   >>> shamt;  // arithmetic right

      ALU_LUI : result = B;

      ALU_JALR : result = (A + B) & 32'hFFFF_FFFE;
      
      ALU_MUL:    result = A * B;
      ALU_MULH:   result = prod_ss[63:32];
      ALU_MULHSU: result = prod_su[63:32];
      ALU_MULHU:  result = prod_uu[63:32];

      ALU_DIV: begin
    if (B == 0) begin
        result = 32'hFFFFFFFF;   // Spec: -1
    end
    else if (A == 32'h80000000 && B == 32'hFFFFFFFF) begin
        result = 32'h80000000;   // Overflow case
    end
    else begin
        result = $signed(A) / $signed(B);
    end
end

// ================= DIVU =================
ALU_DIVU: begin
    if (B == 0) begin
        result = 32'hFFFFFFFF;
    end
    else begin
        result = A / B;
    end
end

// ================= REM =================
ALU_REM: begin
    if (B == 0) begin
        result = A;              // Spec: remainder = dividend
    end
    else if (A == 32'h80000000 && B == 32'hFFFFFFFF) begin
        result = 32'h0;
    end
    else begin
        result = $signed(A) % $signed(B);
    end
end

// ================= REMU =================
ALU_REMU: begin
    if (B == 0) begin
        result = A;
    end
    else begin
        result = A % B;
    end
end
      default :  result = 32'd0;

    endcase
  end
endmodule
