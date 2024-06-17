# Data Types folder

This folder contains all the Packages used in the Alveare Tile

### Current Packages

1. Data Record

2. Generics

This Package contains the Generics used for (sim/synth?) 

| Generic | Description | Default | Measurement Unit|
| :--------- |:-----------|:-----------|:-----------|
| DataWidth | Data path width of single character|  8  | bits |
| OpCodeWidth | Width of the Opcode in the instruction |  7  | bits |
| OpCodeBus |  Width of the decoded opcode. It is a one-hot vector in which  each bit represents a different operator|  11  | bits |
| InternalOpBus |  Width of the internal operators (OR, AND, RANGE)|  3  | bits |
| ClusterWidth | Width of each cluster, how many AND Chars in parallel |  4  | Number of Comparators |
| ClusterWidth | Number of clusters, how many OR Chars in parallel |  4  | Number of clusters |
| AddressWidthData | This determines the range of the Data Ram |  6  | 2\**AWD|
| AddrWidthDataBRAM |  This determines the width of read in the Data Ram BRAM support|  10 | 2\**AWDB|
| AddrWidthWriteDataBRAM | This determines the width of write in the Data Ram|  12  | 2\**AWWDB|
| AddressWidthInstr | This determines the range of the Instr Ram |  4  | 2\**AWI|
| RamWidthData | This determines the width of each cell in the Data Ram |  8  | bits |
| ExternalBusWidthData | This determines the width of the external bus to write into Alveare Data Ram|  128  | bits |
| ExternalBusWidthInstr | This determines the width of the external bus width to write into Alveare Instr Ram|  32  | bits |
| InternalBusWidthData | This determines how many bits can be written on the bus connecting the Data Ram to the external host (CPU)|  DataWidth * (NCluster + ClusterWidth - 1)  | bits |
| RamWidthInstr | This determines the width of each cell in the Instr Ram|  ClusterWidth * DataWidth + OpCodeWidth  | bits |
| CounterWidth | width of the Kleene counter | 1 | 2\**CW bits |
| StackDataWidth | width of the Stack cell | CounterWidth + OpCodeBus + 1 + AddressWidthInstr + AddressWidthData | bits |
| BufferAddressWidth | ?? | 3 | bits |
| CharacterNumber | ?? | AddrWidthDataBRAM + 4 | 2\**CN bits |
| C_S00_AXI_DATA_WIDTH | Data width of the AXI Lite peripheral | 32 | bits |
| C_S00_AXI_ADDR_WIDTH | Address width of the AXI Lite peripheral | 7| 2\**C bits |

3. Opcode

   * opcodes in natural form/ positions in the decoder bus
      * op_or  0; OR operator
      * op_and  1; AND operator
      * op_range  2; RANGE operator
      * op_cp_plus  3; )+ operator
      * op_cp_star  4; )\* operator
      * op_cp_or  5; )| operator
      * op_opar  6; ( operator
      * op_cp  7; ) operator
      * op_alws  8; . operator
      * op_jmp  9; jump offset encoding
      * op_nop  10; no operation
      
```
     +---+-------+-------+
     ¦ 6 ¦ 5 4 3 ¦ 2 1 0 ¦
     +---+-------+-------+
     ¦ ( ¦      |¦ )|    ¦
     ¦   ¦   &   ¦ )*    ¦
     ¦   ¦       ¦ )+    ¦
     ¦   ¦ []    ¦ )     ¦
     |   | , . . |       |
     +---+-------+-------+
```

opcodes position in instruction
   * opParpos   6; --open parenthesis (6)
   * opIpos     5; -- range/and/or/. opcodes (5..3)
   * opEpos     2; -- closed parenthesis opcodes(2..0)
    
 internal/external operators bitwise representation
   * opIWidth   3; -- bits to represent the internal operators
   * opEWidth   3; -- bits to represent the internal operators
   * opParWidth :1; -- open parenthesis operator

opcodes in binary form so before F&D stages as the compiler should produce (assuming no other operators in combinations)

   | Generic | Binary | Hex | Where?|
   | :--------- |:-----------|:-----------|:-----------|
   | opc_or |  "001"  | 0x08 | opIWidth   |
   | opc_and |  "010"  | 0x10 | opIWidth   |
   | opc_range |  "100"  | 0x20 | opIWidth   |
   | opc_alws |  "111"  | 0x38 | opIWidth   |
   |  |  |  |  |
   | opc_cp_plus |  "001"  | 0x02 | opEWidth   |
   | opc_cp_star |  "010"  | 0x01 | opEWidth   |
   | opc_cp_or |  "011"  | 0x03 | opEWidth   |
   | opc_cp |  "100"  | 0x04 | opEWidth   |
   | opc_jmp |  "100"  | 0x07 | opEWidth   |
   |  |  |  |  |
   | opc_opar | 1 | 0x40 | opParpos |
   |  |  |  |  |
   | opc_nop | 0 | 0x00 |  OpCodeWidth |


4. Stack

| Generic | Description | Default |
| :--------- |:-----------|:-----------|
| counterMSB | MSB of the counter |   StackDataWidth - 1  |
| counterLSB | LSB of the counter |  StackDataWidth - CounterWidth  |
| op_codeMSB | MSB of the counter |   counterLSB - 1  |
| op_codeLSB | LSB of the counter |  counterLSB - OpCodeBus  |
| matchAccum | MSB of the counter |   op_codeLSB - 1  |
| specialaddrMSB | MSB of the counter |   matchAccum - 1  |
| specialaddrLSB | LSB of the counter |  matchAccum - AddressWidthInstr  |
| contextaddrMSB | MSB of the counter |   specialaddrLSB - 1  |
| contextaddrLSB | LSB of the counter |  specialaddrLSB - AddressWidthData  |

5. Types

| Type | Description | HDL description |
| :--------- |:-----------|:-----------|
| RegisterArray | array of std_logic_vector (width = DataWidth) to map a wider std_logic_vector into the registers of the comparators| (DataWidth - 1 downto 0) |
| ResultsArray | ?? |  std_logic_vector(ClusterWidth - 1 downto 0)|
| ClusterArray | subtype of RegisterArray |  std_logic_vector(ClusterWidth - 1 downto 0)|
| ClusterData | subtype of RegisterArray |  ClusterArray(0 to ClusterWidth - 1)|

| Function |Description | Input | Return |
| :--------- |:-----------|:-----------|:-----------|
| results_array_to_std_logic_vec | array of std_logic_vector (width = DataWidth) to map a wider std_logic_vector into the registers of the comparators| ra : ResultsArray(0 to NCluster - 1) | std_logic_vector(DataWidth - 1 downto 0) |
| std_logic_vec_to_results_array |?? | sv : std_logic_vector( ((NCluster * ClusterWidth) - 1) downto 0 ) | ResultsArray(DataWidth - 1 downto 0) |
| string_to_clusterarray |?? | s : String |  |
| string_to_std_logic_vector |?? | s : String | std_logic_vector |
| std_logic_vec_to_cluster_array |?? | sv : std_logic_vector( ((ClusterWidth * DataWidth) - 1) downto 0 ) | ClusterArray|
| cluster_array_to_std_logic_vec |?? | res : ClusterArray(0 to ClusterWidth - 1) | std_logic_vector|
| std_logic_vec_to_cluster_data |?? | sv : std_logic_vector( ((NCluster * ClusterWidth\*DataWidth) - 1) downto 0 ) | ClusterData|
| cluster_data_to_std_logic_vec |?? | res : ClusterData(0 to NCluster - 1) | std_logic_vector|

