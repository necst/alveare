library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alveare_core_ip_v1_0 is
    generic (
        -- Users to add parameters here
        -- Width of the data in input (usually is of 8 bits)
        DataWidth               : positive := 8;
        -- Width of the Opcode in the instruction
        OpCodeWidth             : positive := 7;
        -- Width of the decoded opcode. It is a one-hot vector in which
        -- each bit represents a different operator
        OpCodeBus               : positive := 11;
        -- Width of each cluster (Number of Comparators)
        ClusterWidth            : positive := 4;
        -- Number of clusters
        NCluster                : positive := 4;
        -- Width of the counter of the repetitions for the kleene operator
        CounterWidth            : positive := 3;
        -- StackBuffer Depth
        BufferAddressWidth      : positive := 6;
        -- This determines the range of the Data BRAM (Write port)
        AddrWidthDataBRAM       : positive := 12;
        -- This determines the range of the Data BRAM (Read port)
        AddrWidthWriteDataBRAM  : positive := 14;
        -- This determines the range of the Data Buffer of the core
        AddressWidthData        : positive := 6;
        -- This determines the range of the Instr Ram
        AddressWidthInstr       : positive := 6;
        -- This determines the width of each cell in the Data Buffer
        RamWidthData            : positive := 8;
        -- This determines the width of the data incoming in the Data Buffer
        ExternalBusWidthData    : positive := 128;
        Debug               : boolean   := true;

        -- User parameters ends
        -- Do not modify the parameters beyond this line


        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH    : integer   := 32;
        C_S00_AXI_ADDR_WIDTH    : integer   := 7

    );
    port (
        -- Users to add ports here
        BRAM_DATA_OUT_A     : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        BRAM_DATA_IN_B      : in std_logic_vector(ExternalBusWidthData - 1 downto 0);
        BRAM_WADDR_A        : out std_logic_vector(AddrWidthWriteDataBRAM - 1 downto 0);
        BRAM_RADDR_B        : out std_logic_vector(AddrWidthDataBRAM - 1 downto 0);
        BRAM_WE             : out std_logic_vector(0 downto 0);
        -- User ports ends
        -- Do not modify the ports beyond this line


        -- Ports of Axi Slave Bus Interface S00_AXI
        s00_axi_aclk    : in std_logic;
        s00_axi_aresetn : in std_logic;
        s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awprot  : in std_logic_vector(2 downto 0);
        s00_axi_awvalid : in std_logic;
        s00_axi_awready : out std_logic;
        s00_axi_wdata   : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb   : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wvalid  : in std_logic;
        s00_axi_wready  : out std_logic;
        s00_axi_bresp   : out std_logic_vector(1 downto 0);
        s00_axi_bvalid  : out std_logic;
        s00_axi_bready  : in std_logic;
        s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arprot  : in std_logic_vector(2 downto 0);
        s00_axi_arvalid : in std_logic;
        s00_axi_arready : out std_logic;
        s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp   : out std_logic_vector(1 downto 0);
        s00_axi_rvalid  : out std_logic;
        s00_axi_rready  : in std_logic
    );
end alveare_core_ip_v1_0;

