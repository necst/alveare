library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.typesPack.all;
use work.genericsPack.all;

entity Mux6In is
    generic(
        DataWidth       : positive := 8;
        ClusterWidth    : positive := 4;
        NCluster        : positive := 4;
        SelWidth        : positive := 3
        );
    port (
        data_in_1   : in std_logic_vector( ((NCluster * ClusterWidth * DataWidth) - 1) downto 0 );
        data_in_2   : in std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        data_in_3   : in std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        data_in_4   : in std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        data_in_5   : in std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        data_in_6   : in std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        sel         : in std_logic_vector(SelWidth - 1 downto 0);
        data_out    : out std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 )
        );
end Mux6In;

architecture Behavioral of Mux6In is

begin

    Multiplexer : process( data_in_1, data_in_2, data_in_3, data_in_4, data_in_5, data_in_6, sel )
    begin
        if sel = "000" then
            data_out <= data_in_1;
        elsif sel = "001" then
            data_out <= data_in_2;
        elsif sel = "010" then
            data_out <= data_in_3;
        elsif sel = "011" then 
            data_out <= data_in_4;
        elsif sel = "100" then
            data_out <= data_in_5;
        elsif sel = "101" then
            data_out <= data_in_6;
        else
            data_out <= (others => '0');
        end if;
        
    end process ; -- Multiplexer

end Behavioral;