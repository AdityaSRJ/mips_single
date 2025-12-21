module earlyBranch	#(
			parameter	BEQZ  = 6'b001110,
					BNEQZ = 6'b001101
			 )
			(
			input	[5:0]IF_ID_opcode,
			input	[31:0]IF_ID_A_eff,
			output	takenBranch     // helps in deciding in the fetch stage whether to choose IF_ID_NPC
			);

assign takenBranch = ( IF_ID_opcode == BEQZ &&  IF_ID_A_eff == 0 )	||	(IF_ID_opcode == BNEQZ &&  IF_ID_A_eff != 0);


endmodule