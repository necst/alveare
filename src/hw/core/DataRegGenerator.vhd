library ieee;
use ieee.std_logic_1164.all;
use work.typesPack.all;
use work.genericsPack.all;

entity DataRegGenerator is
    generic(
        DataWidth               : positive := 8;
        ClusterWidth            : positive := 4;
        InternalBusWidthData    : positive := 56;
        NCluster                : positive := 4
        );
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        data_in         : in std_logic_vector(InternalBusWidthData - 1 downto 0);
        data_out        : out std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 )
        );
end DataRegGenerator;

architecture struct of DataRegGenerator is
    signal array_data   : ClusterData(0 to ClusterWidth - 1);
    signal data_out_i   : ClusterData(0 to ClusterWidth - 1);
begin
    generate_array : for i in 0 to ClusterWidth - 1 generate
        Vector_to_Array : entity work.VectToArray 
            generic map(
                VectWidth       => DataWidth * ClusterWidth,
                ArrWidth        => ClusterWidth,
                ArrCellWidth    => DataWidth
                )
            port map(
                vector_in       => data_in(InternalBusWidthData - i * DataWidth - 1 downto (ClusterWidth - 1 - i) * DataWidth),
                array_out       => array_data(i)
                );
    end generate;

    generate_cluster_data : for i in 0 to ClusterWidth - 1 generate
        Reg_Array   : entity work.RegArray
            generic map(
                ArrWidth   => ClusterWidth
                )
            port map(
                clk         => clk,
                rst         => rst,
                data_in     => array_data(i),
                data_out    => data_out_i(i)
                );
    end generate;
    data_out <= cluster_data_to_std_logic_vec(data_out_i);
end struct;
