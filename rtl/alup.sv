module ALUP(
    input logic [31:0] A,
    input logic [31:0] B,
    input rv32_pkg::ALUSel_t ALUSel,
    output logic [31:0] result
);
    import rv32_pkg::*;

    logic [8:0] A0, A1, A2, A3;
    logic [8:0] B0, B1, B2, B3;
    logic CarryIn0, CarryIn1, CarryIn2, CarryIn3;
    
    logic [8:0] Sum0, Sum1, Sum2, Sum3;
    logic CarryOut0, CarryOut1, CarryOut2, CarryOut3;

    logic [8:0] Result0, Result1, Result2, Result3;

    Adder_9Bit alupext_adder (
        .A0(A0), .A1(A1), .A2(A2), .A3(A3),
        .B0(B0), .B1(B1), .B2(B2), .B3(B3),
        .CarryIn0(CarryIn0), .CarryIn1(CarryIn1), .CarryIn2(CarryIn2), .CarryIn3(CarryIn3),
        .Sum0(Sum0), .Sum1(Sum1), .Sum2(Sum2), .Sum3(Sum3),
        .CarryOut0(CarryOut0), .CarryOut1(CarryOut1), .CarryOut2(CarryOut2), .CarryOut3(CarryOut3)
    );

    always_comb begin
        A0 = {1'b0, A[7:0]};
        A1 = {1'b0, A[15:8]};
        A2 = {1'b0, A[23:16]};
        A3 = {1'b0, A[31:24]};
        B0 = {1'b0, B[7:0]};
        B1 = {1'b0, B[15:8]};
        B2 = {1'b0, B[23:16]};
        B3 = {1'b0, B[31:24]};

        CarryIn0 = 1'b0;
        CarryIn1 = 1'b0;
        CarryIn2 = 1'b0;
        CarryIn3 = 1'b0;
        
        Result0 = Sum0;
        Result1 = Sum1;
        Result2 = Sum2;
        Result3 = Sum3;

        result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};

        unique case(ALUSel)

//            ALU_ADD: begin
//                CarryIn0 = 1'b0;
//                CarryIn1 = CarryOut0;
//                CarryIn2 = CarryOut1;
//                CarryIn3 = CarryOut2;
//
//            end
//
//            ALU_SUB: begin // cần xem sét kỹ lại 
//                B0 = ~{1'b0, B[7:0]};
//                B1 = ~{1'b0, B[15:8]};
//                B2 = ~{1'b0, B[23:16]};
//                B3 = ~{1'b0, B[31:24]};
//                CarryIn0 = 1'b1;
//                CarryIn1 = CarryOut0;
//                CarryIn2 = CarryOut1;
//                CarryIn3 = CarryOut2;
//            end

            ALU_PADD_B: begin
                //CarryIn0 = 1'b0;
                //CarryIn1 = 1'b0;
                //CarryIn2 = 1'b0;
                //CarryIn3 = 1'b0;
            end
            ALU_PAADD_B: begin
                A0 = {A[7], A[7:0]};
                A1 = {A[15], A[15:8]};
                A2 = {A[23], A[23:16]};
                A3 = {A[31], A[31:24]};
                B0 = {B[7], B[7:0]};
                B1 = {B[15], B[15:8]};
                B2 = {B[23], B[23:16]};
                B3 = {B[31], B[31:24]};

                result = {Result3[8:1], Result2[8:1], Result1[8:1], Result0[8:1]};
            end
            ALU_PAADDU_B: begin

                result = {Result3[8:1], Result2[8:1], Result1[8:1], Result0[8:1]};
            end
            ALU_PSADDU_B: begin

                if(Sum0[8]) begin
                    Result0 = 9'd255; 
                end else begin
                    Result0 = Sum0;
                end
                if(Sum1[8]) begin
                    Result1 = 9'd255; 
                end else begin
                    Result1 = Sum1;
                end
                if(Sum2[8]) begin
                    Result2 = 9'd255; 
                end else begin
                    Result2 = Sum2;
                end
                if(Sum3[8]) begin
                    Result3 = 9'd255; 
                end else begin
                    Result3 = Sum3;
                end

                //result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            ALU_PSUB_B: begin
                B0 = ~{B[7], B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = ~{B[23], B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = 1'b1;
                CarryIn2 = 1'b1;
                CarryIn3 = 1'b1;
            end
            ALU_PASUB_B: begin
                A0 = {A[7], A[7:0]};
                A1 = {A[15], A[15:8]};
                A2 = {A[23], A[23:16]};
                A3 = {A[31], A[31:24]};
                B0 = ~{B[7], B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = ~{B[23], B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = 1'b1;
                CarryIn2 = 1'b1;
                CarryIn3 = 1'b1;

                result = {Result3[8:1], Result2[8:1], Result1[8:1], Result0[8:1]};
            end
            ALU_PASUBU_B: begin
                B0 = ~{1'b0, B[7:0]};
                B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]};
                B3 = ~{1'b0, B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = 1'b1;
                CarryIn2 = 1'b1;
                CarryIn3 = 1'b1;

                result = {Result3[8:1], Result2[8:1], Result1[8:1], Result0[8:1]};
            end
            ALU_PSSUB_B: begin
                A0 = {A[7], A[7:0]};
                A1 = {A[15], A[15:8]};
                A2 = {A[23], A[23:16]};
                A3 = {A[31], A[31:24]};
                B0 = ~{B[7], B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = ~{B[23], B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = 1'b1;
                CarryIn2 = 1'b1;
                CarryIn3 = 1'b1;

                if(Sum0[8]==1'b1 && Sum0[7]==1'b0) begin
                    Result0 = -9'sd128; 
                end else if(Sum0[8]==1'b0 && Sum0[7]==1'b1) begin
                    Result0 = 9'sd127; 
                end else begin
                    Result0 = Sum0;
                end

                if(Sum1[8]==1'b1 && Sum1[7]==1'b0) begin
                    Result1 = -9'sd128; 
                end else if(Sum1[8]==1'b0 && Sum1[7]==1'b1) begin
                    Result1 = 9'sd127; 
                end else begin
                    Result1 = Sum1;
                end

                if(Sum2[8]==1'b1 && Sum2[7]==1'b0) begin
                    Result2 = -9'sd128; 
                end else if(Sum2[8]==1'b0 && Sum2[7]==1'b1) begin
                    Result2 = 9'sd127; 
                end else begin
                    Result2 = Sum2;
                end

                if(Sum3[8]==1'b1 && Sum3[7]==1'b0) begin
                    Result3 = -9'sd128; 
                end else if(Sum3[8]==1'b0 && Sum3[7]==1'b1) begin
                    Result3 = 9'sd127; 
                end else begin
                    Result3 = Sum3;
                end

                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            ALU_PSSUBU_B: begin
                B0 = ~{1'b0, B[7:0]};
                B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]};
                B3 = ~{1'b0, B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = 1'b1;
                CarryIn2 = 1'b1;
                CarryIn3 = 1'b1;

                if(Sum0[8] == 1'b1) begin
                    Result0 = 9'd0; 
                end else begin
                    Result0 = Sum0;
                end
                if(Sum1[8] == 1'b1) begin
                    Result1 = 9'd0; 
                end else begin
                    Result1 = Sum1;
                end
                if(Sum2[8] == 1'b1) begin
                    Result2 = 9'd0; 
                end else begin
                    Result2 = Sum2;
                end
                if(Sum3[8] == 1'b1) begin
                    Result3 = 9'd0; 
                end else begin
                    Result3 = Sum3;
                end

                //result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            ALU_PADD_H: begin
                //CarryIn0 = 1'b0;
                CarryIn1 = CarryOut0;
                //CarryIn2 = 1'b0;
                CarryIn3 = CarryOut2;
            end
            // cần quan sát thêm bit dấu khi thực hiện phép cộng tràn số học với phần tử 8 bit (ALU_PADD_H) và phần tử 8 bit có dấu (ALU_PAADD_H)
            ALU_PAADD_H: begin
                //A0 = {A[7], A[7:0]};
                A1 = {A[15], A[15:8]};
                //A2 = {A[23], A[23:16]};
                A3 = {A[31], A[31:24]};
                //B0 = {B[7], B[7:0]};
                B1 = {B[15], B[15:8]};
                //B2 = {B[23], B[23:16]};
                B3 = {B[31], B[31:24]};
                //CarryIn0 = 1'b0;
                CarryIn1 = CarryOut0;
                //CarryIn2 = 1'b0;
                CarryIn3 = CarryOut2;

                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};
            end
            ALU_PAADDU_H: begin
                //CarryIn0 = 1'b0;
                CarryIn1 = CarryOut0;
                //CarryIn2 = 1'b0;
                CarryIn3 = CarryOut2;
                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};
            end
            ALU_PSADD_H: begin

                //A0 = {A[7], A[7:0]};
                A1 = {A[15], A[15:8]};
                //A2 = {A[23], A[23:16]};
                A3 = {A[31], A[31:24]};
                //B0 = {B[7], B[7:0]};
                B1 = {B[15], B[15:8]};
                //B2 = {B[23], B[23:16]};
                B3 = {B[31], B[31:24]};
                //CarryIn0 = 1'b0;
                CarryIn1 = CarryOut0;
                //CarryIn2 = 1'b0;
                CarryIn3 = CarryOut2;
                
                if(Sum1[8] == 1'b1 && Sum1[7] == 1'b0) begin
                    Result0 = 9'd0;
                    Result1= -9'sd128;
                end else if (Sum1[8] == 1'b0 && Sum1[7] == 1'b1) begin
                    Result0 = 9'd255;
                    Result1 = 9'sd127;
                end else begin
                    Result0 = Sum0;
                    Result1 = Sum1;
                end
                if(Sum3[8] == 1'b1 && Sum3[7] == 1'b0) begin
                    Result2 = 9'd0;
                    Result3= -9'sd128;
                end else if (Sum3[8] == 1'b0 && Sum3[7] == 1'b1) begin
                    Result2 = 9'd255;
                    Result3 = 9'sd127;
                end else begin
                    Result2 = Sum2;
                    Result3 = Sum3;
                end

                //result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            // Cần xem xét
            ALU_PSADDU_H: begin

                CarryIn1 = CarryOut0;
                CarryIn3 = CarryOut2;

                if(Sum1[8] == 1'b1) begin
                    Result0 = 9'd255;
                    Result1 = 9'd255;
                end else begin
                    Result0 = Sum0;
                    Result1 = Sum1;
                end

                if(Sum3[8] == 1'b1) begin
                    Result2 = 9'd255;
                    Result3 = 9'd255;
                end else begin
                    Result2 = Sum2;
                    Result3 = Sum3;
                end
                //result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            // Cần xem sét thêm bit dấu khi thực hiện phép trừ tràn số học với phần tử 8 bit (ALU_PSUB_H) và phần tử 8 bit có dấu (ALU_PASUB_H)
            ALU_PSUB_H: begin
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;
            end
            ALU_PASUB_H: begin
                //A0 = {A[7], A[7:0]};
                A1 = {A[15], A[15:8]};
                //A2 = {A[23], A[23:16]};
                A3 = {A[31], A[31:24]};
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;

                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};
            end
            // Cần xem sét thêm bit dấu khi thực hiện phép trừ tràn số học với phần tử 8 bit có dấu (ALU_PASUBU_H)
            ALU_PASUBU_H: begin
                //A0 = {A[7], A[7:0]};
                //A1 = {A[15], A[15:8]};
                //A2 = {A[23], A[23:16]};
                //A3 = {A[31], A[31:24]};
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{1'b0, B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{1'b0, B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;

                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};

            end
            ALU_PSSUB_H: begin
                //A0 = {A[7], A[7:0]};
                A1 = {A[15], A[15:8]};
                //A2 = {A[23], A[23:16]};
                A3 = {A[31], A[31:24]};
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;

                if(Sum1[8] == 1'b1 && Sum1[7] == 1'b0) begin
                    Result0 = 9'd0;
                    Result1= -9'sd128;
                end else if (Sum1[8] == 1'b0 && Sum1[7] == 1'b1) begin
                    Result0 = 9'd255;
                    Result1 = 9'sd127;
                end else begin
                    Result0 = Sum0;
                    Result1 = Sum1;
                end

                if(Sum3[8] == 1'b1 && Sum3[7] == 1'b0) begin
                    Result2 = 9'd0;
                    Result3= -9'sd128;
                end else if (Sum3[8] == 1'b0 && Sum3[7] == 1'b1) begin
                    Result2 = 9'd255;
                    Result3 = 9'sd127;
                end else begin
                    Result2 = Sum2;
                    Result3 = Sum3;
                end

                //result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            ALU_PSSUBU_H: begin
                //A0 = {A[7], A[7:0]};
                //A1 = {A[15], A[15:8]};
                //A2 = {A[23], A[23:16]};
                //A3 = {A[31], A[31:24]};
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{1'b0, B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{1'b0, B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;

                if(Sum1[8] == 1'b1) begin
                    Result0 = 9'd0;
                    Result1 = 9'd0;
                end else begin
                    Result0 = Sum0;
                    Result1 = Sum1;
                end
                if(Sum3[8] == 1'b1) begin
                    Result2 = 9'd0;
                    Result3 = 9'd0;
                end else begin
                    Result2 = Sum2;
                    Result3 = Sum3;
                end

                //result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            ALU_PAS_HX: begin
                // rd_lo = a_even - b_odd
                B0 = {1'b0, ~B[23:16]};
                B1 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd + b_even
                B2 = {1'b0, B[7:0]};
                B3 = {1'b0, B[15:8]};
                CarryIn3 = CarryOut2;
            end
            ALU_PAAS_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even - b_odd
                B0 = {1'b0, ~B[23:16]};
                B1 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd + b_even
                B2 = {1'b0, B[7:0]};
                B3 = {B[15], B[15:8]};
                CarryIn3 = CarryOut2;

                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};
            end
            ALU_PSAS_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even - b_odd
                B0 = {1'b0, ~B[23:16]};
                B1 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd + b_even
                B2 = {1'b0, B[7:0]};
                B3 = {B[15], B[15:8]};
                CarryIn3 = CarryOut2;

                if (Sum1[8] == 1'b1 && Sum1[7] == 1'b0) begin
                    Result0 = 9'd0; Result1 = -9'sd128;
                end else if (Sum1[8] == 1'b0 && Sum1[7] == 1'b1) begin
                    Result0 = 9'd255; Result1 = 9'sd127;
                end

                if (Sum3[8] == 1'b1 && Sum3[7] == 1'b0) begin
                    Result2 = 9'd0; Result3 = -9'sd128;
                end else if (Sum3[8] == 1'b0 && Sum3[7] == 1'b1) begin
                    Result2 = 9'd255; Result3 = 9'sd127;
                end
            end
            ALU_PSA_HX: begin
                // rd_lo = a_even + b_odd
                B0 = {1'b0, B[23:16]};
                B1 = {1'b0, B[31:24]};
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd - b_even
                B2 = {1'b0, ~B[7:0]};
                B3 = ~{B[15], B[15:8]};
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;
            end
            ALU_PASA_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even + b_odd
                B0 = {1'b0, B[23:16]};
                B1 = {B[31], B[31:24]};
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd - b_even
                B2 = {1'b0, ~B[7:0]};
                B3 = ~{B[15], B[15:8]};
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;

                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};
            end
            ALU_PSSA_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even + b_odd
                B0 = {1'b0, B[23:16]};
                B1 = {B[31], B[31:24]};
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd - b_even
                B2 = {1'b0, ~B[7:0]};
                B3 = ~{B[15], B[15:8]};
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;

                if (Sum1[8] == 1'b1 && Sum1[7] == 1'b0) begin
                    Result0 = 9'd0; Result1 = -9'sd128;
                end else if (Sum1[8] == 1'b0 && Sum1[7] == 1'b1) begin
                    Result0 = 9'd255; Result1 = 9'sd127;
                end

                if (Sum3[8] == 1'b1 && Sum3[7] == 1'b0) begin
                    Result2 = 9'd0; Result3 = -9'sd128; // Cần xem xét kỹ lại giá trị trả về khi tràn số học với phần tử 8 bit có dấu (ALU_PSSA_HX)
                end else if (Sum3[8] == 1'b0 && Sum3[7] == 1'b1) begin
                    Result2 = 9'd255; Result3 = 9'sd127;
                end
            end
            ALU_PMSEQ_H: begin
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if ({Sum1[7:0], Sum0[7:0]} == 16'd0) begin
                    Result1 = 9'd255; Result0 = 9'd255;
                end else begin
                    Result1 = 9'd0; Result0 = 9'd0;
                end
                if ({Sum3[7:0], Sum2[7:0]} == 16'd0) begin
                    Result3 = 9'd255; Result2 = 9'd255;
                end else begin
                    Result3 = 9'd0; Result2 = 9'd0;
                end
            end
            ALU_PMSLT_H: begin

                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};

                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if (Sum1[7] ^ ((A[15] ^ B[15]) & (A[15] ^ Sum1[7]))) begin
                    Result1 = 9'd255; Result0 = 9'd255;
                end else begin
                    Result1 = 9'd0; Result0 = 9'd0;
                end
                if (Sum3[7] ^ ((A[31] ^ B[31]) & (A[31] ^ Sum3[7]))) begin
                    Result3 = 9'd255; Result2 = 9'd255;
                end else begin
                    Result3 = 9'd0; Result2 = 9'd0;
                end
            end
            ALU_PMSLTU_H: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};

                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if (~Sum1[8]) begin
                    Result1 = 9'h0FF; Result0 = 9'h0FF;
                end else begin
                    Result1 = 9'd0; Result0 = 9'd0;
                end
                if (~Sum3[8]) begin
                    Result3 = 9'h0FF; Result2 = 9'h0FF;
                end else begin
                    Result3 = 9'd0; Result2 = 9'd0;
                end
            end
            ALU_PMIN_H: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};

                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if (Sum1[7] ^ ((A[15] ^ B[15]) & (A[15] ^ Sum1[7]))) begin // A < B
                    Result0 = {1'b0, A[7:0]}; Result1 = {1'b0, A[15:8]};
                end else begin
                    Result0 = {1'b0, B[7:0]}; Result1 = {1'b0, B[15:8]};
                end
                if (Sum3[7] ^ ((A[31] ^ B[31]) & (A[31] ^ Sum3[7]))) begin // A < B
                    Result2 = {1'b0, A[23:16]}; Result3 = {1'b0, A[31:24]};
                end else begin
                    Result2 = {1'b0, B[23:16]}; Result3 = {1'b0, B[31:24]};
                end
            end
            ALU_PMINU_H: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};

                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if (~Sum1[8]) begin
                    Result0 = {1'b0, A[7:0]}; Result1 = {1'b0, A[15:8]};
                end else begin
                    Result0 = {1'b0, B[7:0]}; Result1 = {1'b0, B[15:8]};
                end
                if (~Sum3[8]) begin
                    Result2 = {1'b0, A[23:16]}; Result3 = {1'b0, A[31:24]};
                end else begin
                    Result2 = {1'b0, B[23:16]}; Result3 = {1'b0, B[31:24]};
                end
            end
            ALU_PMAX_H: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};

                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if (Sum1[7] ^ ((A[15] ^ B[15]) & (A[15] ^ Sum1[7]))) begin // A < B
                    Result0 = {1'b0, B[7:0]}; Result1 = {1'b0, B[15:8]};
                end else begin
                    Result0 = {1'b0, A[7:0]}; Result1 = {1'b0, A[15:8]};
                end
                if (Sum3[7] ^ ((A[31] ^ B[31]) & (A[31] ^ Sum3[7]))) begin // A < B
                    Result2 = {1'b0, B[23:16]}; Result3 = {1'b0, B[31:24]};
                end else begin
                    Result2 = {1'b0, A[23:16]}; Result3 = {1'b0, A[31:24]};
                end
            end
            ALU_PMAXU_H: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};

                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if (~Sum1[8]) begin
                    Result0 = {1'b0, B[7:0]}; Result1 = {1'b0, B[15:8]};
                end else begin
                    Result0 = {1'b0, A[7:0]}; Result1 = {1'b0, A[15:8]};
                end
                if (~Sum3[8]) begin
                    Result2 = {1'b0, B[23:16]}; Result3 = {1'b0, B[31:24]};
                end else begin
                    Result2 = {1'b0, A[23:16]}; Result3 = {1'b0, A[31:24]};
                end
            end
            ALU_PSABS_H: begin
                A0 = 9'd0; A1 = 9'd0; A2 = 9'd0; A3 = 9'd0;
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;

                if (A[15:0] == 16'h8000) begin
                    Result1 = 9'h07F; Result0 = 9'h0FF;
                end else if (A[15] == 1'b1) begin
                    Result1 = Sum1; Result0 = Sum0;
                end else begin
                    Result0 = {1'b0, A[7:0]}; Result1 = {1'b0, A[15:8]};
                end

                if (A[31:16] == 16'h8000) begin
                    Result3 = 9'h07F; Result2 = 9'h0FF;
                end else if (A[31] == 1'b1) begin
                    Result3 = Sum3; Result2 = Sum2;
                end else begin
                    Result2 = {1'b0, A[23:16]}; Result3 = {1'b0, A[31:24]};
                end
            end
            default: begin
            end

        endcase
    end 

endmodule
