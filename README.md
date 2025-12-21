
# PipeLined Implementation of MIPS32 Processor

MIPS32 is a **Reduced Instruction Set Architechture (RISC)** which can operate on 32 bits of data at a time.

## Salient Features

### MIPS32 Registers:

* 32, 32 general purpose registers : *R0 to R1*.
* A special purpose register : 32 bit Program Counter pointing to the next instruction to be fetched.


### MIPS Instruction Encoding:
Instructions classified into three groups.
* R-type(Register) : Two Source and One Destination Register.

* I-type(Immediate) : One Source and One Destination Register. 

* J-type(jump) : Not implemented.

 <img width="523" height="233" alt="Image" src="https://github.com/user-attachments/assets/4614a59c-f91e-4610-a7e0-cc65246075c1" />

 ## Pipeline Stages:

 * IF : Instruction Fetch
 * ID : Instruction Decode
 * EX : Execute / Effective Address Calculation.
 * MEM: Memory Access/Branch Completion.
 * WB : Register Write Back

### IF Stage:
$$
IF/ID.IR \leftarrow Mem[PC]
$$

$$
IF/ID.NPC, PC \leftarrow
\begin{cases}
    EX/MEM.ALUOut & \text{if } ((EX/MEM.opcode == branch) \ \& \ EX/MEM.cond) \\
    PC + 4 & \text{else}
\end{cases}
$$

### ID Stage:
$$ID/EX.A \leftarrow Reg[IF/ID.IR[rs]]$$$$ID/EX.B \leftarrow Reg[IF/ID.IR[rt]]$$$$ID/EX.NPC \leftarrow IF/ID.NPC$$$$ID/EX.IR \leftarrow IF/ID.IR$$$$ID/EX.Imm \leftarrow \text{sign-extend}(IF/ID.IR_{15..0})$$

### EX Stage:
EX Stage (Execution)R-R ALU:$$EX/MEM.IR \leftarrow ID/EX.IR$$$$EX/MEM.ALUOut \leftarrow ID/EX.A \text{ func } ID/EX.B$$R-M ALU:$$EX/MEM.IR \leftarrow ID/EX.IR$$$$EX/MEM.ALUOut \leftarrow ID/EX.A \text{ func } ID/EX.Imm$$Load / Store:$$EX/MEM.IR \leftarrow ID/EX.IR$$$$EX/MEM.ALUOut \leftarrow ID/EX.A + ID/EX.B$$$$EX/MEM.B \leftarrow ID/EX.B$$Branch:$$EX/MEM.ALUOut \leftarrow ID/EX.NPC + (ID/EX.Imm \ll 2)$$$$EX/MEM.cond \leftarrow (ID/EX.A == 0)$$

### MEM Stage:
MEM Stage (Memory Access)ALU Instructions:$$MEM/WB.IR \leftarrow EX/MEM.IR$$$$MEM/WB.ALUOut \leftarrow EX/MEM.ALUOut$$Load Instruction:$$MEM/WB.IR \leftarrow EX/MEM.IR$$$$MEM/WB.LMD \leftarrow Mem[EX/MEM.ALUOut]$$Store Instruction:$$MEM/WB.IR \leftarrow EX/MEM.IR$$$$Mem[EX/MEM.ALUOut] \leftarrow EX/MEM.B$$

### WB Stage:
WB Stage (Write Back)R-R ALU:$$Reg[MEM/WB.IR[rd]] \leftarrow MEM/WB.ALUOut$$R-M ALU:$$Reg[MEM/WB.IR[rt]] \leftarrow MEM/WB.ALUOut$$Load:$$Reg[MEM/WB.IR[rt]] \leftarrow MEM/WB.LMD$$

## Non-PipeLined Architechture

<img width="811" height="360" alt="Image" src="https://github.com/user-attachments/assets/c5223b97-0fb8-409e-82e1-c29cb66acd1c" />

## PipeLined Architechture

<img width="809" height="372" alt="Image" src="https://github.com/user-attachments/assets/40a61dfd-a2f9-4b35-8aef-1287714c4951" />


## Issues To Be Addressed.

* Structural Hazards : Conflict while Data Access and Instruction Fetch.
* Data Hazards       : Only RAW Hazards are poosible in MIPS32.






