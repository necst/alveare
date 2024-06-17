library ieee;
use ieee.std_logic_1164.all;

package GenericsPack is
    -- Width of the data in input (usually is of 8 bits)
    constant DataWidth          : positive := 8;

    -- Width of the Opcode in the instruction
    constant OpCodeWidth        : positive := 7;
    -- Width of the decoded opcode. It is a one-hot vector in which
    -- each bit represents a different operator
    constant OpCodeBus          : positive := 11;
    -- Width of the internal operators (OR and AND, RANGE, ALWS)
    constant InternalOpBus      : positive := 4;

    -- Width of each cluster (Number of Comparators)
    constant ClusterWidth       : positive := 4;
    -- Number of clusters
    constant NCluster           : positive := 4;
    
    -- This determines the range of the Data Ram
    constant AddressWidthData   : positive := 6;

    constant AddrWidthDataBRAM  : positive := 12;
    -- 
    constant AddrWidthWriteDataBRAM  : positive := 14;
    -- This determines the range of the Instr Ram
    constant AddressWidthInstr  : positive := 6;
    -- This determines the width of each cell in the Data Ram
    constant RamWidthData       : positive := 8;
    -- This determines the width of the external bus of the AXI4 peripheral
    constant ExternalBusWidthData : positive := 128;
    -- This determines the width of the min, and max part in the instruction MinMaxWidth
    --constant MinMaxWidth : positive := 4;

    constant ExternalBusWidthInstr : positive := 32;
    -- This determines how many bits can be written on the bus connecting the Data Ram to the CPU
    constant InternalBusWidthData       : positive := DataWidth * (NCluster + ClusterWidth - 1);
    -- This determines the width of each cell in the Instr Ram
    constant RamWidthInstr      : positive := ClusterWidth * DataWidth + OpCodeWidth + ClusterWidth;

    constant CounterWidth       : positive := 1;
    
    constant StackDataWidth     : positive := CounterWidth + OpCodeBus + 1 + AddressWidthInstr + AddressWidthData;
    constant BufferAddressWidth : positive := 6;

    constant CharacterNumber    : positive := AddrWidthDataBRAM + 4;
    constant C_S00_AXI_DATA_WIDTH    : integer   := 32;
    constant C_S00_AXI_ADDR_WIDTH    : integer   := 7;
end GenericsPack;

-- package body GenericsPack is
-- end package body GenericsPack;
