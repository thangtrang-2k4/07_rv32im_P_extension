module sync_fifo #(
   parameter integer DATA_WIDTH = 8,
   parameter integer DEPTH      = 8,
   parameter         AF_LEVEL   = 1,
   parameter         AE_LEVEL   = 1
)(
   // input
   input  wire                       clk,
   input  wire                       sclr_n,
   input  wire                       aclr_n,
   input  wire [DATA_WIDTH-1:0]      din,
   input  wire                       wr_en,
   input  wire                       rd_en,

   // output
   output wire [DATA_WIDTH-1:0]      dout,
   output reg                        full,
   output reg                        almost_full,
   output reg                        empty,
   output reg                        almost_empty,
   output reg                        overflow,
   output reg  [$clog2(DEPTH+1)-1:0] usedw
);

   // Register File
   reg  [DATA_WIDTH-1:0] mem [0:DEPTH-1];
   
   // Control
   reg                        wr_allow;
   reg                        rd_allow;

   reg  [$clog2(DEPTH)-1:0]   wr_ptr;
   reg  [$clog2(DEPTH)-1:0]   wr_ptr_next;
   reg  [$clog2(DEPTH)-1:0]   rd_ptr;
   reg  [$clog2(DEPTH)-1:0]   rd_ptr_next;

   reg                        full_next;
   reg                        almost_full_next;
   reg                        empty_next;
   reg                        almost_empty_next;
   reg                        overflow_next;
   reg  [$clog2(DEPTH+1)-1:0] usedw_next;

   // FIFO control
   always @(*) begin
       rd_allow = rd_en && !empty;
       wr_allow = wr_en && !full;
   
       wr_ptr_next = wr_ptr;
       rd_ptr_next = rd_ptr;
       usedw_next  = usedw;
       overflow_next = overflow;

       case ({wr_allow, rd_allow})
           2'b01: begin
               rd_ptr_next = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
               usedw_next  = usedw - 1;
           end
           2'b10: begin
               wr_ptr_next = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
               usedw_next  = usedw + 1;
           end
           2'b11: begin
               wr_ptr_next = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
               rd_ptr_next = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
               // usedw_next giữ nguyên
           end
           default: ; // 2'b00 không làm gì
       endcase
   
       overflow_next = 1'b0;
       if (wr_en && full && !rd_en)
           overflow_next = 1'b1;
   
       full_next         = (usedw_next == DEPTH);
       almost_full_next  = (usedw_next >= DEPTH - AF_LEVEL);
       empty_next        = (usedw_next == 0);
       almost_empty_next = (usedw_next <= AE_LEVEL);
   end

   always @(posedge clk or negedge aclr_n) begin

      if(!aclr_n) begin 
         wr_ptr       <= '0;
         rd_ptr       <= '0;
         full         <= 1'b0;
         almost_full  <= 1'b0;
         empty        <= 1'b1;
         almost_empty <= 1'b1;
         overflow     <= 1'b0;
         usedw        <= '0;
      end
      else if (!sclr_n) begin 
         wr_ptr       <= '0;
         rd_ptr       <= '0;
         full         <= 1'b0;
         almost_full  <= 1'b0;
         empty        <= 1'b1;
         almost_empty <= 1'b1;
         overflow     <= 1'b0;
         usedw        <= '0;
      end
      else begin 
         wr_ptr       <= wr_ptr_next;
         rd_ptr       <= rd_ptr_next;
         full         <= full_next;
         almost_full  <= almost_full_next;
         empty        <= empty_next; 
         almost_empty <= almost_empty_next;
         overflow     <= overflow_next;
         usedw        <= usedw_next;    
      end
   end

   // FIFO Register

   //always @(posedge clk or negedge aclr_n) begin
   //   if(!aclr_n) dout <= '0;
   //   else if (!sclr_n) dout <= '0;
   //   else begin 
   //      if(wr_allow) mem[wr_ptr] <= din;
   //      else mem[wr_ptr] <= mem[wr_ptr];

   //      if(rd_allow) dout <= mem[rd_ptr];
   //      else dout <= dout;
   //   end
   //end

   //always @(posedge clk or negedge aclr_n) begin
   //   if (!aclr_n) begin
   //      dout <= '0;
   //   end
   //   else if (!sclr_n) begin
   //      dout <= '0;
   //   end
   //   else begin
   //      // preload dout with head of FIFO
   //      if (!empty)
   //         dout <= mem[rd_ptr];
   //
   //      // write
   //      if (wr_allow)
   //         mem[wr_ptr] <= din;
   //   end
   //end

   always @(posedge clk) begin
      if (wr_allow) begin
         mem[wr_ptr] <= din;
      end
   end

   assign dout = mem[rd_ptr];
endmodule
