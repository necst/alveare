library ieee;
use ieee.std_logic_1164.all;
use work.typesPack.all;
use work.opcodePack.all;
use work.genericsPack.all;
entity Execute is
    generic(
        InternalOpBus       : positive := 3;
        ClusterWidth        : positive := 4;
        NCluster            : positive := 4;
        DataWidth           : positive := 8;
        AddressWidthData    : positive := 6;
        BusWidthData        : positive := 32
        );
    port(
        -- clock signal
        clk                 : in std_logic;
        -- reset signal, active LOW
        rst                 : in std_logic;
        -- Signal to indicate a stall in the pipeline
        stall               : in std_logic;
        -- Data coming from the Data RAM
        data                : in std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        -- Data contained in the instruction that has been decoded
        reference           : in std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        -- Vector that indicates if each data in the reference is valid or not
        valid_ref           : in std_logic_vector(ClusterWidth - 1 downto 0);
        -- operators coming from the Fetch and Decode (only AND and OR)
        operator            : in std_logic_vector(InternalOpBus - 1 downto 0);
        -- signal to indicate if there was a match among all the clusters
        match               : out std_logic;
        -- Jump of the address of the Data Ram to retrieve the next batch of data
        data_offset         : out std_logic_vector(AddressWidthData - 1 downto 0);

        disable_comparators : in std_logic_vector(1 downto 0)
        );
end Execute;

architecture behav of Execute is
    -- Internal signals to connect the various components
    signal results_i        : ResultsArray(0 to NCluster - 1);
    signal cluster_match    : std_logic_vector(NCluster - 1 downto 0);
    signal en_comparators   : std_logic_vector(NCluster - 1 downto 0);
    signal match_i          : std_logic;
    signal cluster_match_i  : std_logic_vector(NCluster - 1 downto 0);
    signal en_comparators_i : std_logic_vector(NCluster - 1 downto 0);
	signal data_i           : ClusterData(0 to NCluster - 1);
begin
    data_i              <= std_logic_vec_to_cluster_data(data);
    ENGINE          : entity work.Engine
        generic map(
            InternalOpBus       => InternalOpBus,
            NCluster            => NCluster,
            ClusterWidth        => ClusterWidth,
            AddressWidthData    => AddressWidthData
            )
        port map(
            compare_results     => results_array_to_std_logic_vec(results_i),
            valid_ref           => valid_ref,
            operator            => operator,
            address_offset      => data_offset,
            match               => match_i,
            cluster_match       => cluster_match,
            stall               => stall
            );
 
    generate_clusters   : for i in 0 to NCluster - 1 generate 
        CLUSTER_MUX : entity work.ClusterMux
            generic map(
                ClusterWidth    => ClusterWidth,
                DataWidth       => DataWidth
                )
            port map(
                operator        => operator,
                en              => en_comparators(i),-- (NCluster - (i + 1)),
                data            => cluster_array_to_std_logic_vec(data_i(i)),
                reference       => reference,
                result          => results_i(i)
                );
    end generate generate_clusters;


    en_comparators <=   (others => '0') when disable_comparators = "10" else
                        	cluster_match_i when disable_comparators = "01" else
                        (others => '1') when disable_comparators = "11" else --disable when 11
                        en_comparators_i ;
    match <= match_i;

    REG_CLUSTER_MATCH : entity work.Reg
        generic map(
            DataWidth   => NCluster
            )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => cluster_match,
            data_out    => cluster_match_i
            );

    REG_EN_COMPARATORS  : entity work.Reg
        generic map(
            DataWidth   => NCluster
            )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => en_comparators,
            data_out    => en_comparators_i
            );
end behav;
