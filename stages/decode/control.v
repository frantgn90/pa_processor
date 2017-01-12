`ifndef _control
`define _control

`include "../../define.v"

module control (
    clk,
    stall,
    opcode,
    regwrite,	// WB Stage: Register write permission
    memtoreg,	// WB Stage: Rules the mux that says if the data to the register comes from mem (1) or from the ALU (0)
    branch,		// M Stage: Govern the Fetch stage mux for PC
    memwrite,	// M Stage: If the memory will be written or not
    memread,	// M Stage: If the memory will be readed or not
    byteword,	// M Stage: If it is a byte (0) or world (1) load/store
    alusrc		// EX stage: src2 source mux govern
);
	// Input signals
   input clk;
   input       stall;
   input [5:0] opcode;

	// Output signals
	output reg regwrite;
	output reg branch;
	output reg alusrc;
	output reg byteword;
	output reg memwrite;
	output reg memread;
	output reg memtoreg;

	always @(posedge clk) begin
        if (stall) begin
            regwrite 	<= 0;
			memtoreg 	<= "X";
			branch		<= "X";
			memwrite 	<= 0;
			memread 	<= 0;
			byteword 	<= "X";
			alusrc 		<= "X";
        end
        else begin
            case (opcode)
            `OP_RTYPE: begin
                regwrite 	<= 1;
                memtoreg 	<= 0;
                branch		<= 0;
                memwrite 	<= 0;
                memread 	<= 0;
                byteword 	<= "X";
                alusrc 		<= 1;
            end
            `OP_LDB: begin
                regwrite 	<= 1;
                memtoreg 	<= 1;
                branch		<= 0;
                memwrite 	<= 0;
                memread 	<= 1;
                byteword 	<= 0;
                alusrc 		<= 0;
            end
            `OP_LDW: begin
                regwrite 	<= 1;
                memtoreg 	<= 1;
                branch		<= 0;
                memwrite 	<= 0;
                memread 	<= 1;
                byteword 	<= 1;
                alusrc 		<= 0;
            end
            `OP_STB: begin
                regwrite 	<= 0;
                memtoreg 	<= "X";
                branch		<= 0;
                memwrite 	<= 1;
                memread 	<= 0;
                byteword 	<= 0;
                alusrc 		<= 0;
            end
            `OP_STW: begin
                regwrite 	<= 0;
                memtoreg 	<= "X";
                branch		<= 0;
                memwrite 	<= 1;
                memread 	<= 0;
                byteword 	<= 1;
                alusrc 		<= 0;
            end
            `OP_BEQ: begin
                regwrite 	<= 0;
                memtoreg 	<= "X";
                branch		<= 1;
                memwrite 	<= 0;
                memread 	<= 0;
                byteword 	<= "X";
                alusrc 		<= 1;
            end
            `OP_JUMP: begin
                regwrite 	<= 0;
                memtoreg 	<= "X";
                branch		<= 0;
                memwrite 	<= 0;
                memread 	<= 0;
                byteword 	<= "X";
                alusrc 		<= "X";
            end
            /*
            JUMP AND IRET NOT DONE
            */
            /*`OPCODE_TLBWRITE: 
            begin
                `WARNING(("[CONTROL] Unknown OPCODE signal %x", opcode))
            end
            default: 
            begin
                `WARNING(("[CONTROL] Unknown OPCODE signal %x", opcode))
            end*/
            default: begin
                regwrite 	<= 0;
                memtoreg 	<= "X";
                branch		<= 0;
                memwrite 	<= 0;
                memread 	<= 0;
                byteword 	<= "X";
                alusrc 		<= "X";
            end
            endcase
        end
	end
endmodule

`endif
