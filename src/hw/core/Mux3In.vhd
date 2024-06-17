library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Mux3In is
    generic(
        DataWidth   : positive;
        SelWidth    : positive := 2
        );
    port (
        data_in_1   : in std_logic_vector(DataWidth - 1 downto 0);
        data_in_2   : in std_logic_vector(DataWidth - 1 downto 0);
        data_in_3   : in std_logic_vector(DataWidth - 1 downto 0);
        sel         : in std_logic_vector(SelWidth - 1 downto 0);
        data_out    : out std_logic_vector(DataWidth - 1 downto 0)

        );
end Mux3In;

architecture Behavioral of Mux3In is

begin

    Multiplexer : process( data_in_1, data_in_2, data_in_3, sel )
    begin
        if sel = "00" then
            data_out <= data_in_1;
        elsif sel = "01" then
            data_out <= data_in_2;
        else
            data_out <= data_in_3;
        end if ;
        
    end process ; -- Multiplexer

end Behavioral;
