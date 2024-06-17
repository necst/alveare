--cache set-associative
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity CacheSetAssociative is
generic(
     NAssociativityBit   : integer  := 2;
     AddressWidth        : integer  := 8;
     InternalBusWidth    : positive := 32;
     RamDataWidth        : integer  := 8
);

port(
     clk          : in  std_logic;
     read_addr    : in  std_logic_vector(AddressWidth - 1 downto 0);
     read_data    : out std_logic_vector(InternalBusWidth - 1 downto 0);
     write_addr   : in  std_logic_vector(AddressWidth - 1 downto 0);
     write_data   : in  std_logic_vector(InternalBusWidth - 1 downto 0);
     write_enable : in  std_logic_vector(InternalBusWidth / RamDataWidth - 1 downto 0)
);
end CacheSetAssociative;


architecture behav of CacheSetAssociative is
constant SingleMemorySize : natural := 2**AddressWidth;
signal set_read_enable  :  std_logic_vector(NAssociativityBit downto 0);
signal set_write_enable :  std_logic_vector(NAssociativityBit downto 0);
signal we_a             :  (others => '0');
signal addr_a           :  std_logic_vector(AddressWidth - 1 downto 0);
signal data_in_a        :  (others => '0');
signal data_out_a       :  std_logic_vector(InternalBusWidth - 1 downto 0); 
signal we_b             :  std_logic_vector(InternalBusWidth / RamDataWidth - 1 downto 0);
signal addr_b           :  std_logic_vector(AddressWidth - 1 downto 0);
signal data_in_b        :  std_logic_vector(InternalBusWidth - 1 downto 0);
signal data_out_b       :  std_logic_vector(InternalBusWidth - 1 downto 0);

begin
generate_set  : for i in NAssociativityBit to 0 generate
     generic map(
         SingleMemorySize        => Size,
         AddressWidth            => AddressWidth,
         RamDataWidth            => RamDataWidth,
         InternalBusWidth        => InternalBusWidth
    )
     port map(
         clk        => clk,
         data_out_a => data_out_a,
         data_out_b => data_out_b,
         data_in_a  => data_in_a,
         data_in_b  => data_in_b,
         addr_b     => addr_b,
         addr_a     => addr_a,
         en_a       => set_read_enable(i),
         en_b       => set_write_enable(i),
         we_a       => we_a,
         we_b       => we_b
         );
end generate generate_set; 

addr_a    <= read_addr;
read_data <= data_in_b;
addr_b    <= write_addr;
data_in_b <= write_data;
we_b      <= write_enable; -- 
end behav;
