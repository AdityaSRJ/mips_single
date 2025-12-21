module stallUnit #(
			parameter 	RR_ALU = 3'b000,
	  				RM_ALU = 3'b001,
	  				LOAD   = 3'b010,
	  				STORE  = 3'b011,
	  				BRANCH = 3'b100
		)
		(	
		input [4:0] IF_ID_srcA,
		input [4:0] IF_ID_srcB,
		input [2:0] EX_MEM_type,
		input [31:0] EX_MEM_IR,
		output reg [2:0] stallStage   // kept for future ref. Currently stall needed only in one scenario
		);
// 000: no stall
// 001: NOP passed to IF_ID
// 010: NOP passed to ID_EX		only this is usefull now
// 011: NOP passed to EX_MEM 			
// 100: NOP passed to MEM_WB
// 101: NOP passed to WB stage 
wire [4:0]EX_MEM_IR_dest;

assign EX_MEM_IR_dest	=	(EX_MEM_type==RR_ALU) ? EX_MEM_IR[15:11] : EX_MEM_IR[20:16];

always@(*)
begin
	

	if((EX_MEM_type == LOAD) && (IF_ID_srcA == EX_MEM_IR_dest	||	IF_ID_srcB == EX_MEM_IR_dest))	stallStage = 3'b010; // for LOAD-USE

	else stallStage = 3'b000;
		
end

endmodule
/*
----------------------------------------------------------------------------------
 STALL UNIT CONTROL CODES
----------------------------------------------------------------------------------
 The 'stallStage' output determines where a Bubble (NOP) is inserted.
 Any stage *below* the insertion point must be FROZEN to preserve its state.

 Value | Insert NOP into | Freeze These Registers (stallStage >= Value)
 ------|-----------------|--------------------------------------------------------
 3'd0  | None            | None
 3'd1  | IF_ID           | PC
 3'd2  | ID_EX           | IF_ID, PC
 3'd3  | EX_MEM          | ID_EX, IF_ID, PC
 3'd4  | MEM_WB          | EX_MEM, ID_EX, IF_ID, PC
 3'd5  | WB Stage        | MEM_WB, EX_MEM, ID_EX, IF_ID, PC

 IMPLEMENTATION GUIDE:
 1. FLUSH Logic (Bubble):
    if (stallStage == N) -> Force output Register[N] to NOP.

 2. FREEZE Logic (Hold):
    if (stallStage >= N) -> Disable Write/Update for Register[N-1].
----------------------------------------------------------------------------------
*/
