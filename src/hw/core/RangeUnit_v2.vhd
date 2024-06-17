library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RangeUnit_v2 is
 generic(
	DataWidth : positive := 8
 );
 
 Port (
      i_en          : in std_logic; 
      i_data        : in std_logic_vector(DataWidth-1 downto 0);
      i_reference_1 : in std_logic_vector(DataWidth-1 downto 0);
      i_reference_2 : in std_logic_vector(DataWidth-1 downto 0);
      o_match       : out std_logic
 );
end RangeUnit_v2;

architecture Behavioral of RangeUnit_v2 is
signal output_ru : std_logic := '1';
begin
	process(i_data, i_en, i_reference_1, i_reference_2) 
	begin
         if(i_data >= i_reference_1 and i_data <= i_reference_2) then
           output_ru <= '1' and (not i_en);
         else
           output_ru <= '0' and (not i_en);
		   end if;
	end process;
    o_match <= output_ru;
end Behavioral;
