module pipe_MIPS32 (clk , reset);

input clk;
input reset;    


// IF_ID
reg [31:0] PC, IF_ID_IR, IF_ID_NPC;

//ID_EX
reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm, ID_EX_Branch_NPC; 


// operand A : saved in all registers bcoz of ALU-Branch Hazard
reg [31:0] EX_MEM_A , MEM_WB_A;

// type
reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;

// EX_MEM
reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;


// MEM_WB
reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;


// Memories : 
reg [31:0] Reg [0:31];				// Register Bank	32x32 bits
reg [31:0] DataMem [0:1023], ProgMem[0:1023];	// Data Memory 		1024x32 bits
    						// Program Memory 	1024x32 bits

// Branch Target Pre-Evaluation
wire [31:0]Branch_NPC;		


// pass in parameter list: follow modern foramt
parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011,
	  SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111, LW = 6'b001000,
	  SW = 6'b001001, ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100,
	  MULI = 6'b001111, BNEQZ = 6'b001101, BEQZ = 6'b001110, NOP = 6'b011111;

parameter RR_ALU = 3'b000,
	  RM_ALU = 3'b001,
	  LOAD   = 3'b010,
	  STORE  = 3'b011,
	  BRANCH = 3'b100,
	  HALT   = 3'b101,
	  NO_OP  = 3'b110;


reg HALTED;		// SET SO THAT NO INST AFTER THIS IS ABLE TO WB OR ACCESS MEM 

// RegWrite Signals : Specify when Inst having a destination actually writes.
reg RegWriteEX;
reg RegWriteMEM;
reg RegWriteID;

// Forwarding Unit Output
wire [1:0] fwdA , fwdB;

// Forwarded Mux output
wire [31:0]Aeff , Beff;
wire [2:0] stall;

// earlyBranch Unit Output
wire	takenBranch;

always@(*)
begin
	case(EX_MEM_type)

	RR_ALU,RM_ALU,LOAD	:	RegWriteEX = 1'b1;	// EX stage writes
	default			:	RegWriteEX = 1'b0;

	endcase

	case(MEM_WB_type)

	RR_ALU,RM_ALU,LOAD	:	RegWriteMEM = 1'b1;	// MEM stage writes
	default			:	RegWriteMEM = 1'b0;

	endcase

	case(ID_EX_type)

	RR_ALU,RM_ALU,LOAD	:	RegWriteID = 1'b1;	// MEM stage writes
	default			:	RegWriteID = 1'b0;

	endcase
end

// custom forwarding unit ; forwards to ID not EX
combForwardingUnit#(
.RR_ALU	(RR_ALU),
.RM_ALU	(RM_ALU),
.LOAD	(LOAD),
.STORE	(STORE),
.BRANCH	(BRANCH)
)	muxSelectA
(
.IF_ID_IR_rs	(IF_ID_IR[25:21]),
.EX_MEM_IR	(EX_MEM_IR),
.EX_MEM_type	(EX_MEM_type),
.MEM_WB_IR	(MEM_WB_IR),
.MEM_WB_type	(MEM_WB_type),
.RegWriteEX	(RegWriteEX),
.RegWriteMEM	(RegWriteMEM),
.muxSelect	(fwdA)
);


combForwardingUnit#(
.RR_ALU	(RR_ALU),
.RM_ALU	(RM_ALU),
.LOAD	(LOAD),
.STORE	(STORE),
.BRANCH	(BRANCH)
)	muxSelectB
(
.IF_ID_IR_rs	(IF_ID_IR[20:16]),
.EX_MEM_IR	(EX_MEM_IR),
.EX_MEM_type	(EX_MEM_type),
.MEM_WB_IR	(MEM_WB_IR),
.MEM_WB_type	(MEM_WB_type),
.RegWriteEX	(RegWriteEX),
.RegWriteMEM	(RegWriteMEM),
.muxSelect	(fwdB)
);

// Mux with inputs as operands from all stages
mux4to1 muxA(
.in0	(Reg[IF_ID_IR[25:21]]), // actual oprand
.in1	(EX_MEM_ALUOut), 	// from EX
.in2	(MEM_WB_ALUOut), 	// from MEM
.in3	(MEM_WB_LMD), 		// from MEM for Load inst
.sel	(fwdA),
.out	(Aeff)
);


mux4to1 muxB(
.in0	(Reg[IF_ID_IR[20:16]]), 
.in1	(EX_MEM_ALUOut), 
.in2	(MEM_WB_ALUOut), 
.in3	(MEM_WB_LMD), 
.sel	(fwdB),
.out	(Beff)
);


// stallUnit for LOAD-USE stall
stallUnit#(
.RR_ALU	(RR_ALU),
.RM_ALU	(RM_ALU),
.LOAD	(LOAD),
.STORE	(STORE),
.BRANCH	(BRANCH)
) combStallUnit
(
.IF_ID_srcA	(IF_ID_IR[25:21]),
.IF_ID_srcB	(IF_ID_IR[20:16]),
.EX_MEM_type	(EX_MEM_type),
.EX_MEM_IR	(EX_MEM_IR),
.stallStage		(stall)
);

// earlyBranch Detection
earlyBranch#(
.BEQZ	(BEQZ),
.BNEQZ	(BNEQZ)) combBranchUnit
(
.IF_ID_opcode	(IF_ID_IR[31:26]),
.IF_ID_A_eff	(Aeff),
.takenBranch	(takenBranch)
);

assign #2	Branch_NPC ={ {16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]} } + IF_ID_NPC;

