module ALUP(
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [31:0] ACC, // 3rd operand for Multiply-Accumulate cases (rd_data)
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

    logic signed [8:0] mac_a0, mac_a1, mac_a2, mac_a3;
    logic signed [8:0] mac_b0, mac_b1, mac_b2, mac_b3;
    logic [31:0] mac_out;

    Mac8_Unit alupext_mac8 (
        .A0(mac_a0), .A1(mac_a1), .A2(mac_a2), .A3(mac_a3),
        .B0(mac_b0), .B1(mac_b1), .B2(mac_b2), .B3(mac_b3),
        .ACC(ACC),
        .MacOut(mac_out)
    );

    // P-Extension Clip operation variables
    logic [15:0] clip_upper_limit;
    logic [15:0] clip_lower_limit;
    logic [15:0] mask_val_lo, mask_val_hi;
    logic pos_ov_lo, neg_ov_lo, pos_ov_hi, neg_ov_hi;

    always_comb begin
        mac_a0 = '0; mac_a1 = '0; mac_a2 = '0; mac_a3 = '0;
        mac_b0 = '0; mac_b1 = '0; mac_b2 = '0; mac_b3 = '0;
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};

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

                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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

                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            ALU_PADD_H: begin
                //CarryIn0 = 1'b0;
                CarryIn1 = CarryOut0;
                //CarryIn2 = 1'b0;
                CarryIn3 = CarryOut2;
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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

                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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

                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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

                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
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
                result = {Result3[7:0], Result2[7:0], Result1[7:0], Result0[7:0]};
            end
            ALU_PSATI_H: begin
                // Compute limits
                clip_upper_limit = (16'd1 << B[3:0]) - 16'd1;
                clip_lower_limit = ~(clip_upper_limit);

                // Mask values (in & ~upperLimit)
                mask_val_lo = A[15:0]  & clip_lower_limit; // clip_lower_limit == ~upperLimit
                mask_val_hi = A[31:16] & clip_lower_limit;

                // Detect overflow using SimdClip mask logic
                pos_ov_lo = (mask_val_lo != 16'd0) && (A[15] == 1'b0);
                neg_ov_lo = (mask_val_lo != clip_lower_limit) && (A[15] == 1'b1);
                
                pos_ov_hi = (mask_val_hi != 16'd0) && (A[31] == 1'b0);
                neg_ov_hi = (mask_val_hi != clip_lower_limit) && (A[31] == 1'b1);

                // Mux out the clamped value
                Result01 = pos_ov_lo ? clip_upper_limit : (neg_ov_lo ? clip_lower_limit : A[15:0]);
                Result23 = pos_ov_hi ? clip_upper_limit : (neg_ov_hi ? clip_lower_limit : A[31:16]);
                
                // vxsat update is ignored for now per user option 2
                result = {Result23, Result01};
            end
            ALU_PUSATI_H: begin
                // Compute limits
                clip_upper_limit = (16'd1 << B[3:0]) - 16'd1;
                clip_lower_limit = 16'd0;

                // Mask values (in & ~upperLimit)
                mask_val_lo = A[15:0]  & (~clip_upper_limit);
                mask_val_hi = A[31:16] & (~clip_upper_limit);

                // Detect overflow
                // In unsigned clipping, any negative number (sign bit == 1) causes neg_ov!
                pos_ov_lo = (mask_val_lo != 16'd0) && (A[15] == 1'b0);
                neg_ov_lo = (A[15] == 1'b1);
                
                pos_ov_hi = (mask_val_hi != 16'd0) && (A[31] == 1'b0);
                neg_ov_hi = (A[31] == 1'b1);

                // Mux out
                Result01 = pos_ov_lo ? clip_upper_limit : (neg_ov_lo ? clip_lower_limit : A[15:0]);
                Result23 = pos_ov_hi ? clip_upper_limit : (neg_ov_hi ? clip_lower_limit : A[31:16]);
                
                result = {Result23, Result01};
            end
            ALU_PM4ADDA_B: begin
                mac_a0 = $signed({A[7], A[7:0]}); mac_b0 = $signed({B[7], B[7:0]});
                mac_a1 = $signed({A[15], A[15:8]}); mac_b1 = $signed({B[15], B[15:8]});
                mac_a2 = $signed({A[23], A[23:16]}); mac_b2 = $signed({B[23], B[23:16]});
                mac_a3 = $signed({A[31], A[31:24]}); mac_b3 = $signed({B[31], B[31:24]});
                result = mac_out;
            end
            ALU_PM4ADDASU_B: begin
                mac_a0 = $signed({A[7], A[7:0]}); mac_b0 = $signed({1'b0, B[7:0]});
                mac_a1 = $signed({A[15], A[15:8]}); mac_b1 = $signed({1'b0, B[15:8]});
                mac_a2 = $signed({A[23], A[23:16]}); mac_b2 = $signed({1'b0, B[23:16]});
                mac_a3 = $signed({A[31], A[31:24]}); mac_b3 = $signed({1'b0, B[31:24]});
                result = mac_out;
            end
            ALU_PM4ADDAU_B: begin
                mac_a0 = $signed({1'b0, A[7:0]}); mac_b0 = $signed({1'b0, B[7:0]});
                mac_a1 = $signed({1'b0, A[15:8]}); mac_b1 = $signed({1'b0, B[15:8]});
                mac_a2 = $signed({1'b0, A[23:16]}); mac_b2 = $signed({1'b0, B[23:16]});
                mac_a3 = $signed({1'b0, A[31:24]}); mac_b3 = $signed({1'b0, B[31:24]});
                result = mac_out;
            end
            default: begin
            end

        endcase
    end 

endmodule

module Mac8_Unit(
    input  logic signed [8:0] A0, A1, A2, A3,
    input  logic signed [8:0] B0, B1, B2, B3,
    input  logic [31:0]       ACC,
    output logic [31:0]       MacOut
);
    logic signed [31:0] sum0, sum1, sum2, sum3;
    
    always_comb begin
        sum0 = 32'(A0 * B0);
        sum1 = 32'(A1 * B1);
        sum2 = 32'(A2 * B2);
        sum3 = 32'(A3 * B3);
        MacOut = ACC + sum0 + sum1 + sum2 + sum3;
    end
endmodule
