library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity alveare_core_ip_v1_0_S00_AXI is
    generic (
        -- Users to add parameters here
        -- Width of the data in input (usually is of 8 bits)
        DataWidth               : positive := 8;
        -- Width of the Opcode in the instruction
        OpCodeWidth             : positive := 7;
        -- Width of the decoded opcode. It is a one-hot vector in which
        -- each bit represents a different operator
        OpCodeBus               : positive := 11;
        -- Width of the internal operators (OR and AND)
        InternalOpBus           : positive := 4;
        -- Width of each cluster (Number of Comparators)
        ClusterWidth            : positive := 4;
        -- Number of clusters
        NCluster                : positive := 4;
        -- Width of the counter of the repetitions for the kleene operator
        CounterWidth            : positive := 1;
        -- StackBuffer Depth
        BufferAddressWidth      : positive := 6;
        -- Width of a Stack word
        StackDataWidth          : positive := 22;
        -- This determines the range of the Data BRAM (Write port)
        AddrWidthDataBRAM       : positive := 12;
        -- This determines the range of the Data BRAM (Read port)
        AddrWidthWriteDataBRAM  : positive := 12;
        -- This determines the range of the Data Buffer of the core
        AddressWidthData        : positive := 6;
        -- This determines the range of the Instr Ram
        AddressWidthInstr       : positive := 6;
        -- This determines the width of each cell in the Data Buffer
        RamWidthData            : positive := 8;
        -- This determines the width of the data incoming in the Data Buffer
        ExternalBusWidthData    : positive := 128;
        Debug                   : boolean   := true;

        -- User parameters ends
        -- Do not modify the parameters beyond this line

        -- Width of S_AXI data bus
        C_S_AXI_DATA_WIDTH      : integer   := 32;
        -- Width of S_AXI address bus
        C_S_AXI_ADDR_WIDTH      : integer   := 7
    );
    port (
        -- Users to add ports here
        -- This out and in signals are used to control the BRAM
        BRAM_DATA_OUT_A     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        BRAM_DATA_IN_B      : in std_logic_vector(ExternalBusWidthData - 1 downto 0);
        BRAM_WADDR_A        : out std_logic_vector(AddrWidthWriteDataBRAM - 1 downto 0);
        BRAM_RADDR_B        : out std_logic_vector(AddrWidthDataBRAM - 1 downto 0);
        BRAM_WE             : out std_logic_vector(0 downto 0);
        -- User ports ends
        -- Do not modify the ports beyond this line

        -- Global Clock Signal
        S_AXI_ACLK      : in std_logic;
        -- Global Reset Signal. This Signal is Active LOW
        S_AXI_ARESETN   : in std_logic;
        -- Write address (issued by master, acceped by Slave)
        S_AXI_AWADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        -- Write channel Protection type. This signal indicates the
            -- privilege and security level of the transaction, and whether
            -- the transaction is a data access or an instruction access.
        S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
        -- Write address valid. This signal indicates that the master signaling
            -- valid write address and control information.
        S_AXI_AWVALID   : in std_logic;
        -- Write address ready. This signal indicates that the slave is ready
            -- to accept an address and associated control signals.
        S_AXI_AWREADY   : out std_logic;
        -- Write data (issued by master, acceped by Slave) 
        S_AXI_WDATA     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        -- Write strobes. This signal indicates which byte lanes hold
            -- valid data. There is one write strobe bit for each eight
            -- bits of the write data bus.    
        S_AXI_WSTRB     : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        -- Write valid. This signal indicates that valid write
            -- data and strobes are available.
        S_AXI_WVALID    : in std_logic;
        -- Write ready. This signal indicates that the slave
            -- can accept the write data.
        S_AXI_WREADY    : out std_logic;
        -- Write response. This signal indicates the status
            -- of the write transaction.
        S_AXI_BRESP : out std_logic_vector(1 downto 0);
        -- Write response valid. This signal indicates that the channel
            -- is signaling a valid write response.
        S_AXI_BVALID    : out std_logic;
        -- Response ready. This signal indicates that the master
            -- can accept a write response.
        S_AXI_BREADY    : in std_logic;
        -- Read address (issued by master, acceped by Slave)
        S_AXI_ARADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        -- Protection type. This signal indicates the privilege
            -- and security level of the transaction, and whether the
            -- transaction is a data access or an instruction access.
        S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
        -- Read address valid. This signal indicates that the channel
            -- is signaling valid read address and control information.
        S_AXI_ARVALID   : in std_logic;
        -- Read address ready. This signal indicates that the slave is
            -- ready to accept an address and associated control signals.
        S_AXI_ARREADY   : out std_logic;
        -- Read data (issued by slave)
        S_AXI_RDATA     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        -- Read response. This signal indicates the status of the
            -- read transfer.
        S_AXI_RRESP     : out std_logic_vector(1 downto 0);
        -- Read valid. This signal indicates that the channel is
            -- signaling the required read data.
        S_AXI_RVALID    : out std_logic;
        -- Read ready. This signal indicates that the master can
            -- accept the read data and response information.
        S_AXI_RREADY    : in std_logic
    );
