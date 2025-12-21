
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
### IF Stage:

$$
IF/ID.IR \leftarrow Mem[PC]
$$

$$
IF/ID.NPC, PC \leftarrow
\begin{cases}
    EX/MEM.ALUOut & \text{if } ((EX/MEM.opcode == branch) \  \\&  \  EX/MEM.cond) \\
    PC + 4 & \text{else}
\end{cases}
$$

### ID Stage:
$$ID/EX.A \leftarrow Reg[IF/ID.IR[rs]]$$$$ID/EX.B \leftarrow Reg[IF/ID.IR[rt]]$$$$ID/EX.NPC \leftarrow IF/ID.NPC$$$$ID/EX.IR \leftarrow IF/ID.IR$$$$ID/EX.Imm \leftarrow \text{sign-extend}(IF/ID.IR_{15..0})$$

### EX Stage:
**R-R ALU:**

$$
EX/MEM.IR \leftarrow ID/EX.IR
$$

$$
EX/MEM.ALUOut \leftarrow ID/EX.A \text{ func } ID/EX.B
$$

**R-M ALU:**

$$
EX/MEM.IR \leftarrow ID/EX.IR
$$

$$
EX/MEM.ALUOut \leftarrow ID/EX.A \text{ func } ID/EX.Imm
$$

**Load / Store:**

$$
EX/MEM.IR \leftarrow ID/EX.IR
$$

$$
EX/MEM.ALUOut \leftarrow ID/EX.A + ID/EX.B
$$

$$
EX/MEM.B \leftarrow ID/EX.B
$$

**Branch:**

$$
EX/MEM.ALUOut \leftarrow ID/EX.NPC + (ID/EX.Imm \ll 2)
$$

$$
EX/MEM.cond \leftarrow (ID/EX.A == 0)
$$

### MEM Stage:
**ALU Instructions:**

$$
MEM/WB.IR \leftarrow EX/MEM.IR
$$

$$
MEM/WB.ALUOut \leftarrow EX/MEM.ALUOut
$$

**Load Instruction:**

$$
MEM/WB.IR \leftarrow EX/MEM.IR
$$

$$
MEM/WB.LMD \leftarrow Mem[EX/MEM.ALUOut]
$$

**Store Instruction:**

$$
MEM/WB.IR \leftarrow EX/MEM.IR
$$

$$
Mem[EX/MEM.ALUOut] \leftarrow EX/MEM.B
$$
### WB Stage:
**R-R ALU:**

$$
Reg[MEM/WB.IR[rd]] \leftarrow MEM/WB.ALUOut
$$

**R-M ALU:**

$$
Reg[MEM/WB.IR[rt]] \leftarrow MEM/WB.ALUOut
$$

**Load:**

$$
Reg[MEM/WB.IR[rt]] \leftarrow MEM/WB.LMD
$$
## Non-PipeLined Architechture

<img width="811" height="360" alt="Image" src="https://github.com/user-attachments/assets/c5223b97-0fb8-409e-82e1-c29cb66acd1c" />

## PipeLined Architechture

<img width="809" height="372" alt="Image" src="https://github.com/user-attachments/assets/40a61dfd-a2f9-4b35-8aef-1287714c4951" />


## Structural Hazards

Structural hazards occur when the hardware cannot support all possible combinations of instructions simultaneously due to resource conflicts. In this implementation, the primary structural hazards are:

* **IF - MEM Conflicts:** Both stages attempt to access memory simultaneously (Instruction Fetching in **IF** vs. Data Access in **MEM**).
* **ID - WB Conflicts:** Both stages attempt to access the Register File simultaneously (Reading operands in **ID** vs. Writing results in **WB**).

<img width="1390" height="362" alt="Image" src="https://github.com/user-attachments/assets/3642e63e-d398-4208-a8ca-85fc0b7aee4e" />


