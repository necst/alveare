library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity AddrGenerator is
  generic(
    AddressWidthData : positive := 4;
    NCluster         : positive := 1;
    ClusterWidth     : positive := 2
    );

  port(
    -- Vector of results of the clusters
    cluster_result : in  std_logic_vector(NCluster - 1 downto 0);
    -- One-hot vector representing which cluster made the match. The '0' corresponds
    -- to the cluste that made the match
    cluster_match  : out std_logic_vector(NCluster - 1 downto 0)
    );
end entity;

architecture behav of AddrGenerator is
begin
--maybe reverse the order according to the data flow
    cluster_match_gen : process (cluster_result)
    begin
		for i in NCluster - 1 downto 0  loop
			if cluster_result(i) = '1' then
				cluster_match(i) <= '0';
			else 
				cluster_match(i) <= '1';
			end if;
		end loop;
    end process cluster_match_gen;
end behav;
