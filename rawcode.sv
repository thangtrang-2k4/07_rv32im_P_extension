            ALU_PAS_HX: begin
                // rd_lo = a_even - b_odd
                B0 = ~{1'b0, B[23:16]};
                B1 = ~{1'b0, B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd + b_even
                B2 = {1'b0, B[7:0]};
                B3 = {1'b0, B[15:8]};
                CarryIn3 = CarryOut2;
            end
            ALU_PSA_HX: begin
                // rd_lo = a_even + b_odd
                B0 = {1'b0, B[23:16]};
                B1 = {1'b0, B[31:24]};
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd - b_even
                B2 = ~{1'b0, B[7:0]};
                B3 = ~{1'b0, B[15:8]};
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;
            end
            ALU_PAAS_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even - b_odd
                B0 = ~{1'b0, B[23:16]};
                B1 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1;
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd + b_even
                B2 = {1'b0, B[7:0]};
                B3 = {B[15], B[15:8]};
                CarryIn3 = CarryOut2;

                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};
            end
            ALU_PASA_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even + b_odd
                B0 = {1'b0, B[23:16]};
                B1 = {B[31], B[31:24]};
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd - b_even
                B2 = ~{1'b0, B[7:0]};
                B3 = ~{B[15], B[15:8]};
                CarryIn2 = 1'b1;
                CarryIn3 = CarryOut2;

                result = {Result3[8:0], Result2[7:1], Result1[8:0], Result0[7:1]};
            end
            ALU_PSAS_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even - b_odd
                B0 = ~{1'b0, B[23:16]};
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
            ALU_PSSA_HX: begin
                A1 = {A[15], A[15:8]};
                A3 = {A[31], A[31:24]};
                
                // rd_lo = a_even + b_odd
                B0 = {1'b0, B[23:16]};
                B1 = {B[31], B[31:24]};
                CarryIn1 = CarryOut0;

                // rd_hi = a_odd - b_even
                B2 = ~{1'b0, B[7:0]};
                B3 = ~{B[15], B[15:8]};
                CarryIn2 = 1'b1;
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
            ALU_PMSEQ_H: begin
                {Result1[7:0], Result0[7:0]} = (A[15:0] == B[15:0]) ? 16'hFFFF : 16'h0000;
                {Result3[7:0], Result2[7:0]} = (A[31:16] == B[31:16]) ? 16'hFFFF : 16'h0000;
            end
            ALU_PMSLT_H: begin
                {Result1[7:0], Result0[7:0]} = ($signed(A[15:0]) < $signed(B[15:0])) ? 16'hFFFF : 16'h0000;
                {Result3[7:0], Result2[7:0]} = ($signed(A[31:16]) < $signed(B[31:16])) ? 16'hFFFF : 16'h0000;
            end
            ALU_PMSLTU_H: begin
                {Result1[7:0], Result0[7:0]} = (A[15:0] < B[15:0]) ? 16'hFFFF : 16'h0000;
                {Result3[7:0], Result2[7:0]} = (A[31:16] < B[31:16]) ? 16'hFFFF : 16'h0000;
            end
            ALU_PMIN_H: begin
                {Result1[7:0], Result0[7:0]} = ($signed(A[15:0]) < $signed(B[15:0])) ? A[15:0] : B[15:0];
                {Result3[7:0], Result2[7:0]} = ($signed(A[31:16]) < $signed(B[31:16])) ? A[31:16] : B[31:16];
            end
            ALU_PMAX_H: begin
                {Result1[7:0], Result0[7:0]} = ($signed(A[15:0]) > $signed(B[15:0])) ? A[15:0] : B[15:0];
                {Result3[7:0], Result2[7:0]} = ($signed(A[31:16]) > $signed(B[31:16])) ? A[31:16] : B[31:16];
            end
            ALU_PMINU_H: begin
                {Result1[7:0], Result0[7:0]} = (A[15:0] < B[15:0]) ? A[15:0] : B[15:0];
                {Result3[7:0], Result2[7:0]} = (A[31:16] < B[31:16]) ? A[31:16] : B[31:16];
            end
            ALU_PMAXU_H: begin
                {Result1[7:0], Result0[7:0]} = (A[15:0] > B[15:0]) ? A[15:0] : B[15:0];
                {Result3[7:0], Result2[7:0]} = (A[31:16] > B[31:16]) ? A[31:16] : B[31:16];
            end
            ALU_PSABS_H: begin
                if (A[15:0] == 16'h8000)
                    {Result1[7:0], Result0[7:0]} = 16'h7FFF;
                else if (A[15] == 1'b1)
                    {Result1[7:0], Result0[7:0]} = -A[15:0];
                else
                    {Result1[7:0], Result0[7:0]} = A[15:0];

                if (A[31:16] == 16'h8000)
                    {Result3[7:0], Result2[7:0]} = 16'h7FFF;
                else if (A[31] == 1'b1)
                    {Result3[7:0], Result2[7:0]} = -A[31:16];
                else
                    {Result3[7:0], Result2[7:0]} = A[31:16];
            end