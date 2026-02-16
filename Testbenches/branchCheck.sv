`include "vunit_defines.svh"

module tb_branch_vunit;
  logic clk;
  logic reset;
  integer k;

  pipe_MIPS32 mips(clk, reset);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SUITE begin
    `TEST_CASE("Factorial Calculation (Branch & RAW Hazards)") begin
     
      reset = 1;
      #10 reset = 0;

      for(k = 0; k < 31; k++) mips.Reg[k] = k;

      mips.ProgMem[0] = 32'h280a00c8; // ADDI R10, R0, 200
      mips.ProgMem[1] = 32'h21430000; // LW R3, 0(R10)
      mips.ProgMem[2] = 32'h28020001; // ADDI R2, R0, 1
      mips.ProgMem[3] = 32'h14431000; // MUL R2, R2, R3
      mips.ProgMem[4] = 32'h2c630001; // SUBI R3, R3, 1
      mips.ProgMem[5] = 32'h3460fffd; // BNEQZ R3, LOOP
      mips.ProgMem[6] = 32'h2542fffe; // SW R2, -2(R10) -> Store at 198
      mips.ProgMem[7] = 32'hfc000000; // HLT

      mips.DataMem[200] = 8;

      #2500;

      `CHECK_EQUAL(mips.DataMem[198], 40320);
      
      `CHECK_EQUAL(mips.DataMem[200], 8);
    end
  end

  initial #6000 $finish;
endmodule