module Adder_9Bit (
    input logic [8:0] A0, A1, A2, A3,
    input logic [8:0] B0, B1, B2, B3,
    input logic CarryIn0, CarryIn1, CarryIn2, CarryIn3,

    output logic [8:0] Sum0, Sum1, Sum2, Sum3,
    output logic CarryOut0, CarryOut1, CarryOut2, CarryOut3
);


    assign Sum0 = A0 + B0 + CarryIn0;
    assign CarryOut0 = Sum0[8];

    assign Sum1 = A1 + B1 + CarryIn1;
    assign CarryOut1 = Sum1[8];

    assign Sum2 = A2 + B2 + CarryIn2;
    assign CarryOut2 = Sum2[8];

    assign Sum3 = A3 + B3 + CarryIn3;
    assign CarryOut3 = Sum3[8];

endmodule