architecture arch_imp of alveare_core_ip_v1_0 is

    constant StackDataWidth             : positive := CounterWidth + OpCodeBus + 1 + AddressWidthInstr + AddressWidthData;
            -- Width of the internal operators (OR and AND)
    constant InternalOpBus      : positive := 4;

    ---- component declaration
    --component alveare_core_ip_v1_0_S00_AXI is
    --    generic (
    --    -- Width of the data in input (usually is of 8 bits)
    --    DataWidth => DataWidth,
    --    OpCodeWidth             => OpCodeWidth,
    --    OpCodeBus               => OpCodeBus,
    --    InternalOpBus           => InternalOpBus,
     
    --    ClusterWidth            => ClusterWidth,
    --    NCluster                => NCluster,

    --    CounterWidth            => CounterWidth,

    --    BufferAddressWidth      => BufferAddressWidth,
    --    StackDataWidth          => StackDataWidth,

    --    AddrWidthDataBRAM       => AddrWidthDataBRAM,
    --    AddrWidthWriteDataBRAM  => AddrWidthWriteDataBRAM,
    --    AddressWidthData        => AddressWidthData,
    --    AddressWidthInstr       => AddressWidthInstr,
    --    RamWidthData            => RamWidthData,
    --    ExternalBusWidthData    => ExternalBusWidthData,
    --    C_S_AXI_DATA_WIDTH      => C_S00_AXI_DATA_WIDTH,
    --    C_S_AXI_ADDR_WIDTH      => C_S00_AXI_ADDR_WIDTH
    --    );
    --    port (
    --    BRAM_DATA_OUT_A     : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    --    BRAM_DATA_IN_B      : in std_logic_vector(ExternalBusWidthData - 1 downto 0);
    --    BRAM_WADDR_A        : out std_logic_vector(AddrWidthWriteDataBRAM - 1 downto 0);
    --    BRAM_RADDR_B        : out std_logic_vector(AddrWidthDataBRAM - 1 downto 0);
    --    BRAM_WE             : out std_logic_vector(0 downto 0);

    --    S_AXI_ACLK  : in std_logic;
    --    S_AXI_ARESETN   : in std_logic;
    --    S_AXI_AWADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    --    S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
    --    S_AXI_AWVALID   : in std_logic;
    --    S_AXI_AWREADY   : out std_logic;
    --    S_AXI_WDATA : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    --    S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    --    S_AXI_WVALID    : in std_logic;
    --    S_AXI_WREADY    : out std_logic;
    --    S_AXI_BRESP : out std_logic_vector(1 downto 0);
    --    S_AXI_BVALID    : out std_logic;
    --    S_AXI_BREADY    : in std_logic;
    --    S_AXI_ARADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    --    S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
    --    S_AXI_ARVALID   : in std_logic;
    --    S_AXI_ARREADY   : out std_logic;
    --    S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    --    S_AXI_RRESP : out std_logic_vector(1 downto 0);
    --    S_AXI_RVALID    : out std_logic;
    --    S_AXI_RREADY    : in std_logic
    --    );
    --end component alveare_core_ip_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
alveare_core_ip_v1_0_S00_AXI_inst : entity work.alveare_core_ip_v1_0_S00_AXI
    generic map (
        AddressWidthInstr       => AddressWidthInstr,
        AddressWidthData        => AddressWidthData,
        OpCodeBus               => OpCodeBus,
        OpCodeWidth             => OpCodeWidth,
        InternalOpBus           => InternalOpBus,
        DataWidth               => DataWidth,
        ClusterWidth            => ClusterWidth,
        NCluster                => NCluster,
        CounterWidth            => CounterWidth,
        BufferAddressWidth      => BufferAddressWidth,
        StackDataWidth          => StackDataWidth,
        AddrWidthDataBRAM       => AddrWidthDataBRAM,
        AddrWidthWriteDataBRAM  => AddrWidthWriteDataBRAM,
        ExternalBusWidthData    => ExternalBusWidthData,
        RamWidthData            => RamWidthData,
        Debug                   => Debug,

        C_S_AXI_DATA_WIDTH      => C_S00_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH      => C_S00_AXI_ADDR_WIDTH
    )
    port map (
        BRAM_DATA_OUT_A         => BRAM_DATA_OUT_A,
        BRAM_DATA_IN_B          => BRAM_DATA_IN_B,
        BRAM_WADDR_A            => BRAM_WADDR_A,
        BRAM_RADDR_B            => BRAM_RADDR_B,
        BRAM_WE                 => BRAM_WE,

        S_AXI_ACLK  => s00_axi_aclk,
        S_AXI_ARESETN   => s00_axi_aresetn,
        S_AXI_AWADDR    => s00_axi_awaddr,
        S_AXI_AWPROT    => s00_axi_awprot,
        S_AXI_AWVALID   => s00_axi_awvalid,
        S_AXI_AWREADY   => s00_axi_awready,
        S_AXI_WDATA => s00_axi_wdata,
        S_AXI_WSTRB => s00_axi_wstrb,
        S_AXI_WVALID    => s00_axi_wvalid,
        S_AXI_WREADY    => s00_axi_wready,
        S_AXI_BRESP => s00_axi_bresp,
        S_AXI_BVALID    => s00_axi_bvalid,
        S_AXI_BREADY    => s00_axi_bready,
        S_AXI_ARADDR    => s00_axi_araddr,
        S_AXI_ARPROT    => s00_axi_arprot,
        S_AXI_ARVALID   => s00_axi_arvalid,
        S_AXI_ARREADY   => s00_axi_arready,
        S_AXI_RDATA => s00_axi_rdata,
        S_AXI_RRESP => s00_axi_rresp,
        S_AXI_RVALID    => s00_axi_rvalid,
        S_AXI_RREADY    => s00_axi_rready
    );

    -- Add user logic here

    -- User logic ends

end arch_imp;
