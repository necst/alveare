library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.genericsPack.all;
use work.opCodePack.all;
use work.typesPack.all;

entity Tile is
    generic(
        ---------------Core----------------------
        AddressWidthInstr       : positive := 6;
        AddressWidthData        : positive := 6;

        OpCodeBus               : positive := 11;
        OpCodeWidth             : positive := 7;
        InternalOpBus           : positive := 4;
        --
        DataWidth               : positive := 8;
        ClusterWidth            : positive := 4;
        NCluster                : positive := 4;

        CounterWidth            : positive := 1;
        BufferAddressWidth      : positive := 6;
        StackDataWidth          : positive := 23;

        ExternalBusWidthData    : positive := 128;
        InternalBusWidthData    : positive := 56;
        ExternalBusWidthInstr   : positive := 32;
        RamWidthInstr           : positive := 43;
        RamWidthData            : positive := 8;

        CharacterNumber         : positive := 11;
        Debug                   : boolean := true
        );

    port ( 
        clk              : in std_logic;
        rst              : in std_logic;
        addr_start_instr : in std_logic_vector(AddressWidthInstr - 1 downto 0);
        
        --end of the search
        no_more_characters  : in std_logic;

        src_en           : in std_logic;
        
        complete         : out std_logic;
        found            : out std_logic;
        
        curr_character      : out std_logic_vector(CharacterNumber - 1 downto 0);
        curr_last_match_char: out std_logic_vector(CharacterNumber - 1 downto 0);

        instr_address_wr : in std_logic_vector(AddressWidthInstr - 1 downto 0);
        instr_data_in    : in std_logic_vector(ExternalBusWidthInstr - 1 downto 0);
        instr_we_data    : in std_logic;
        instr_we_opcode  : in std_logic;

-- signal used for debug purposes only
        debug_curr_state     : out std_logic_vector(6 downto 0);
        debug_curr_opc       : out std_logic_vector(OpCodeBus - 1 downto 0);
        debug_instr_addr_1   : out std_logic_vector(AddressWidthInstr - 1 downto 0);
        debug_instr_addr_2   : out std_logic_vector(AddressWidthInstr - 1 downto 0);
        debug_instr_addr_3   : out std_logic_vector(AddressWidthInstr - 1 downto 0);
        debug_curr_data      : out std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        debug_curr_ref       : out std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        debug_instr_1        : out std_logic_vector (RamWidthInstr - 1 downto 0);
        debug_instr_2        : out std_logic_vector (RamWidthInstr - 1 downto 0);
        debug_instr_3        : out std_logic_vector (RamWidthInstr - 1 downto 0);
--


        data_address_wr  : in std_logic_vector(AddressWidthData - 1 downto 0);
        data_data_in     : in std_logic_vector(ExternalBusWidthData - 1 downto 0);
        data_we          : in std_logic
        );
end Tile;

architecture Behavioral of Tile is

    signal ram_instr_addr_rd_1_int      : std_logic_vector (AddressWidthInstr - 1 downto 0);
    signal ram_instr_out_1_int          : std_logic_vector (RamWidthInstr - 1 downto 0);

    signal ram_instr_addr_rd_2_int      : std_logic_vector (AddressWidthInstr - 1 downto 0);
    signal ram_instr_out_2_int          : std_logic_vector (RamWidthInstr - 1 downto 0);


    signal ram_instr_out_3_int          : std_logic_vector (RamWidthInstr - 1 downto 0);
    signal ram_instr_addr_rd_3_int      : std_logic_vector (AddressWidthInstr - 1 downto 0);

    signal ram_data_address_rd_int      : std_logic_vector(AddressWidthData - 1 downto 0);

    signal ram_data_out_int_1           : std_logic_vector(InternalBusWidthData - 1 downto 0);
    signal ram_data_out_int_2           : std_logic_vector(InternalBusWidthData - 1 downto 0);
    signal ram_data_out_int_3           : std_logic_vector(InternalBusWidthData - 1 downto 0);
    signal ram_data_out_int_4           : std_logic_vector(InternalBusWidthData - 1 downto 0);
    signal ram_data_out_int_5           : std_logic_vector(InternalBusWidthData - 1 downto 0);
    signal ram_data_out_int_6           : std_logic_vector(InternalBusWidthData - 1 downto 0);


    signal data_0                       : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
    signal data_1                       : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
    signal data_2                       : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
    signal data_3                       : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
    signal data_4                       : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
    signal data_lm                      : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );

    signal mux_data                     : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );

    signal last_match                   : std_logic_vector(AddressWidthData - 1 downto 0);
    signal cp_sel_data                  : std_logic_vector(2 downto 0);
