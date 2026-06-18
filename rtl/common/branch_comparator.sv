// BranchComparator.v
module Branch_Comparator #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0] rs1,
  input  wire [WIDTH-1:0] rs2,
  input  wire             BrUn,   // 0 = signed, 1 = unsigned
  output wire             BrEq,   // rs1 == rs2
  output wire             BrLT    // rs1 <  rs2  (theo BrUn)
);
  assign BrEq = (rs1 == rs2);
  assign BrLT = (BrUn) ? (rs1 < rs2)                  // unsigned
                       : ($signed(rs1) < $signed(rs2)); // signed
endmodule
