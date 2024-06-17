library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CompareUnit is
    generic(
        DataWidth       : positive := 8
        );
    port(
        -- enable comparators signal. if HIGH comparators are disabled, if LOW
        -- the comparator is enabled
        en              : in std_logic;
        -- data to be checked
        data            : in std_logic_vector(DataWidth - 1 downto 0);
        -- reference to be put in comparison with the data
        reference       : in std_logic_vector(DataWidth - 1 downto 0);
        -- result of the comparison
        result          : out std_logic
        );
end CompareUnit;

architecture behav of CompareUnit is

begin
    process(en, data, reference)
    begin
        if data = reference then
            result <= '1' and (not en);
        else
            result <= '0' and (not en);
        end if;
    end process;
end behav;