begin
  RAMDATA       : entity work.RamData
      generic map(
          RamWidth          => RamWidthData,
          ExternalBusWidth  => ExternalBusWidthData,
          InternalBusWidth  => InternalBusWidthData,
          AddressWidth      => AddressWidthData
        )
      port map(
          rst             => rst,
          clk             => clk,
          address_rd_1    => ram_data_address_rd_int,
          address_rd_2    => last_match,
          address_wr      => data_address_wr,
          data_in         => data_data_in,
          we              => data_we,
          data_out_1      => ram_data_out_int_1,
          data_out_2      => ram_data_out_int_2,
          data_out_3      => ram_data_out_int_3,
          data_out_4      => ram_data_out_int_4,
          data_out_5      => ram_data_out_int_5,
          data_out_6      => ram_data_out_int_6
        );
  RAMINSTRUCTION : entity work.RamInstr
      generic map(
          BusWidth        => ExternalBusWidthInstr,
          DataWidth       => DataWidth,
          OpCodeWidth     => OpCodeWidth,
          ClusterWidth    => ClusterWidth,
          RamWidth        => RamWidthInstr,
          AddressWidth    => AddressWidthInstr
        )
      port map(
          rst             => rst,
          clk             => clk,
          address_rd_1    => ram_instr_addr_rd_1_int,
          address_rd_2    => ram_instr_addr_rd_2_int,
          address_rd_3    => ram_instr_addr_rd_3_int,
          address_wr      => instr_address_wr,
          data_in         => instr_data_in,
          we_data         => instr_we_data,
          we_opcode       => instr_we_opcode,
          data_out_1      => ram_instr_out_1_int,
          data_out_2      => ram_instr_out_2_int,
          data_out_3      => ram_instr_out_3_int
        );
  ALVEARECORE      : entity work.AlveareCore
      generic map(
          AddressWidthInstr => AddressWidthInstr,
          AddressWidthData  => AddressWidthData,
          OpCodeBus         => OpCodeBus,
          OpCodeWidth       => OpCodeWidth,
          InternalOpBus     => InternalOpBus,
          DataWidth         => DataWidth,
          ClusterWidth      => ClusterWidth,
          NCluster          => NCluster,
          BusWidthData      => InternalBusWidthData,

          CounterWidth      => CounterWidth,
          BufferAddressWidth=> BufferAddressWidth,
          StackDataWidth    => StackDataWidth,

          RamWidthInstr     => RamWidthInstr,
          CharacterNumber   => CharacterNumber,
          Debug             => Debug
          )
      port map(
          clk                 => clk,
          rst                 => rst,
          addr_start_instr    => addr_start_instr,
          
          no_more_characters  => no_more_characters,
          
          src_en              => src_en,
          complete            => complete,
          found               => found,
          curr_character      => curr_character,
          curr_last_match_char=> curr_last_match_char,

          debug_curr_state     => debug_curr_state,
          debug_curr_opc       => debug_curr_opc,
          debug_curr_ref       => debug_curr_ref,

          addr_instruction_1  => ram_instr_addr_rd_1_int,
          instruction_1       => ram_instr_out_1_int,
          addr_instruction_2  => ram_instr_addr_rd_2_int,
          instruction_2       => ram_instr_out_2_int,

          addr_instruction_3  => ram_instr_addr_rd_3_int,
          instruction_3       => ram_instr_out_3_int,
          addr_data_1         => ram_data_address_rd_int,
          addr_data_2         => last_match,
          data                => mux_data,
          sel_data            => cp_sel_data
          );


  Data_0_offset    : entity work.DataRegGenerator
    generic map(
      DataWidth             => DataWidth,
      ClusterWidth          => ClusterWidth,
      InternalBusWidthData  => InternalBusWidthData
      )
    port map(
      clk         => clk,
      rst         => rst,
      data_in     => ram_data_out_int_1,
      data_out    => data_0
      );
  Data_1_offset    : entity work.DataRegGenerator
    generic map(
      DataWidth             => DataWidth,
      ClusterWidth          => ClusterWidth,
      InternalBusWidthData  => InternalBusWidthData
      )
    port map(
      clk         => clk,
      rst         => rst,
      data_in     => ram_data_out_int_2,
      data_out    => data_1
      );
  Data_2_offset    : entity work.DataRegGenerator
    generic map(
      DataWidth             => DataWidth,
      ClusterWidth          => ClusterWidth,
      InternalBusWidthData  => InternalBusWidthData
      )
    port map(
      clk         => clk,
      rst         => rst,
      data_in     => ram_data_out_int_3,
      data_out    => data_2
      );
  Data_3_offset    : entity work.DataRegGenerator
    generic map(
      DataWidth             => DataWidth,
      ClusterWidth          => ClusterWidth,
      InternalBusWidthData  => InternalBusWidthData
      )
    port map(
      clk         => clk,
      rst         => rst,
      data_in     => ram_data_out_int_4,
      data_out    => data_3
      );
  Data_4_offset    : entity work.DataRegGenerator
    generic map(
      DataWidth             => DataWidth,
      ClusterWidth          => ClusterWidth,
      InternalBusWidthData  => InternalBusWidthData
      )
    port map(
      clk         => clk,
      rst         => rst,
      data_in     => ram_data_out_int_5,
      data_out    => data_4
      );
  Data_last_match    : entity work.DataRegGenerator
    generic map(
      DataWidth             => DataWidth,
      ClusterWidth          => ClusterWidth,
      InternalBusWidthData  => InternalBusWidthData
      )
    port map(
      clk         => clk,
      rst         => rst,
      data_in     => ram_data_out_int_6,
      data_out    => data_lm
      );

  RAM_DATA_MUX       : entity work.Mux6In
    generic map(
      DataWidth    => DataWIdth,
      ClusterWidth => ClusterWidth,
      NCluster     => NCluster,
      SelWidth     => 3
      )
    port map(
      data_in_1   => data_0,
      data_in_2   => data_1,
      data_in_3   => data_2,
      data_in_4   => data_3,
      data_in_5   => data_4,
      data_in_6   => data_lm,
      sel         => cp_sel_data,
      data_out    => mux_data
      );


hw_debug_generate: if Debug generate
        debug_instr_addr_1   <= ram_instr_addr_rd_1_int;
        debug_instr_addr_2   <= ram_instr_addr_rd_2_int;
        debug_instr_addr_3   <= ram_instr_addr_rd_3_int;
        debug_curr_data      <= mux_data;

        debug_instr_1        <= ram_instr_out_1_int;
        debug_instr_2        <= ram_instr_out_2_int;
        debug_instr_3        <= ram_instr_out_3_int;
end generate; --hw_debug_generate

end Behavioral;
