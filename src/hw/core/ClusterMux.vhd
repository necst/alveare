library ieee;
use ieee.std_logic_1164.all;
use work.typesPack.all;
use work.genericsPack.all;
use work.opcodePack.all;

entity ClusterMux is
    generic(
        ClusterWidth        : positive := 4;
        DataWidth           : positive := 8
        );
    port(
        -- signal to enable the comparators. HIGH comparators are disabled, LOW they are enabled
        en                  : in std_logic;
        -- operation could be compare or a range
        operator            : in std_logic_vector(InternalOpBus - 1 downto 0);
        -- data to be given to the comparators and to be checked
        data                : in std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        -- reference to do the comparison with the data
        reference           : in std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        -- results of the cluster
        result              : out std_logic_vector(ClusterWidth - 1 downto 0)
        );
end ClusterMux;
    
architecture struct of ClusterMux is
    signal data_i           : ClusterArray(0 to ClusterWidth - 1);
    signal data_a           : ClusterArray(0 to ClusterWidth - 1); 
	signal is_or_range	    : std_logic;
    signal op_is_range      : std_logic;	
begin
    is_or_range    <= operator(op_range) or operator(op_or);
    op_is_range    <= operator(op_range);
    data_a         <= std_logic_vec_to_cluster_array(data);
    generate_mux    : for i in 0 to ClusterWidth - 1 generate
        Mux     : entity work.Mux
            generic map(
                DataWidth       => DataWidth
                )
            port map(
                data_in_1       => data_a(i),
                data_in_2       => data_a(0),
                sel             => is_or_range,
                data_out        => data_i(i)
                );
    end generate generate_mux; 

    Cluster : entity work.Cluster
        generic map(
            ClusterWidth    => ClusterWidth,
            DataWidth       => DataWidth
            )
        port map(
            en              => en,
            data            => cluster_array_to_std_logic_vec(data_i),
            reference       => reference,
            op_is_range     => op_is_range,
            result          => result
            );
end struct;
