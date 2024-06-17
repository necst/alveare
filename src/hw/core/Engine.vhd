library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.opcodePack.all;
use work.typesPack.all;

entity Engine is
    generic(
        InternalOpBus       : positive := 3;
        NCluster            : positive := 4;
        ClusterWidth        : positive := 4;
        AddressWidthData    : positive := 6
        );
    port(
        -- A vector that contain the single cluster result
        compare_results     : in  std_logic_vector(NCluster * ClusterWidth - 1 downto 0);--ResultsArray(0 to NCluster - 1); 
        -- Valid characters in the instruction
        valid_ref           : in std_logic_vector(ClusterWidth - 1 downto 0);
        -- Opcode of the instruction 
        operator            : in std_logic_vector(InternalOpBus - 1 downto 0);
        -- Data offset produced by the Address generator according to the operator and the valide ref            
        address_offset      : out std_logic_vector(AddressWidthData - 1 downto 0);
        -- Cycle result          
        match               : out std_logic;
        -- Vector of bits representing which cluster has done the match
        -- The cluster that matched correspond to the '0' in the vector.
        -- All the other values are set to '1'
        cluster_match       : out std_logic_vector(NCluster - 1 downto 0);
        -- Signal coming from the Control Path to stall or not the execution, active high        
        stall               : in std_logic
        );
end Engine;

architecture behav of Engine is
    signal valid_ref_bin        : std_logic_vector(ClusterWidth - 1 downto 0);
    signal match_i              : std_logic;
    signal valid_ref_int        : std_logic_vector(ClusterWidth - 1 downto 0);
    signal compare_results_int  : ResultsArray(0 to NCluster - 1);
begin
    
    valid_ref_int       <= valid_ref;
    compare_results_int <= std_logic_vec_to_results_array(compare_results);
    match               <= match_i;
    --------------------------------------------------- 
    -- Computation of the binary value of valide_ref --
    ---------------------------------------------------

    valid_ref_bin_conv : process (valid_ref, operator, match_i)
    variable COUNT: integer;
    begin
		COUNT := 0;
	    for i in ClusterWidth - 1 downto 0 loop
	              if valid_ref(i) = '1' then
					COUNT := COUNT + 1;
				  else
					COUNT := COUNT;
				  end if;
	    end loop;
        if match_i = '0' then
            address_offset <= std_logic_vector(to_unsigned(ClusterWidth,AddressWidthData));
        elsif operator(op_and) = '1' then
            address_offset <= std_logic_vector(to_unsigned(COUNT,AddressWidthData));
        elsif operator(op_or) = '1' or operator(op_range) = '1' then
            address_offset <= std_logic_vector(to_unsigned(1,AddressWidthData));
        else
            address_offset <= (others => '0');
        end if;
    end process valid_ref_bin_conv;

    -------------------------------------------------------------------------------
    -- Processing of the results by the comparators if the exectuion not stalled --
    -------------------------------------------------------------------------------
process (compare_results_int, operator, valid_ref)
	variable FIND : integer;
    begin
		FIND := -1;
    if operator(op_or) = '1' or operator(op_range) = '1' then
			for i in NCluster - 1 downto 0 loop
				for j in ClusterWidth - 1 downto 0  loop          
				    if valid_ref(j) = '1' and compare_results_int(i)(j) = valid_ref(j) then
						  FIND := i;
				    else
						  FIND := FIND;
					end if;
				end loop;
			end loop;
    elsif operator(op_and) = '1' then
			for i in NCluster - 1 downto 0  loop
			    if compare_results_int(i) = valid_ref then
					  FIND := i;
				  else
					  FIND := FIND;
				  end if;
      end loop;
    else
      FIND := -1;
    end if;
	   
	for i in NCluster - 1 downto 0 loop
	  if i = FIND then
			cluster_match(i)    <= '0';
    else
		  cluster_match(i)    <= '1';
		end if;
  end loop;

  if FIND = -1 then
    if operator(op_not) = '1' then 
      cluster_match(0)    <= '0';
      match_i             <= '1';
    else
      match_i             <= '0';
    end if;
  else
    match_i               <= '1';
  end if;

end process;

end behav;

