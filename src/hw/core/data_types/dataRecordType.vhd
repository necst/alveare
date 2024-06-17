library ieee;
use ieee.std_logic_1164.all;
use work.genericsPack.all;
use work.typesPack.all;

package DataRecordType is
    type dataRegisterOutput is record
        data_cluster_1  : ClusterArray(0 to ClusterWidth - 1);
        data_cluster_2  : ClusterArray(0 to ClusterWidth - 1);
        data_cluster_3  : ClusterArray(0 to ClusterWidth - 1);
        data_cluster_4  : ClusterArray(0 to ClusterWidth - 1);
    end record dataRegisterOutput;

    constant zero_data  : dataRegisterOutput    := (data_cluster_1 => (others => (others => '0')),
                                                    data_cluster_2 => (others => (others => '0')),
                                                    data_cluster_3 => (others => (others => '0')),
                                                    data_cluster_4 => (others => (others => '0')));
end package DataRecordType;