## Data Hazards
Data hazards occur due to data dependencies between instructions that are in various stages of execution in the pipeline. 
### ALU-ALU Data Dependency

<img width="1390" height="362" alt="Image" src="https://github.com/user-attachments/assets/eebd3fb8-9ee1-4524-818e-fc55b170c31c" />

* A **naive solution** to ALU-ALU data dependency is inserting stall cycles. After the instruction is decoded and the control unit determines that there is a data dependency, it can insert stall cycles and re-execute the ID stage again.
* **3 clock cycles are wasted**.



#### Reducing the Number of Stall Cycles

Two methods can be employed to minimize performance loss:

* **Data Forwarding:** By using additional hardware, the data required can be forwarded to the dependent instruction as soon as it is computed, rather than waiting for it to be written back to the register file.
  <img width="1614" height="398" alt="Image" src="https://github.com/user-attachments/assets/5516036b-8578-4b9c-a012-ee0b24dbdd83" />
  - The first instruction computes r4, which is required by all the subsequent four instructions.
  - The dependencies are depicted by red arrows (Result written in WB, operands read in ID).
  - The last instruction, OR, is not affected by data dependency.

* **Concurrent Register Access:** By splitting the clock cycle into two halves. Register read and write operations can be carried out in separate halves of a clock cycle (e.g., **write** in the first half and **read** in the second half).

<img width="1632" height="726" alt="Image" src="https://github.com/user-attachments/assets/7d355c63-0f76-449b-9de9-c55878c85ed3" />

### Data Hazard while Accessing Memory. 
A load instruction followed by the use of the loaded data is an example of a data hazard that requires unavoidable pipeline stalls. 

<img width="1503" height="530" alt="Image" src="https://github.com/user-attachments/assets/a26cd73b-6ced-4a81-b84a-557022190fff" />


#### Solution ?
* The hazard cannot be eliminated by forwarding alone.
* Common solution is to use a hardware addition called **pipeline interlock. **
* Another software solution is **Instruction Scheduling**, where the compiler tries to avoid generating code with a load followed by an immediate use. 

## Control Hazard.

Control hazards arise because of branch instructions being executed in the pipeline. 

### What happens when a branch is executed? 

* If the branch is taken, the PC is not normally updated until the end of the MEM stage.
* Instruction can thus be fetched after **3 stall cycles.**
<img width="1594" height="521" alt="Image" src="https://github.com/user-attachments/assets/d8a75a56-c9b1-4039-a93d-af267a484e32" />
* **Ideal CPI** = 1
* **Branch Frequency** = 30%
* **Stall Cycles** = 3

The **Actual CPI** is calculated by weighting the CPI of non-branch instructions (0.7 probability) and branch instructions (0.3 probability, with penalty).

$$
\text{Actual CPI} = (0.7 \times 1) + (0.3 \times 4)
$$

$$
\text{Actual CPI} = 0.7 + 1.2 = 1.9
$$

### Reducing Branch Penalties

To mitigate the high performance cost of branch hazards (which normally incur 3 stall cycles), the pipeline structure is modified to resolve branch decisions earlier.

**1. Standard MIPS32 Solution (Early Resolution)**
In the standard MIPS32 architecture, additional hardware is added to the **ID (Instruction Decode)** stage to calculate the branch target address and evaluate the branch condition.
* By the end of the ID stage, the processor knows whether the branch is taken and where to jump.
* **Result:** This reduces the penalty to just **1 stall cycle**.

**2. Proposed Optimization (Zero Stalls)**
This implementation further eliminates the remaining stall cycle by utilizing **Negative Edge Triggering**.
* **Mechanism:** Instruction Decode (ID) is performed on the **negative clock edge**.
* **Result:** Since the branch decision is resolved halfway through the cycle, the Program Counter (PC) can be updated in time for the next Instruction Fetch (IF) on the following positive edge.
* **Impact:** This results in **Zero Stall Cycles** for branch instructions.

