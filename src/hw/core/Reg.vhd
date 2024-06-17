library ieee;
use ieee.std_logic_1164.all;

entity Reg is
    generic(
        DataWidth       : positive := 8
        );
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        data_in         : in std_logic_vector(DataWidth - 1 downto 0);
        data_out        : out std_logic_vector(DataWidth - 1 downto 0)
        );
end Reg;

architecture behav of Reg is

begin
    process (clk, rst)
    begin
        if rst = '0' then
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            data_out <= data_in;
        end if; 
    end process;
end behav;
