`include "vunit_defines.svh"

module tb_simple_vunit;
  logic clk;
  logic reset;
  integer k;

  // Instantiate DUT
  pipe_MIPS32 mips(clk, reset);

  // Clock Generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SUITE begin
    `TEST_CASE("Sanity Check - Normal Arithmetic and Load/Store") begin
     
      reset = 1;
      #10 reset = 0;
      
     
      for(k = 0; k < 32; k++) begin
        mips.Reg[k] = k; 
      end

           
      mips.ProgMem[0] = 32'h00430800;	// ADD R1, R2, R3    -> R1 = 2 + 3 = 5		
     						
      mips.ProgMem[1] = 32'h04A62000;	// SUB R4, R5, R6    -> R4 = 5 - 6 = -1	      	

      mips.ProgMem[2] = 32'h2907000A;  	// ADDI R7, R8, 10   -> R7 = 8 + 10 = 18    

      mips.ProgMem[3] = 32'h2D49000A; 	// SUBI R9, R10, 10  -> R9 = 10 - 10 = 0     

      mips.ProgMem[4] = 32'h256C0000;   // STORE R12, 0(R11) -> Mem[11] = 12   

      mips.ProgMem[5] = 32'h216D0000;	// LW R13, 0(R11)    -> R13 = Mem[11] = 12

      
      #350;

      
      `CHECK_EQUAL(mips.Reg[1], 5);           // Check ADD
      `CHECK_EQUAL($signed(mips.Reg[4]), -1); // Check SUB
      `CHECK_EQUAL(mips.Reg[7], 18);          // Check ADDI
      `CHECK_EQUAL(mips.Reg[9], 0);           // Check SUBI
      `CHECK_EQUAL(mips.DataMem[11], 12);     // Check STORE
      `CHECK_EQUAL(mips.Reg[13], 12);         // Check LOAD
    end
  end

  // Watchdog to prevent infinite loops if something breaks
  initial begin
    #1000 $finish;
  end
endmodule