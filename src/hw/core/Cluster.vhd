library ieee;
use ieee.std_logic_1164.all;
use work.typesPack.all;

entity Cluster is
    generic(
        ClusterWidth        : positive := 2;
        DataWidth           : positive := 8
        );
    port(
        -- Signal to enable or disable the comparators. If HIGH comparators
        -- are disabled, if LOW comparators are enabled
        en                  : in std_logic;
        -- data to check
        data                : in std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        -- reference data for the comparison
        reference           : in std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        -- select if the operation is a compare or a range 
        op_is_range         : in std_logic; 
        -- vector of results. Each bit correspond to a comparator
        result              : out std_logic_vector(0 to ClusterWidth - 1)
        );
end Cluster;

architecture struct of Cluster is
signal result_cmp_i : std_logic_vector(0 to ClusterWidth-1);
signal result_range_i : std_logic_vector(0 to ClusterWidth-1) := (others=>'0');
signal reference_i      : ClusterArray(0 to ClusterWidth - 1);
signal data_i     : ClusterArray(0 to ClusterWidth - 1);
begin
	data_i <= std_logic_vec_to_cluster_array(data);
    reference_i <=std_logic_vec_to_cluster_array(reference);
    comp_gen : for i in 0 to ClusterWidth - 1 generate
        Comparator : entity work.CompareUnit
                generic map(
                    DataWidth     => DataWidth
                )
                port map(
                    en            => en,
                    data          => data_i(i),
                    reference     => reference_i(i),
                    result        => result_cmp_i(i)    
                );
    end generate comp_gen;
    range_gen : for i in 0 to ClusterWidth/2 - 1 generate 
        Ranger : entity work.RangeUnit_v2
                generic map(
                    DataWidth     => DataWidth
                )
                port map(
                    i_en          => en, 
                    i_data        => data_i(i),
                    i_reference_1 => reference_i(i*2),
                    i_reference_2 => reference_i((i+1)*2-1),
                    o_match       => result_range_i(i*2)
                );
 --  result_range_i(i+1) <= result_range_i(i);
    end generate range_gen;
        Mux : entity work.Mux
          generic map(
              DataWidth       => ClusterWidth
          )
          port map(
              data_in_1       => result_cmp_i,
              data_in_2       => result_range_i,
              sel             => op_is_range,
              data_out        => result
          );
end struct;
