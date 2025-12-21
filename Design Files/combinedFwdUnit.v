module combForwardingUnit #(
 			parameter RR_ALU = 3'b000,
	  			  RM_ALU = 3'b001,
				  LOAD = 3'b010,
				  STORE  = 3'b011,
				  BRANCH = 3'b100
			)
			(  
			input [4:0]IF_ID_IR_rs,       	// consumer		 	
			input [31:0]EX_MEM_IR,		// producer1	
			input [2:0] EX_MEM_type,
			input [31:0]MEM_WB_IR,      	// producer2	
			input [2:0]MEM_WB_type,    	// if it is LMD is forwarded. Stall is inserted
			input  RegWriteEX,		// Verifies that inst will actually write in Reg: Store and Branch have destination
			input  RegWriteMEM,
			output reg[1:0]muxSelect        // muxA
			
			);




wire	[4:0]EX_MEM_IR_dest;
wire	[4:0]MEM_WB_IR_dest;


assign EX_MEM_IR_dest	=	(EX_MEM_type==RR_ALU) ? EX_MEM_IR[15:11] : EX_MEM_IR[20:16];
assign MEM_WB_IR_dest	=	(MEM_WB_type==RR_ALU) ? MEM_WB_IR[15:11] : MEM_WB_IR[20:16];


always@(*)
begin
	
		if(IF_ID_IR_rs == EX_MEM_IR_dest	&&	RegWriteEX && EX_MEM_type != LOAD)		muxSelect = 2'b01;

		else if((IF_ID_IR_rs == MEM_WB_IR_dest) && (MEM_WB_type == LOAD))	muxSelect = 2'b11; // LMD forwarded. stall to be added

		else if	(IF_ID_IR_rs == MEM_WB_IR_dest	&&	RegWriteMEM)		muxSelect = 2'b10;

		else									muxSelect = 2'b00;
		
end


endmodule