



module loadUseCheck;		// covers all load-use dependencies

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
forever			//Two Phase Clock
	begin
		#5 clk = 1; 
		#5 clk = 0;
		
	end

initial
begin
	for(k = 0; k<31; k= k + 1)
		mips.Reg[k] = k;  // not necessary; just to check dummy inst

	mips.ProgMem[0] = 32'h20410000;	// LW R1 0(R2)
	mips.ProgMem[1] = 32'h20830000;	// LW R3 0(R4)
	mips.ProgMem[2] = 32'h00232800;	// ADD R5 R1 R3   LOAD ALU CASE
	mips.ProgMem[3] = 32'h216A0000;  // LW R10 0(R11)	 
	mips.ProgMem[4] = 32'h39400005;	// BEQZ R10 5     LOAD BRANCH CASE
	mips.ProgMem[10]= 32'h24E50000;// SW R5 0(R7)	
	mips.ProgMem[11]= 32'hfc000000;	// HLT


	mips.DataMem[2] = 8;
	mips.DataMem[4] = 13;	
	mips.DataMem[11] = 0;

	

	#200;
	$display("DataMem[7] = %4d   ", 	mips.DataMem[7]);
	#50 $stop;

end



endmodule