end alveare_core_ip_v1_0_S00_AXI;

architecture arch_imp of alveare_core_ip_v1_0_S00_AXI is

    -- AXI4LITE signals
    signal axi_awaddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_awready  : std_logic;
    signal axi_wready   : std_logic;
    signal axi_bresp    : std_logic_vector(1 downto 0);
    signal axi_bvalid   : std_logic;
    signal axi_araddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_arready  : std_logic;
    signal axi_rdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal axi_rresp    : std_logic_vector(1 downto 0);
    signal axi_rvalid   : std_logic;

    -- Example-specific design signals
    -- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    -- ADDR_LSB is used for addressing 32/64 bit registers/memories
    -- ADDR_LSB = 2 for 32 bits (n downto 2)
    -- ADDR_LSB = 3 for 64 bits (n downto 3)
    constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
    constant OPT_MEM_ADDR_BITS : integer := 3;
    ------------------------------------------------
    ---- Signals for user logic register space example
    --------------------------------------------------
    ---- Number of Slave Registers 10
    -- dedicated to address_write_instruction
    signal slv_reg0 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to pass the instructions into instr_memory
    signal slv_reg1 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to address_write_data
    signal slv_reg2 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to pass the data into data_memory
    signal slv_reg3 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to pass the start_data_address
    signal slv_reg4 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to pass the end_data_address
    signal slv_reg5 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to pass the start_instr_address
    signal slv_reg6 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to search_enable signal
    signal slv_reg7 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to the core complete signal
    signal slv_reg8 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- dedicated to the core found signal
    signal slv_reg9 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg10  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg11  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg12  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg13  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg14  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg15  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg16  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg17  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg18  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg19  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg20  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg_rden     : std_logic;
    signal slv_reg_wren     : std_logic;
    signal reg_data_out     :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal byte_index       : integer;
    signal aw_en  : std_logic;

    
    -- User defined signals and constants
    constant CharacterNumber    : positive := AddrWidthDataBRAM + 4;
    constant padding_num_char   : std_logic_vector(C_S_AXI_DATA_WIDTH - CharacterNumber - 1 downto 0) := (others => '0');
    --signal bram_addr_padding    : std_logic_vector(C_S_AXI_DATA_WIDTH - AddrWidthDataBRAM - 1 downto 0) := (others => '0');
    -- Tile outputs
    signal control_vector   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal counter          : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    
    -- Signals to control the data buffer reload
    signal curr_character       : std_logic_vector(CharacterNumber - 1 downto 0);
    signal curr_character_check : std_logic_vector(CharacterNumber - 1 downto 0) := (others => '0');
    signal curr_last_match_char : std_logic_vector(CharacterNumber - 1 downto 0);
    signal difference           : std_logic_vector(CharacterNumber - 1 downto 0) := (others => '0');
    signal check_char           : std_logic_vector(AddressWidthData - 1 downto 0) := (others => '0');

    -- Indicated if the Data Buffer has to be reloaded
    signal bram_addr            : std_logic_vector(AddrWidthDataBRAM - 1 downto 0) := (others => '0');
    signal bram_addr_wr         : std_logic_vector(AddrWidthWriteDataBRAM - 1 downto 0) := (others => '0');
    signal data_address_wr      : std_logic_vector(AddressWidthData - 1 downto 0) := (others => '0');
    signal data_address_wr_i    : std_logic_vector(AddressWidthData - 1 downto 0) := (others => '0');
    signal data_we              : std_logic := '0';
    signal data_data_in         : std_logic_vector(ExternalBusWidthData - 1 downto 0);
    signal rst                  : std_logic := '1';
    signal no_more_characters   : std_logic := '0';
    signal reload               : std_logic;
    signal reload_padding       : std_logic_vector(C_S_AXI_DATA_WIDTH-2 downto 0) := (others => '0');
    signal ram_addr_out         : std_logic_vector(AddressWidthData - 1 downto 0);


    --------------------

    signal debug_cp_state     :  std_logic_vector(6 downto 0);
    signal  debug_curr_opc       :  std_logic_vector(OpCodeBus - 1 downto 0);
    signal debug_instr_addr_1   :  std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal debug_instr_addr_2   :  std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal debug_instr_addr_3   :  std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal debug_curr_data      :  std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
    signal debug_curr_ref :  std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal debug_instr_1        :  std_logic_vector (ClusterWidth * DataWidth + OpCodeWidth + ClusterWidth - 1 downto 0);
    signal debug_instr_2        :  std_logic_vector (ClusterWidth * DataWidth + OpCodeWidth + ClusterWidth - 1 downto 0);
    signal debug_instr_3        :  std_logic_vector (ClusterWidth * DataWidth + OpCodeWidth + ClusterWidth - 1 downto 0);



    -------------- Other useful stuffs
    Constant padding_std_logic    : std_logic_vector(C_S_AXI_DATA_WIDTH-1-1 downto 0) := (others => '0');
    constant padding_reference    : std_logic_vector(C_S_AXI_DATA_WIDTH-1-debug_curr_ref'length downto 0) := (others => '0');
    constant padding_cp_state : std_logic_vector( C_S_AXI_DATA_WIDTH-1-7 downto 0):= (others => '0');
    constant padding_opcode : std_logic_vector( C_S_AXI_DATA_WIDTH-1-OpCodeBus downto 0):= (others => '0');
    constant padding_instr_addr : std_logic_vector( C_S_AXI_DATA_WIDTH-1-debug_instr_addr_1'length downto 0):= (others => '0');
    constant instr_ram_width : positive := ClusterWidth * DataWidth + OpCodeWidth + ClusterWidth;
    constant padding_instr_ram : std_logic_vector(C_S_AXI_DATA_WIDTH-(instr_ram_width - C_S_AXI_DATA_WIDTH)-1 downto 0):= (others => '0');
    constant padding_bram_addr : std_logic_vector(bram_addr'length - C_S_AXI_DATA_WIDTH -1 downto 0):= (others => '0');
    constant OPT_MEM_ADDR_BITS_TMP : integer := 4;

    signal reg_curr_data_first : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg_curr_ref :  std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal reg_control_vector  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg10  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg11  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg12  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg13  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg14  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg15  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg16  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg17  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg18  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg19  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal reg20  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

    --constant padding_data : std_logic_vector( C_S_AXI_DATA_WIDTH-1-curr_data'length downto 0):= (others => '0');


begin
    
    -- Instantiation of the Tile entity
    ALVEARE_TILE : entity work.Tile
        generic map(
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
            ExternalBusWidthData    => ExternalBusWidthData,
            InternalBusWidthData    => DataWidth * (NCluster + ClusterWidth - 1),
            RamWidthInstr           => ClusterWidth * DataWidth + OpCodeWidth + ClusterWidth,
            RamWidthData            => RamWidthData,
            CharacterNumber         => CharacterNumber,
            Debug                   => Debug
            )
        port map(
            clk                     => S_AXI_ACLK,
            rst                     => rst,
            addr_start_instr        => slv_reg6(AddressWidthInstr - 1 downto 0),
            no_more_characters      => no_more_characters,

            src_en                  => slv_reg7(0),

-- hopefully will be cutted in synthesis if not used:D
        debug_curr_state     => debug_cp_state,
        debug_curr_opc       => debug_curr_opc,
        debug_instr_addr_1   => debug_instr_addr_1,
        debug_instr_addr_2   => debug_instr_addr_2,
        debug_instr_addr_3   => debug_instr_addr_3,
        debug_curr_data      => debug_curr_data,
        debug_curr_ref       => debug_curr_ref,
        debug_instr_1        => debug_instr_1,
        debug_instr_2        => debug_instr_2,
        debug_instr_3        => debug_instr_3,
---

            complete                => control_vector(0),
            found                   => control_vector(1),
            curr_character          => curr_character,
            curr_last_match_char    => curr_last_match_char,

            instr_address_wr        => slv_reg0(AddressWidthInstr - 1 downto 0),
            instr_data_in           => slv_reg1,
            instr_we_data           => slv_reg7(1),
            instr_we_opcode         => slv_reg7(2),
            data_address_wr         => data_address_wr,
            data_data_in            => data_data_in,
            data_we                 => data_we
            );

    -- I/O Connections assignments

    S_AXI_AWREADY   <= axi_awready;
    S_AXI_WREADY    <= axi_wready;
    S_AXI_BRESP <= axi_bresp;
    S_AXI_BVALID    <= axi_bvalid;
    S_AXI_ARREADY   <= axi_arready;
    S_AXI_RDATA <= axi_rdata;
    S_AXI_RRESP <= axi_rresp;
    S_AXI_RVALID    <= axi_rvalid;
    -- Implement axi_awready generation
    -- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    -- de-asserted when reset is low.

    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then 
        if S_AXI_ARESETN = '0' then
          axi_awready <= '0';
          aw_en <= '1';

        else
          if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1'and aw_en = '1') then
            -- slave is ready to accept write address when
            -- there is a valid write address and write data
            -- on the write address and data bus. This design 
            -- expects no outstanding transactions. 
            axi_awready <= '1';
             aw_en <= '0';

          else
             aw_en <= '1';
            axi_awready <= '0';
          end if;
        end if;
      end if;
    end process;

    -- Implement axi_awaddr latching
    -- This process is used to latch the address when both 
    -- S_AXI_AWVALID and S_AXI_WVALID are valid. 

    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then 
        if S_AXI_ARESETN = '0' then
          axi_awaddr <= (others => '0');
        else
          if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
            -- Write Address latching
            axi_awaddr <= S_AXI_AWADDR;
          end if;
        end if;
      end if;                   
    end process; 

    -- Implement axi_wready generation
    -- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
    -- de-asserted when reset is low. 

    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then 
        if S_AXI_ARESETN = '0' then
          axi_wready <= '0';
        else
          if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
              -- slave is ready to accept write data when 
              -- there is a valid write address and write data
              -- on the write address and data bus. This design 
              -- expects no outstanding transactions.           
              axi_wready <= '1';
          else
            axi_wready <= '0';
          end if;
        end if;
      end if;
    end process; 

    -- Implement memory mapped register select and write logic generation
    -- The write data is accepted and written to memory mapped registers when
    -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    -- select byte enables of slave registers while writing.
    -- These registers are cleared when reset (active low) is applied.
    -- Slave register write enable is asserted when valid address and data are available
    -- and the slave is ready to accept the write address and write data.
    slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;



write_not_debug_generate: if not Debug generate
    process (S_AXI_ACLK)
    variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
    begin
      if rising_edge(S_AXI_ACLK) then 
        if S_AXI_ARESETN = '0' then
          slv_reg0 <= (others => '0');
          slv_reg1 <= (others => '0');
          slv_reg2 <= (others => '0');
          slv_reg3 <= (others => '0');
          slv_reg4 <= (others => '0');
          slv_reg5 <= (others => '0');
          slv_reg6 <= (others => '0');
          slv_reg7 <= (others => '0');
          slv_reg8 <= (others => '0');
          slv_reg9 <= (others => '0');
          slv_reg10 <= (others => '0');
        else
          loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
          if (slv_reg_wren = '1') then
            case loc_addr is
              when b"0000" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 0
                    slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"0001" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 1
                    slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"0010" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 2
                    slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"0011" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 3
                    slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"0100" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 4
                    slv_reg4(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"0101" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 5
                    slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"0110" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 6
                    slv_reg6(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"0111" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 7
                    slv_reg7(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"1000" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 8
                    slv_reg8(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"1001" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 9
                    slv_reg9(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
                when b"1010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 10
                  slv_reg10(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
              when others =>
                slv_reg0 <= slv_reg0;
                slv_reg1 <= slv_reg1;
                slv_reg2 <= slv_reg2;
                slv_reg3 <= slv_reg3;
                slv_reg4 <= slv_reg4;
                slv_reg5 <= slv_reg5;
                slv_reg6 <= slv_reg6;
                slv_reg7 <= slv_reg7;
                slv_reg8 <= slv_reg8;
                slv_reg9 <= slv_reg9;
                slv_reg10 <= slv_reg10;
            end case;
          end if;
        end if;
      end if;                   
    end process; 
end generate; --write_not_debug_generate
    -- Implement write response logic generation
    -- The write response and response valid signals are asserted by the slave 
    -- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
    -- This marks the acceptance of address and indicates the status of 
    -- write transaction.

    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then 
        if S_AXI_ARESETN = '0' then
          axi_bvalid  <= '0';
          axi_bresp   <= "00"; --need to work more on the responses
        else
          if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
            axi_bvalid <= '1';
            axi_bresp  <= "00"; 
          elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
            axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
          end if;
        end if;
      end if;                   
    end process; 

    -- Implement axi_arready generation
    -- axi_arready is asserted for one S_AXI_ACLK clock cycle when
    -- S_AXI_ARVALID is asserted. axi_awready is 
    -- de-asserted when reset (active low) is asserted. 
    -- The read address is also latched when S_AXI_ARVALID is 
    -- asserted. axi_araddr is reset to zero on reset assertion.

    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then 
        if S_AXI_ARESETN = '0' then
          axi_arready <= '0';
          axi_araddr  <= (others => '1');
        else
          if (axi_arready = '0' and S_AXI_ARVALID = '1') then
            -- indicates that the slave has acceped the valid read address
            axi_arready <= '1';
            -- Read Address latching 
            axi_araddr  <= S_AXI_ARADDR;           
          else
            axi_arready <= '0';
          end if;
        end if;
      end if;                   
    end process; 

    -- Implement axi_arvalid generation
    -- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
    -- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
    -- data are available on the axi_rdata bus at this instance. The 
    -- assertion of axi_rvalid marks the validity of read data on the 
    -- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
    -- is deasserted on reset (active low). axi_rresp and axi_rdata are 
    -- cleared to zero on reset (active low).  
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        if S_AXI_ARESETN = '0' then
          axi_rvalid <= '0';
          axi_rresp  <= "00";
        else
          if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
            -- Valid read data is available at the read data bus
            axi_rvalid <= '1';
            axi_rresp  <= "00"; -- 'OKAY' response
          elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
            -- Read data is accepted by the master
            axi_rvalid <= '0';
          end if;            
        end if;
      end if;
    end process;

    -- Implement memory mapped register select and read logic generation
    -- Slave register read enable is asserted when valid address is available
    -- and the slave is ready to accept the read address.
    slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;


read_not_debug_generate: if not Debug generate
       process (debug_curr_data, debug_curr_ref, no_more_characters, curr_character, counter, debug_cp_state, control_vector, curr_character_check, slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7, slv_reg8, slv_reg9,slv_reg10, slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15, slv_reg16, slv_reg17, slv_reg18, slv_reg19, slv_reg20, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
    variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
    begin
        -- Address decoding for reading registers
        loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
        case loc_addr is
          when b"0000" =>
            reg_data_out <= slv_reg0;
          when b"0001" =>
            reg_data_out <= slv_reg1;
          when b"0010" =>
            -- First chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= slv_reg2;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH * 4 - 1 downto C_S_AXI_DATA_WIDTH * 3);
          when b"0011" =>
            -- Second chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= padding_std_logic & rst;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH * 3 - 1 downto C_S_AXI_DATA_WIDTH * 2);
          when b"0100" =>
            -- Third chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= padding_num_char & curr_character;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH * 2 - 1 downto C_S_AXI_DATA_WIDTH);
          when b"0101" =>
            -- Fourth chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= slv_reg6;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH - 1 downto 0);
          when b"0110" =>
            -- register 6 contains the clock counts
            reg_data_out <= counter;
          when b"0111" =>
            -- register 7 contains the control vector containing the results
            reg_data_out <= slv_reg7;
          when b"1000" =>
            -- register 8 contains the character number corresponding to the first
            -- character of the matching substring
            reg_data_out <= padding_num_char & curr_character_check;
          when b"1001" =>
            reg_data_out <= control_vector;
          when b"1010" =>
            reg_data_out <= padding_bram_addr & bram_addr;
          when others =>
            reg_data_out  <= (others => '0');
        end case;
    end process;
end generate; --read_not_debug_generate


    -- Output register or memory read data
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if ( S_AXI_ARESETN = '0' ) then
          axi_rdata  <= (others => '0');
        else
          if (slv_reg_rden = '1') then
            -- When there is a valid read address (S_AXI_ARVALID) with 
            -- acceptance of read address by the slave (axi_arready), 
            -- output the read dada 
            -- Read address mux
              axi_rdata <= reg_data_out;     -- register read data
          end if;   
        end if;
      end if;
    end process;

    -- Add user logic here

    -- reset signal that can be controlled in SDK by the user
    rst <= S_AXI_ARESETN and not slv_reg7(5);
    difference <= curr_character_check - curr_character;
    
    -- This process is the clock cycles counter. It activates when the core
    -- and the search are enabled. It counts at each rising edge of the clock
    process( S_AXI_ACLK ) is
    begin
        if (rising_edge (S_AXI_ACLK)) then
            if slv_reg7(0) = '1' then
                if control_vector(0) = '0' then
                    counter <= counter + 1;
                else 
                    counter <= counter;
                end if;
            else
                counter <= (others => '0');
            end if;
        end if;
    end process;
    
    -- This process is needed to control the reload of the Data Buffer whenever
    -- the core needs new data or needs to backup because of a mismatch
    process( S_AXI_ACLK ) is
    begin
        if rising_edge(S_AXI_ACLK) then
            data_we <= '0';
            if rst = '0' then
                curr_character_check    <= (others => '0');
                check_char              <= (others => '0');
                bram_addr               <= (others => '0');
                data_address_wr_i       <= (others => '0');
                data_data_in            <= (others => '0');
                data_we                 <= '0';
            elsif slv_reg7(3) = '1' then
                -- If the condition is true new data from the BRAM has to be retrieved so
                -- to have the correct data in the Data Buffer
                if difference <= 12 then
                    curr_character_check    <= curr_character_check + ExternalBusWidthData / RamWidthData;
                    check_char              <= check_char + ExternalBusWidthData / RamWidthData;
                    for i in 0 to ExternalBusWidthData / C_S_AXI_DATA_WIDTH - 1 loop
                        data_data_in(C_S_AXI_DATA_WIDTH * (4 - i) - 1 downto C_S_AXI_DATA_WIDTH * (3 - i)) <=
                             BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH * (i + 1) - 1 downto C_S_AXI_DATA_WIDTH * i);
                    end loop;
                    data_we             <= '1';
                    bram_addr           <= bram_addr + 1;
                    data_address_wr_i   <= data_address_wr_i + ExternalBusWidthData / RamWidthData;
                end if;
            elsif slv_reg7(4) = '1' then
                bram_addr <= slv_reg3(AddrWidthDataBram - 1 downto 0);
            else
                bram_addr <= (others => '0');
            end if;
        end if;
    end process;

    process( S_AXI_ACLK ) is
    begin
        if rising_edge( S_AXI_ACLK ) then
            if rst = '0' then
                BRAM_RADDR_B <= (others => '0');
                data_address_wr <= (others => '0');
            else
                BRAM_RADDR_B <= bram_addr;
                data_address_wr <= data_address_wr_i;
            end if;
        end if;
    end process;

    process( S_AXI_ACLK ) is
    begin
        if rising_edge( S_AXI_ACLK ) then
            if rst = '0' then
                no_more_characters <= '0';
            elsif curr_character_check > slv_reg5 then
                no_more_characters <= '1';
            else 
                no_more_characters <= '0';
            end if;
            control_vector(2) <= no_more_characters;
        end if;
    end process;

    -- This process acts whenever the user wants to manually load the BRAM
    process( S_AXI_ACLK ) is
    begin
        if rising_edge(S_AXI_ACLK) then
            if rst = '0' then
                BRAM_WE           <= "0";
                BRAM_WADDR_A      <= (others => '0');
                BRAM_DATA_OUT_A   <= (others => '0');
            else
                BRAM_WE <= slv_reg2(0 downto 0);
                if slv_reg2(0) = '1' then
                    BRAM_WADDR_A    <= slv_reg8(AddrWidthWriteDataBRAM - 1 downto 0);
                    BRAM_DATA_OUT_A <= slv_reg9;
                else
                    BRAM_WADDR_A    <= (others => '0');
                    BRAM_DATA_OUT_A <= (others => '0');
                end if;
            end if;
        end if;
    end process;



-------------------------------------------------
--
-- Debug processes for read and write :D
--
---------------------------------


read_debug_generate: if Debug generate
    process (debug_curr_data, debug_curr_ref, no_more_characters, curr_character, counter, debug_cp_state, control_vector, curr_character_check, slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7, slv_reg8, slv_reg9,slv_reg10, slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15, slv_reg16, slv_reg17, slv_reg18, slv_reg19, slv_reg20, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
    variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS_TMP downto 0);
    begin
        -- Address decoding for reading registers
        loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS_TMP downto ADDR_LSB);
        case loc_addr is
          when b"00000" =>
            reg_data_out <= reg_curr_data_first;
          when b"00001" =>
            reg_data_out <= padding_reference & reg_curr_ref ;
          when b"00010" =>
            -- First chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= slv_reg0;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH * 4 - 1 downto C_S_AXI_DATA_WIDTH * 3);
          when b"00011" =>
            -- Second chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= padding_std_logic & rst;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH * 3 - 1 downto C_S_AXI_DATA_WIDTH * 2);
          when b"00100" =>
            -- Third chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= padding_num_char & curr_character;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH * 2 - 1 downto C_S_AXI_DATA_WIDTH);
          when b"00101" =>
            -- Fourth chunk of 32 bits coming from BRAM in order to be debugged
            reg_data_out <= slv_reg6;--BRAM_DATA_IN_B(C_S_AXI_DATA_WIDTH - 1 downto 0);
          when b"00110" =>
            -- register 6 contains the clock counts
            reg_data_out <= counter;
          when b"00111" =>
            -- register 7 contains the control vector containing the results
            reg_data_out <= slv_reg7;
          when b"01000" =>
            -- register 8 contains the character number corresponding to the first
            -- character of the matching substring
            reg_data_out <= padding_num_char & curr_character_check;
          when b"01001" =>
            reg_data_out <= reg_control_vector;
          when b"01010" =>
            reg_data_out <= padding_cp_state & debug_cp_state;
          when b"01011" =>
            reg_data_out <= reg10;
          when b"01100" =>
            reg_data_out <= reg11;
          when b"01101" =>
            reg_data_out <= reg12;
          when b"01110" =>
            reg_data_out <= reg13;
          when b"01111" =>
            reg_data_out <= reg14 ;
          when b"10000" =>
            reg_data_out <= reg15 ;
          when b"10001" =>
            reg_data_out <= reg16 ;
          when b"10010" =>
            reg_data_out <= reg17;
          when b"10011" =>
            reg_data_out <= reg18;
          when b"10100" =>
            reg_data_out <= reg19;
          when b"10101" =>
            reg_data_out <= reg20;
          when others =>
            reg_data_out  <= (others => '0');
        end case;
    end process;
end generate; --read_debug_generate



write_debug_generate: if Debug generate
    process (S_AXI_ACLK)
    variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS_TMP downto 0); 
    begin
      if rising_edge(S_AXI_ACLK) then 
        if S_AXI_ARESETN = '0' then
          slv_reg0 <= (others => '0');
          slv_reg1 <= (others => '0');
          slv_reg2 <= (others => '0');
          slv_reg3 <= (others => '0');
          slv_reg4 <= (others => '0');
          slv_reg5 <= (others => '0');
          slv_reg6 <= (others => '0');
          slv_reg7 <= (others => '0');
          slv_reg8 <= (others => '0');
          slv_reg9 <= (others => '0');
          slv_reg10 <= (others => '0');
        slv_reg11 <= (others => '0');
        slv_reg12 <= (others => '0');
        slv_reg13 <= (others => '0');
        slv_reg14 <= (others => '0');
        slv_reg15 <= (others => '0');
        slv_reg16 <= (others => '0');
        slv_reg17 <= (others => '0');
        slv_reg18 <= (others => '0');
        slv_reg19 <= (others => '0');
        slv_reg20 <= (others => '0');
        else
          loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS_TMP downto ADDR_LSB);
          if (slv_reg_wren = '1') then
            case loc_addr is
              when b"00000" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 0
                    slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"00001" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 1
                    slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"00010" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 2
                    slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"00011" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 3
                    slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"00100" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 4
                    slv_reg4(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"00101" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 5
                    slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"00110" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 6
                    slv_reg6(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"00111" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 7
                    slv_reg7(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"01000" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 8
                    slv_reg8(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
              when b"01001" =>
                for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                  if ( S_AXI_WSTRB(byte_index) = '1' ) then
                    -- Respective byte enables are asserted as per write strobes                   
                    -- slave registor 9
                    slv_reg9(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  end if;
                end loop;
                when b"01010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 10
                  slv_reg10(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"01011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 11
                  slv_reg11(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"01100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 12
                  slv_reg12(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"01101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 13
                  slv_reg13(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"01110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 14
                  slv_reg14(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"01111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 15
                  slv_reg15(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"10000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 16
                  slv_reg16(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"10001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 17
                  slv_reg17(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"10010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 18
                  slv_reg18(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"10011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 19
                  slv_reg19(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"10100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 20
                  slv_reg20(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
              when others =>
                slv_reg0 <= slv_reg0;
                slv_reg1 <= slv_reg1;
                slv_reg2 <= slv_reg2;
                slv_reg3 <= slv_reg3;
                slv_reg4 <= slv_reg4;
                slv_reg5 <= slv_reg5;
                slv_reg6 <= slv_reg6;
                slv_reg7 <= slv_reg7;
                slv_reg8 <= slv_reg8;
                slv_reg9 <= slv_reg9;
                slv_reg10 <= slv_reg10;
              slv_reg11 <= slv_reg11;
              slv_reg12 <= slv_reg12;
              slv_reg13 <= slv_reg13;
              slv_reg14 <= slv_reg14;
              slv_reg15 <= slv_reg15;
              slv_reg16 <= slv_reg16;
              slv_reg17 <= slv_reg17;
              slv_reg18 <= slv_reg18;
              slv_reg19 <= slv_reg19;
              slv_reg20 <= slv_reg20;
            end case;
          end if;
        end if;
      end if;                   
    end process; 
end generate; --write_debug_generate






debug_reg_process_generate: if Debug generate
    debug_reg_process : process(debug_instr_3, debug_instr_2, debug_instr_1, debug_curr_data, debug_curr_opc, debug_instr_addr_1, debug_instr_addr_2, debug_instr_addr_3)
    begin
    if rising_edge(S_AXI_ACLK) then
        if(S_AXI_ARESETN = '0') then
        reg10 <= (others => '0');
        reg_control_vector <= (others => '0');
        reg_curr_ref <=  (others => '0');
        reg_curr_data_first <= (others => '0');
        reg11 <= (others => '0');
        reg12 <= (others => '0');
        reg13 <= (others => '0');
        reg14 <= (others => '0');
        reg15 <= (others => '0');
        reg16 <= (others => '0');
        reg17 <= (others => '0');
        reg18 <= (others => '0');
        reg19 <= (others => '0');
        reg20 <= (others => '0');
        else 
        reg_curr_data_first <= debug_curr_data( ((NCluster * ClusterWidth*DataWidth) - 1) downto ((NCluster * ClusterWidth*DataWidth) - C_S_AXI_DATA_WIDTH) );
        reg_curr_ref <= debug_curr_ref;
        reg_control_vector <= control_vector;
        reg10 <= padding_opcode & debug_curr_opc;
        reg11 <= padding_instr_addr & debug_instr_addr_1;
        reg12 <= padding_instr_addr & debug_instr_addr_2;
        reg13 <= padding_instr_addr & debug_instr_addr_3;
        reg14 <= debug_curr_data(C_S_AXI_DATA_WIDTH-1 downto 0);
        reg15 <= debug_instr_1(C_S_AXI_DATA_WIDTH-1 downto 0);
        reg16 <= padding_instr_ram & debug_instr_1(instr_ram_width-1 downto C_S_AXI_DATA_WIDTH);
        reg17 <= debug_instr_2(C_S_AXI_DATA_WIDTH-1 downto 0);
        reg18 <= padding_instr_ram & debug_instr_2(instr_ram_width-1 downto C_S_AXI_DATA_WIDTH);
        reg19 <= debug_instr_3(C_S_AXI_DATA_WIDTH-1 downto 0);
        reg20 <= padding_instr_ram & debug_instr_3(instr_ram_width-1 downto C_S_AXI_DATA_WIDTH);
        end if;
    end if ;
        
    end process ; -- debug_reg_process
end generate; -- debug_reg_process_generate
    -- User logic ends

end arch_imp;
