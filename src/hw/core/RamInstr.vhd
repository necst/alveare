library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RamInstr is
    generic
      (
      -- Number of bits that defines the length of the address. The DataRam
       -- will have 2^AddressWidth cells
      BusWidth      : positive := 32; -- DataWidth * ClusterWidth
      DataWidth     : positive := 8;  -- chracter size
      OpCodeWidth   : positive := 7;  -- opcode instrzuion size
      AddressWidth  : positive := 7;  -- instruction ram size 2*AddressWidth
      RamWidth      : positive := 43; -- BusWidth + OpCodeWidth + ClusterWidth(valid reference)
      ClusterWidth  : positive := 4   -- parallel character at one clock cycle 
      );
  port
    (
      rst             : in std_logic;
      clk             : in std_logic;
      data_in         : in std_logic_vector(BusWidth - 1 downto 0);
      address_rd_1    : in std_logic_vector(AddressWidth - 1 downto 0);
      address_rd_2    : in std_logic_vector(AddressWidth - 1 downto 0);
      address_rd_3    : in std_logic_vector(AddressWidth - 1 downto 0);
      address_wr      : in std_logic_vector(AddressWidth - 1 downto 0);

      we_data         : in std_logic;
      we_opcode       : in std_logic;
      data_out_1      : out std_logic_vector(RamWidth - 1 downto 0);
      data_out_2      : out std_logic_vector(RamWidth - 1 downto 0);
      data_out_3      : out std_logic_vector(RamWidth - 1 downto 0)

      );
end RamInstr;

architecture beh of RamInstr is
  type RAM is array(INTEGER RANGE <>) of std_logic_vector(RamWidth - 1 downto 0);

  signal b_ram : RAM(0 to 2 ** AddressWidth - 1);
begin
  data_out_1 <= b_ram(to_integer(unsigned(address_rd_1)));
  data_out_2 <= b_ram(to_integer(unsigned(address_rd_2)));
  data_out_3 <= b_ram(to_integer(unsigned(address_rd_3)));

  process (clk, rst)
  begin
    if rst = '0' then
        b_ram <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if we_data = '1' then
        b_ram(to_integer(unsigned(address_wr)))(DataWidth * ClusterWidth - 1 downto 0) <= data_in(DataWidth * ClusterWidth - 1 downto 0);
      elsif we_opcode = '1' then
        b_ram(to_integer(unsigned(address_wr)))(RamWidth - 1 downto DataWidth * ClusterWidth) <= data_in(OpCodeWidth + ClusterWidth - 1 downto 0);
      end if;
    end if;
  end process;
end beh;
