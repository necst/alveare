library ieee;
use ieee.std_logic_1164.all;

entity Mux is
    generic(
        DataWidth       : positive
        );
    port(
        data_in_1       : in std_logic_vector(DataWidth - 1 downto 0);
        data_in_2       : in std_logic_vector(DataWidth - 1 downto 0);
        sel             : in std_logic;
        data_out        : out std_logic_vector(DataWidth - 1 downto 0)
        );
end Mux;

architecture behav of Mux is
    
begin
    process (data_in_1, data_in_2, sel)
    begin
        if sel = '0' then
            data_out <= data_in_1;
        else 
            data_out <= data_in_2;
        end if;
    end process;
end behav;
