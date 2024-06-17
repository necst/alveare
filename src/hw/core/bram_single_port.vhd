library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
   entity bram_single_port is
    generic(
        DataWidth : positive := 16;
        AddrWidth : positive := 10
    );
    port(
     clk       : in  std_logic;
     we        : in  std_logic;
     en        : in  std_logic;
     addr      : in  std_logic_vector(AddrWidth - 1 downto 0);
     data_in   : in  std_logic_vector(DataWidth - 1 downto 0);
     data_out  : out std_logic_vector(DataWidth - 1 downto 0)
    );
   end bram_single_port;
architecture syn of bram_single_port is
  type ram_type is array (2**AddrWidth - 1 downto 0) of std_logic_vector(DataWidth - 1 downto 0); 
  signal RAM : ram_type;
begin
    process(clk)
    begin
     if clk'event and clk = '1' then
      if en = '1' then
       if we = '1' then
        RAM(conv_integer(addr)) <= data_in;
        data_out                <= data_in;
       else
        data_out <= RAM(conv_integer(addr));
       end if;
      end if;
     end if;
    end process;
end syn;
