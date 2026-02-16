`include "vunit_defines.svh"

module tb_hazard_vunit;
  logic clk;
  logic reset;
  integer k;

  pipe_MIPS32 mips(clk, reset);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SUITE begin
    `TEST_CASE("Load-Use Hazard Forwarding") begin
      reset = 1;
      #10 reset = 0;

      for(k = 0; k < 31; k++) mips.Reg[k] = k;

      // 3. Load Program
      mips.ProgMem[0] = 32'h20410000; // LW R1, 0(R2)  -> Load 8
      mips.ProgMem[1] = 32'h20830000; // LW R3, 0(R4)  -> Load 13
      mips.ProgMem[2] = 32'h00232800; // ADD R5, R1, R3 -> R5 = 8+13 = 21 (Hazard!)
      mips.ProgMem[3] = 32'h216A0000; // LW R10, 0(R11)
      mips.ProgMem[4] = 32'h39400005; // BEQZ R10, 5
      mips.ProgMem[10]= 32'h24E50000; // SW R5, 0(R7)   -> Store 21 to Mem[7]
      mips.ProgMem[11]= 32'hfc000000; // HLT

      // 4. Initialize Data
      mips.DataMem[2] = 8;
      mips.DataMem[4] = 13;
      mips.DataMem[11] = 0;

      // 5. Wait
      #300;

      // 6. Check Result
      // If Forwarding/Stalling works, R5 should be 21. 
      // If it fails, it might be X or old value.
      `CHECK_EQUAL(mips.DataMem[7], 21);
    end
  end

  initial #1000 $finish;
endmodule