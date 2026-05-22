// ================================================================
// IFetchCtrl.sv
// Quản lý IF stage fetch request, response buffer, PC tagging
// ================================================================
module IFetchCtrl (
    input  logic        clk,
    input  logic        rst_n,

    // ── Pipeline control inputs ──
    input  logic [31:0] i_pc,             // current PC from Program_Counter
    input  logic        i_pc_redirect,    // = PCSel (branch/jump taken)
    input  logic        i_pipe_accept,    // = !load_use_stall && !mem_stall

    // ── IMem bus ──
    output logic        o_imem_stb,       // request to IMem
    output logic [31:0] o_imem_addr,      // address to IMem
    input  logic        i_imem_ack,       // IMem response ready
    input  logic [31:0] i_imem_inst,      // instruction from IMem

    // ── Pipeline outputs ──
    output logic        o_inst_valid,     // instruction available
    output logic [31:0] o_inst,           // instruction data
    output logic [31:0] o_pc_req,         // PC that goes with this instruction
    output logic        o_pc_en           // PC register should advance
);

    // ── Registered state ──
    logic        fetch_pending;
    logic        fetch_kill;
    logic [31:0] pc_req_q;

    // ── Fetch response buffer ──
    logic        buf_valid;
    logic [31:0] buf_inst;
    logic [31:0] buf_pc;

    // ── Derived ──
    wire raw_valid = i_imem_ack && !fetch_kill;

    // ───────────────────────────────────
    // fetch_pending
    // ───────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fetch_pending <= 1'b0;
        else if (i_imem_ack)
            fetch_pending <= 1'b0;
        else if (o_imem_stb)
            fetch_pending <= 1'b1;
    end

    // ───────────────────────────────────
    // fetch_kill — discard wrong-path ack
    // ───────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fetch_kill <= 1'b0;
        else if (i_imem_ack)
            fetch_kill <= 1'b0;
        else if (i_pc_redirect && fetch_pending)
            fetch_kill <= 1'b1;
    end

    // ───────────────────────────────────
    // pc_req_q — tag PC with request
    // ───────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_req_q <= 32'h8000_0000;
        else if (o_imem_stb)
            pc_req_q <= i_pc;
    end

    // ───────────────────────────────────
    // Fetch response buffer
    // ───────────────────────────────────
    wire buf_drain = buf_valid && i_pipe_accept;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_valid <= 1'b0;
            buf_inst  <= 32'h00000013;
            buf_pc    <= 32'h8000_0000;
        end else if (i_pc_redirect) begin
            buf_valid <= 1'b0;                         // flush on redirect
        end else if (raw_valid && !i_pipe_accept && !buf_valid) begin
            buf_valid <= 1'b1;                         // capture ack
            buf_inst  <= i_imem_inst;
            buf_pc    <= pc_req_q;
        end else if (buf_drain) begin
            if (raw_valid) begin
                buf_inst  <= i_imem_inst;              // drain + refill
                buf_pc    <= pc_req_q;
            end else begin
                buf_valid <= 1'b0;                     // drain only
            end
        end
    end

    // ───────────────────────────────────
    // o_imem_stb — issue fetch request
    // ───────────────────────────────────
    // Depends ONLY on registered signals.
    // NOT gated by mem_stall or load_use_stall.
    assign o_imem_stb  = !fetch_pending && !buf_valid && !i_pc_redirect;
    assign o_imem_addr = i_pc;

    // ───────────────────────────────────
    // Pipeline outputs
    // ───────────────────────────────────
    assign o_inst_valid = buf_valid || raw_valid;
    assign o_inst       = buf_valid ? buf_inst : i_imem_inst;
    assign o_pc_req     = buf_valid ? buf_pc   : pc_req_q;
    assign o_pc_en      = o_imem_stb;

endmodule