// IF STAGE
always @(posedge clk or posedge reset)
	if(reset)
	begin
		HALTED 		<= #2 0;
		PC 		<= #2 0;
		IF_ID_NPC 	<= #2 0;
		IF_ID_IR	<= #2 0;
		
	end
	else if(HALTED == 0 &&  ~(stall >= 3'd2) )
	begin

		if(stall == 3'd1)			// NOP inserted. Inst to be fetched again
		IF_ID_IR	<= #2 32'b0111_11xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
		

		else if( takenBranch )
		begin
			
			IF_ID_IR	<= #2 ProgMem[ID_EX_Branch_NPC];
			IF_ID_NPC	<= #2 ID_EX_Branch_NPC + 1;
			PC		<= #2 ID_EX_Branch_NPC + 1;    
	        end		
		
		else
		begin
		IF_ID_IR	<= #2 ProgMem[PC];
		IF_ID_NPC	<= #2 PC + 1;
		PC		<= #2 PC + 1;
		end
		
	end

// ID STAGE
always @(negedge clk or posedge reset)

	if(reset)	ID_EX_type 	<= #2 NO_OP;

	else if(HALTED == 0 &&  ~(stall >= 3'd3))
	begin   
		//rs
		if(IF_ID_IR[25:21] ==5'b00000)  ID_EX_A <= 0;
		else				ID_EX_A <= #2 Aeff;

		//rt
		if(IF_ID_IR[20:16] ==5'b00000)  ID_EX_B <= 0;
		else				ID_EX_B <= #2 Beff;

		ID_EX_Imm	<= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
		ID_EX_NPC	<= #2 IF_ID_NPC;
		ID_EX_IR	<= #2 IF_ID_IR;
		ID_EX_Branch_NPC<= #2 Branch_NPC;

		if(stall == 3'd2 ||takenBranch )		ID_EX_type <= #2 NO_OP;	// Branch has triggered the jump and now has no job left
		else
		case (IF_ID_IR[31:26])

		ADD, SUB, MUL, SLT, AND, OR	: 	ID_EX_type <= #2 RR_ALU;   // A & B 
		ADDI, SUBI, MULI, SLTI		:      	ID_EX_type <= #2 RM_ALU;   // A & IMM
		LW				:	ID_EX_type <= #2 LOAD;	   // A & IMM
		SW				:	ID_EX_type <= #2 STORE;	   // A & IMM Data in B
		BNEQZ, BEQZ			:	ID_EX_type <= #2 NO_OP ;   // NPC & IMM	// FALSE BRANCH EQUIVALENT TO NO_OP	
		NOP				:	ID_EX_type <= #2 NO_OP;	   // NOTHING
		HLT				:	ID_EX_type <= #2 HALT;	   // NOTHING
		default				:	ID_EX_type <= #2 HALT;

		endcase
end


//EX STAGE
always @ (posedge clk or posedge reset)

	if(reset)	EX_MEM_type 	<= #2 NO_OP;
	
	else if(HALTED == 0  && ~(stall >= 3'd4))
	begin
		if(stall == 3'd3 )	EX_MEM_type	<= #2 NO_OP;   
		else			EX_MEM_type	<= #2 ID_EX_type;
		
		EX_MEM_IR	<= #2 ID_EX_IR;
		EX_MEM_A	<= #2 ID_EX_A;


		case (ID_EX_type)
		
		  RR_ALU: // reg_reg alu
			  begin
				case (ID_EX_IR[31:26])
				  ADD:		EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
				  SUB: 		EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
				  MUL: 		EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
				  AND: 		EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
				  OR: 		EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
				  SLT: 		EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;
				  default:	EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
				endcase
			  end
		
		  RM_ALU: // reg imm alu
			  begin
				case (ID_EX_IR[31:26])
				  ADDI:		EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
				  SUBI:		EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
			          SLTI:		EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm;
				  default:	EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
				endcase
			  end

		  LOAD, STORE:  // mem reference
			   begin
			       	    EX_MEM_ALUOut	<= #2 ID_EX_A + ID_EX_Imm;
				    EX_MEM_B		<= #2 ID_EX_B;
			   end
	  
		 
		endcase
	end

//MEM STAGE		3 cases : 

always @(posedge clk or posedge reset)

	if(reset)		MEM_WB_type		<= #2 NO_OP;

	else if(HALTED == 0)		// NOP insertion nver needed in WB stage so need to freeze this one.
	begin

		if(stall == 3'd4)	MEM_WB_type <= #2 NO_OP;
		else 			MEM_WB_type <= #2 EX_MEM_type;

		MEM_WB_IR   <= #2 EX_MEM_IR;
		MEM_WB_A    <= #2 EX_MEM_A;	
		case (EX_MEM_type)

			RR_ALU, RM_ALU	:	MEM_WB_ALUOut 		<= #2 EX_MEM_ALUOut;

			LOAD		:	MEM_WB_LMD		<= #2 DataMem[EX_MEM_ALUOut];

			STORE		:	DataMem[EX_MEM_ALUOut] 	<= #2 EX_MEM_B;
			
			HALT		:	HALTED			<= #2 1'b1; 	// next inst is in EX stage; completes execution ; but doesnt access memory
											// prev inst is on WB stage; completes write back
			 
			endcase		
         end

// WB STAGE
always @(posedge clk)
	begin
		case (MEM_WB_type)

			  RR_ALU:  Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; //rd

			  RM_ALU:  Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; //rt

			  LOAD:    Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;    //rt	  
		endcase		
	end
endmodule







	  
