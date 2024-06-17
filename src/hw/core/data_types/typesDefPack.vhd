library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.genericsPack.all;
--use work.txt_util.all; FOR DEBUG ONLY

package TypesPack is

    -- array of std_logic_vector (width = DataWidth) to map a wider std_logic_vector into
    -- the registers of the comparators
    type RegisterArray is array (natural range <>) of std_logic_vector (DataWidth - 1 downto 0);
    type ResultsArray is array (natural range <>) of std_logic_vector(ClusterWidth - 1 downto 0);
    subtype ClusterArray is RegisterArray;
    type ClusterData is array (natural range <>) of ClusterArray(0 to ClusterWidth - 1);

    function results_array_to_std_logic_vec (ra : ResultsArray(0 to NCluster - 1)) return std_logic_vector;
    function std_logic_vec_to_results_array (sv : std_logic_vector( ((NCluster * ClusterWidth) - 1) downto 0 )) return ResultsArray;
    function string_to_clusterarray(s : String) return ClusterArray;
    function string_to_std_logic_vector(s : String) return std_logic_vector;
    function std_logic_vec_to_cluster_array (sv : std_logic_vector( ((ClusterWidth * DataWidth) - 1) downto 0 )) return ClusterArray;
    function cluster_array_to_std_logic_vec (res : ClusterArray(0 to ClusterWidth - 1)) return std_logic_vector;
    function std_logic_vec_to_cluster_data (sv : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 )) return ClusterData;
    function cluster_data_to_std_logic_vec (res : ClusterData(0 to NCluster - 1)) return std_logic_vector;
end TypesPack;

package body TypesPack is

    function results_array_to_std_logic_vec (ra : ResultsArray(0 to NCluster - 1))
        return std_logic_vector is
    variable res: std_logic_vector(NCluster * ClusterWidth - 1 downto 0) := (others => '0');
    begin
        for i in 0 to NCluster-1 loop
           res( (ClusterWidth *(NCluster - 1 - i+1)- 1) downto (ClusterWidth * (NCluster - 1 - i) )):= ra(i)(ClusterWidth - 1 downto 0);
        end loop;
        return res;
    end function results_array_to_std_logic_vec;

--also here opposite alignment i think so (DAVIDE)
    function std_logic_vec_to_results_array (sv : std_logic_vector( ((NCluster * ClusterWidth) - 1) downto 0 ))
    return ResultsArray is
    variable res : ResultsArray(0 to NCluster - 1);
    begin
        for i in 0 to NCluster-1 loop
        --report  str(i)&" i";
        --report str(NCluster)&" NCluster";
          res(i) := sv( (ClusterWidth *(NCluster - 1 - i+1)- 1) downto (ClusterWidth * (NCluster - 1 - i) ));
        end loop;
        return res;
    end std_logic_vec_to_results_array;

   function std_logic_vec_to_cluster_data (sv : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 ))
   return ClusterData is
   variable res : ClusterData(0 to NCluster - 1);
   begin
       for i in 0 to NCluster-1 loop
          res(i) := std_logic_vec_to_cluster_array(sv ((ClusterWidth*DataWidth*NCluster - 1 - i * ClusterWidth*DataWidth) downto
                           (ClusterWidth*DataWidth*NCluster - (i + 1) *ClusterWidth* DataWidth)));
       end loop;
       return res;
   end std_logic_vec_to_cluster_data;

   function cluster_data_to_std_logic_vec (res : ClusterData(0 to NCluster - 1))
   return std_logic_vector	 is
   variable sv : std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
   begin
       for i in 0 to NCluster-1 loop
       	sv ((ClusterWidth*DataWidth*NCluster - 1 - i * ClusterWidth*DataWidth) downto
                           (ClusterWidth*DataWidth*NCluster - (i + 1) *ClusterWidth* DataWidth)):=cluster_array_to_std_logic_vec(res(i));
       end loop;
       return sv;
   end cluster_data_to_std_logic_vec;

    function string_to_clusterarray(s : String)
        return ClusterArray is
        variable res : ClusterArray(0 to ClusterWidth - 1);
        constant zero : std_logic_vector(DataWidth - 1 downto 0) := (others => '0');
    begin
        for i in 0 to ClusterWidth - 1 loop
            if (i < s'length) then
                res(i) := std_logic_vector(to_unsigned(character'pos(s(i+1)), DataWidth));
            else
                res(i) := zero;
            end if;
        end loop;
        return res;
    end function;

    function cluster_array_to_std_logic_vec (res : ClusterArray(0 to ClusterWidth - 1))
    	return std_logic_vector is
    	variable sv :std_logic_vector(((ClusterWidth * DataWidth) - 1) downto 0 ) ;
    begin
        for i in 0 to ClusterWidth - 1 loop
           sv((ClusterWidth*DataWidth - 1 - i * DataWidth) downto
                           (ClusterWidth*DataWidth - (i + 1) * DataWidth)):= res(i) ;
        end loop;
        return sv;
    end cluster_array_to_std_logic_vec;

    function std_logic_vec_to_cluster_array (sv : std_logic_vector( ((ClusterWidth * DataWidth) - 1) downto 0 ))
    	return ClusterArray is
    	variable res : ClusterArray(0 to ClusterWidth - 1);
    begin
        for i in 0 to ClusterWidth - 1 loop
            res(i) := sv((ClusterWidth*DataWidth - 1 - i * DataWidth) downto
                           (ClusterWidth*DataWidth - (i + 1) * DataWidth));
        end loop;
        return res;
    end std_logic_vec_to_cluster_array;

--function to convert a string into std_logic_vector used for tb purposes, thus right-hand aligned
     function string_to_std_logic_vector(s : String)
        return std_logic_vector is
        variable res : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        constant zero : std_logic_vector(DataWidth - 1 downto 0) := (others => '0');
    begin
        --report s;
        for i in 0 to ClusterWidth - 1 loop
            if (i < s'length) then
                --inverse alignment "AD" --> 414400
                res( ((ClusterWidth - 1 - i + 1) * DataWidth - 1) downto ((ClusterWidth - 1- i) * DataWidth) ) := std_logic_vector(to_unsigned(character'pos(s(i+1)), DataWidth));
            else
                res( ((ClusterWidth - 1 - i + 1) * DataWidth - 1) downto ((ClusterWidth - 1- i) * DataWidth) ) := zero;
            end if;
        end loop;
        --report hstr(res);
        return res;
    end function;

end package body TypesPack;

