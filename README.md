
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
* $A    \leftarrow Reg[rs]$
* $B    \leftarrow Reg[rt]$
* $Imm \\leftarrow \\{16\\{IR[15]\\} , IR[15:0]\\}$
* $Imm1 \\leftarrow \\{6\\{IR[25]\\} , IR[25:0]\\}$

### EX Stage:
* Memory Reference        : $ALUOut \leftarrow A + Imm;$

* Reg-Reg ALU Instruction : $ALUOut \leftarrow A \text{ func } B;$

* Reg-Imm ALU Instruction : $ALUOut \leftarrow A \text{ func } Imm;$

* Branch                  : $ALUOut \leftarrow NPC + Imm;$
                          : $cond \leftarrow (A \text{ op } 0);$

### MEM Stage:
* Load instruction  : $PC \leftarrow NPC;$
                    : $LMD \leftarrow Mem[ALUOut];$

* Store instruction : $PC \leftarrow NPC;$
                    : $Mem[ALUOut] \leftarrow B;$

* Branch instruction: $\text{if } (cond) \text{ } PC \leftarrow ALUOut;$
                    : $\text{else } PC \leftarrow NPC;$

* Other instructions: $PC \leftarrow NPC;$

### WB Stage:

Reg-Reg ALU Instruction : $Reg[rd] \leftarrow ALUOut;$

Reg-Imm ALU Instruction : $Reg[rt] \leftarrow ALUOut;$

Load Instruction        : $Reg[rt] \leftarrow LMD;$


## Non-PipeLined Architechture

<img width="811" height="360" alt="Image" src="https://github.com/user-attachments/assets/c5223b97-0fb8-409e-82e1-c29cb66acd1c" />

## PipeLined Architechture

<img width="809" height="372" alt="Image" src="https://github.com/user-attachments/assets/40a61dfd-a2f9-4b35-8aef-1287714c4951" />


## Issues To Be Addressed.

* Structural Hazards : Conflict while Data Access and Instruction Fetch.
* Data Hazards       : Only RAW Hazards are poosible in MIPS32.






