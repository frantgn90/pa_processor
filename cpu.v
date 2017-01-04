`ifndef _cpu
 `define _cpu

 `include "define.v"
 `include "stages/fetch/pc.v"
 `include "stages/fetch/fetch.v"
 `include "stages/exec/exec1.v"
 `include "stages/exec/M1.v"
 `include "stages/exec/M2.v"
 `include "stages/exec/M3.v"
 `include "stages/exec/M4.v"
 `include "stages/exec/M5.v"
 `include "memory/memory_sync.v"
 `include "cache/cache.v"
 `include "stages/decode/decode_top.v"
 `include "stages/decode/regfile.v"




module cpu(
	         input wire                  clk,
	         input wire                  reset,
	         // Memory ports
	         output wire                 mem_enable,
	         output wire                 mem_rw,
	         input wire                  mem_ack,
	         output wire [`REG_SIZE-1:0] mem_addr,
	         input wire [`WIDTH-1:0]     mem_data_out,
	         output wire [`WIDTH-1:0]    mem_data_in
           );

   //WRITE BACK STAGE
   wire [`REG_ADDR-1:0]                wreg; //destination register
   wire [`REG_SIZE-1:0]                wdata; //result to write
   wire                                regwrite; //write permission



   wire                                if_is_jump;
   wire                                if_is_branch;
   wire                                if_is_exception;
   wire [`ADDR_SIZE-1:0]               if_pc_jump;
   wire [`ADDR_SIZE-1:0]               if_branch;
   wire [`ADDR_SIZE-1:0]               if_old_pc;
   wire [`ADDR_SIZE-1:0]               if_new_pc;

   fetch fetch(
               .clk(clk),
               .is_jump(if_is_jump),
               .is_branch(if_is_branch),
               .is_exception(if_is_exception),
               .reset(reset),
               .pc_jump(if_pc_jump),
               .pc_branch(if_branch),
               .old_pc(if_old_pc),
               .new_pc(if_new_pc)
               );

   wire                                ic_is_byte;
   wire [`REG_SIZE-1:0]                ic_data_out;
   wire [`REG_SIZE-1:0]                ic_memresult;
   wire                                ic_hit;
   wire                                ic_mem_read_req;
   wire [`REG_SIZE-1:0]                ic_mem_read_addr;
   wire [`WIDTH-1:0]                   ic_mem_read_data;
   wire                                ic_mem_read_ack;


   cache Icache(
                .clk(clk),
                .reset(reset),
                .addr(if_new_pc),
	              .do_read(1'b1),
	              .is_byte(ic_is_byte),
	              .do_write(1'b0),
	              .data_in(0),
	              .data_out(ic_memresult),
	              .hit(ic_hit),
	              .mem_read_req(ic_mem_read_req),
	              .mem_read_addr(ic_mem_read_addr),
	              .mem_read_data(ic_mem_read_data),
	              .mem_read_ack(ic_mem_read_ack)
                );

   regfile registers(
                     .clk(clk),
                     .rreg1(),//address register1
                     .rreg2(),
                     .wreg(wreg),//destination register
                     .wdata(wdata),//data to write
                     .regwrite(regwrite),//write permission
                     .rdata1(), //Data form register1
                     .radat2()
                     );




   //WIRE TO COME FROM DECODE TO EXEC1 AND M1:
   //exec1
   wire                                regwrite_in;
   wire                                alusrc;
   wire [`REG_SIZE-1:0]                immediat;
   wire [`ADDR_SIZE-1:0]               old_pc;

   //M1:
   wire                                regwrite_mult_in;

   //M1 and exec1
   wire [`REG_SIZE-1:0]                src1;
   wire [`REG_SIZE-1:0]                src2;
   wire [`REG_ADDR-1:0]                alu_wreg_in;
   wire [4:0]                          aluop;
   wire [`REG_SIZE-1:0]                alu_regwrite;

   exec1 exec1(
	             .clk(clk),
	             .regwrite_in(regwrite_in),
	             .alusrc(alusrc),
	             .aluop(aluop),
               .src1(src1),
               .reg2(reg2),
               .immediat(immediat),
               .old_pc(old_pc),
	             .wreg_in(alu_wreg_in),

	             .regwrite_out(alu_regwrite),
               .zero(zero),
               .overflow(oveflow),
               .alu_result(alu_result),
               .pc_branch(pc_branch),
               .wreg_out(alu_wreg_out)
               );


   wire                                regwrite_out1;
   wire                                m1zero;
   wire                                m1overflow;
   wire [`REG_ADDR-1:0]                M1wreg_out;
   wire [`REG_SIZE-1:0]                m1result;

   M1 M1(
	       .clk(clk),
	       .regwrite_mult_in(regwrite_mult_in),
	       .wreg_in(wreg_in),
         .aluop(aluop),
         .src1(src1),
         .src2(src2),
	    
	       .regwrite_out(regwrite_out1),
         .m1zero(m1zero),
         .m1overflow(m1overflow),
	       .wreg_out(M1wreg_out),
	       .m1result(m1result)
         );

   wire                                regwrite_out2;
   wire                                m2zero;
   wire                                m2overflow;
   wire [`REG_SIZE-1:0]                m2result;
   wire [`REG_ADDR-1:0]                M2wreg_out;

   M2 M2(
	       .clk(clk),
	       .regwrite_mult_in(regwrite_out1),
         .pre_m1result(m1result),
         .pre_zero(m1zero),
         .pre_overflow(m1overflow),
         .wreg_in(M1wreg_out),

         .regwrite_out(regwrite_out2),
         .zero(m2zero),
         .overflow(m2overflow),
	       .m2result(m2result),
         .wreg_out(M2wreg_out)
	       );

   wire                                regwrite_out3;
   wire                                m3zero;
   wire                                m3overflow;
   wire [`REG_SIZE-1:0]                m3result;
   wire [`REG_ADDR-1:0]                M3wreg_out;

   M3 M3(
	       .clk(clk),
	       .regwrite_mult_in(regwrite_out2),
         .pre_m2result(m2result),
         .pre_zero(m2zero),
         .pre_overflow(m2overflow),
         .wreg_in(M2wreg_out),

         .regwrite_out(regwrite_out3),
         .zero(m3zero),
         .overflow(m3overflow),
	       .m3result(m3result),
         .wreg_out(M3wreg_out)
	       );
	 
   wire                                regwrite_out4;
   wire                                m4zero;
   wire                                m4overflow;
   wire [`REG_SIZE-1:0]                m4result;
   wire [`REG_ADDR-1:0]                M4wreg_out;

   M4 M4(
	       .clk(clk),
	       .regwrite_mult_in(regwrite_out3),
         .pre_m3result(m3result),
         .pre_zero(m3zero),
         .pre_overflow(m4overflow),
         .wreg_in(M3wreg_out),

         .regwrite_out(regwrite_out4),
         .zero(m4zero),
         .overflow(m4overflow),
	       .m4result(m4result),
         .wreg_out(M4wreg_out)
	       );

   wire                                regwrite_out5;
   wire                                m5zero;
   wire                                m5overflow;
   wire [`REG_SIZE-1:0]                m5result;
   wire [`REG_ADDR-1:0]                M5wreg_out;

	 
   M5 M5(
	       .clk(clk),
	       .regwrite_mult_in(regwrite_out4),
         .pre_m4result(m4result),
         .pre_zero(m4zero),
         .pre_overflow(m4overflow),
         .wreg_in(M4wreg_out),

         .regwrite_out(regwrite_out5),
         .zero(m5zero),
         .overflow(m5overflow),
	       .m5result(m5result),
         .wreg_out(M5wreg_out)
	       );

   //MEM STAGE
   reg [`REG_ADDR-1:0]                     dc_wreg_out;
   reg [`REG_SIZE-1:0]                     dc_wdata;
   reg                                 dc_regwrite;


   wire                                dc_do_read;
   wire                                dc_is_byte;
   wire                                dc_is_write;
   wire [`REG_SIZE-1:0]                dc_data_in;
   wire [`REG_SIZE-1:0]                dc_data_out;
   wire [`REG_SIZE-1:0]                dc_memresult;
   wire                                dc_hit;

   wire                                dc_mem_write_req;
   wire [`REG_SIZE-1:0]                dc_mem_write_addr;
   wire [`WIDTH-1:0]                   dc_mem_write_data;
   wire                                dc_mem_write_ack;

   wire                                dc_mem_read_req;
   wire [`REG_SIZE-1:0]                dc_mem_read_addr;
   wire [`WIDTH-1:0]                   dc_mem_read_data;
   wire                                dc_mem_read_ack;

   cache Dcache(
                .clk(clk),
                .reset(reset),
                .addr(alu_result),
	              .do_read(dc_do_read),
	              .is_byte(dc_is_byte),
	              .do_write(dc_is_write),
	              .data_in(dc_data_in),
	              .data_out(dc_memresult),
	              .hit(dc_hit),
	              .mem_write_req(dc_mem_write_req),
	              .mem_write_addr(dc_mem_write_addr),
	              .mem_write_data(dc_mem_write_data),
	              .mem_write_ack(dc_mem_write_ack),
	              .mem_read_req(dc_mem_read_req),
	              .mem_read_addr(dc_mem_read_addr),
	              .mem_read_data(dc_mem_read_data),
	              .mem_read_ack(dc_mem_read_ack)
                );
   //ARBITER
   Arbiter Arbiter(
                   .clk(clk),
		               .reset(reset),
		               .ic_read_req(ic_read_req),
		               .ic_read_ack(ic_read_ack),
		               .ic_read_addr(ic_read_addr),
		               .ic_read_data(ic_read_data),

		               .dc_read_req(dc_read_req),
		               .dc_read_ack(dc_read_ack),
		               .dc_read_addr(dc_read_addr),
		               .dc_read_data(dc_read_data),

		               .dc_write_req(dc_write_req),
		               .dc_write_ack(dc_write_ack),
		               .dc_write_addr(dc_write_addr),
		               .dc_write_data(dc_write_data),

		               .mem_enable(mem_enable),
		               .mem_rw(mem_rw),
		               .mem_ack(mem_ack),
		               .mem_addr(mem_addr),
		               .mem_data_in(mem_data_out),
		               .mem_data_out(mem_data_in)
                   );

always @(posedge clk) begin
   dc_wreg_out <= alu_wreg_out;
   dc_regwrite <= alu_regwrite;
   dc_wdata <= dc_do_read? dc_data_out : alu_result;

end

   assign wb_wreg = dc_regwrite? dc_wreg_out : M5wreg_out;
   assign wb_wdata = dc_regwrite? dc_memresult : m5result;
   assign regwrite = regwrite_out5 | dc_regwrite;

endmodule
`endif
