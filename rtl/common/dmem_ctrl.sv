// ================================================================
// DMemCtrl.sv
// Quản lý MEM stage load/store request, one-shot guard, stall signal
// ================================================================
module DMemCtrl (
    input  logic        clk,
    input  logic        rst_n,

    // ── Pipeline MEM stage inputs ──
    input  logic        i_is_load,        // ctrl_MEM.WBSel == WB_MEM
    input  logic        i_is_store,       // ctrl_MEM.MemRW
    input  logic [31:0] i_addr,           // alu_MEM
    input  logic [31:0] i_wdata,          // dataR2_MEM
    input  logic [1:0]  i_size,           // ctrl_MEM.MemSize
    input  logic        i_unsigned,       // ctrl_MEM.MemUnsigned

    // ── DMem bus ──
    output logic        o_dmem_stb,
    output logic        o_dmem_we,
    output logic [31:0] o_dmem_addr,
    output logic [31:0] o_dmem_wdata,
    output logic [1:0]  o_dmem_size,
    output logic        o_dmem_unsigned,
    input  logic        i_dmem_ack,
    input  logic [31:0] i_dmem_rdata,

    // ── Pipeline outputs ──
    output logic        o_mem_stall,      // freeze pipeline
    output logic [31:0] o_rdata           // read data passthrough
);

    logic dmem_pending;
    wire  is_mem_op = i_is_load || i_is_store;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dmem_pending <= 1'b0;
        else if (i_dmem_ack)
            dmem_pending <= 1'b0;
        else if (o_dmem_stb)
            dmem_pending <= 1'b1;
    end

    assign o_dmem_stb      = is_mem_op && !dmem_pending;
    assign o_mem_stall     = is_mem_op && !i_dmem_ack;

    // Passthrough (inputs stable from EX/MEM pipe_regs)
    assign o_dmem_we       = i_is_store;
    assign o_dmem_addr     = i_addr;
    assign o_dmem_wdata    = i_wdata;
    assign o_dmem_size     = i_size;
    assign o_dmem_unsigned = i_unsigned;
    assign o_rdata         = i_dmem_rdata;

endmodule
