
            ALU_PMSEQ_H: begin
                B0 = {1'b0, ~B[7:0]};
                B1 = ~{B[15], B[15:8]};
                B2 = {1'b0, ~B[23:16]};
                B3 = ~{B[31], B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if ({Sum1[7:0], Sum0[7:0]} == 16'd0) begin
                    Result1 = 9'h0FF; Result0 = 9'h0FF;
                end else begin
                    Result1 = 9'd0; Result0 = 9'd0;
                end
                if ({Sum3[7:0], Sum2[7:0]} == 16'd0) begin
                    Result3 = 9'h0FF; Result2 = 9'h0FF;
                end else begin
                    Result3 = 9'd0; Result2 = 9'd0;
                end
            end
            ALU_PMSLT_H: begin
                B0 = ~{1'b0, B[7:0]};
                B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]};
                B3 = ~{1'b0, B[31:24]};
                CarryIn0 = 1'b1; CarryIn1 = CarryOut0;
                CarryIn2 = 1'b1; CarryIn3 = CarryOut2;
                if (Sum1[7] ^ ((A[15] ^ B[15]) & (A[15] ^ Sum1[7]))) begin
                    Result1 = 9'h0FF; Result0 = 9'h0FF;
                end else begin
                    Result1 = 9'd0; Result0 = 9'd0;
                end
                if (Sum3[7] ^ ((A[31] ^ B[31]) & (A[31] ^ Sum3[7]))) begin
                    Result3 = 9'h0FF; Result2 = 9'h0FF;
                end else begin
                    Result3 = 9'd0; Result2 = 9'd0;
                end
            end
            ALU_PMSLTU_H: begin
                B0 = ~{1'b0, B[7:0]}; B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]}; B3 = ~{1'b0, B[31:24]};
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
                B0 = ~{1'b0, B[7:0]}; B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]}; B3 = ~{1'b0, B[31:24]};
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
            ALU_PMAX_H: begin
                B0 = ~{1'b0, B[7:0]}; B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]}; B3 = ~{1'b0, B[31:24]};
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
            ALU_PMINU_H: begin
                B0 = ~{1'b0, B[7:0]}; B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]}; B3 = ~{1'b0, B[31:24]};
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
            ALU_PMAXU_H: begin
                B0 = ~{1'b0, B[7:0]}; B1 = ~{1'b0, B[15:8]};
                B2 = ~{1'b0, B[23:16]}; B3 = ~{1'b0, B[31:24]};
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
                B0 = ~{1'b0, A[7:0]}; B1 = ~{1'b0, A[15:8]};
                B2 = ~{1'b0, A[23:16]}; B3 = ~{1'b0, A[31:24]};
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