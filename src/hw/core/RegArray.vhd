library ieee;
use ieee.std_logic_1164.all;
use work.typesPack.all;

entity RegArray is
    generic(
        ArrWidth        : positive := 4
        );
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        data_in         : in ClusterArray(0 to ArrWidth - 1);
        data_out        : out ClusterArray(0 to ArrWidth - 1)
        );
end RegArray;

architecture behav of RegArray is

begin
    process (clk, rst)
    begin
        if rst = '0' then
            data_out <= (others => (others => '0'));
        elsif rising_edge(clk) then
            data_out <= data_in;
        end if; 
    end process;
end behav;
