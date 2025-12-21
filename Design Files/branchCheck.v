
// Compute the factorial of the number stored in memory location 200 and store the 
// result in memory location 198

module branchCheck;		// covers all data dependencies
				// program for factorial evaluation
reg clk,reset;
integer k;

pipe_MIPS32 mips(clk,reset);

initial
begin
	clk = 0;
	reset = 0;
	#12 reset = 1;
	#10 reset = 0;
	
end

initial 
forever			
	begin
		#5 clk = 1; 
		#5 clk = 0;
		
	end

initial
begin
	for(k = 0; k<31; k= k + 1)
		mips.Reg[k] = k;  // not necessary; just to check dummy inst

	mips.ProgMem[0] = 32'h280a00c8;	// ADDI 	R10 ,R0 ,200
	mips.ProgMem[1] = 32'h21430000;	// LW		R3, 0(R10)	ALU_ALU data dependency 
	mips.ProgMem[2] = 32'h28020001;	// ADDI 	R2, R0 ,1	 
	mips.ProgMem[3] = 32'h14431000;	// LOOP:	MUL R2 R2 R3    ALU_ALU data dependency
	mips.ProgMem[4] = 32'h2c630001;	// SUBI		R3 R3 1	
	mips.ProgMem[5] = 32'h3460fffd;	// BNEQZ	R3 LOOP (-3 OFFSET) ALU_Branch dependency
	mips.ProgMem[6] = 32'h2542fffe;	// SW		R2 -2(R10)
	mips.ProgMem[7]= 32'hfc000000;	// HLT


	mips.DataMem[200] = 8;	

	

	#2000;
	$display("Mem[200] = %4d \n Mem[198] = %4d  ", 	mips.DataMem[200],
						    	mips.DataMem[198]);

end

initial 
begin
	$monitor("R3: %6d \n R2: %6d",mips.Reg[3],mips.Reg[2]);
	#6000 $stop;
end

endmodule