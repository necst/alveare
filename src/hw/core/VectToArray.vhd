library ieee;
use ieee.std_logic_1164.all;
use work.typesPack.all;

entity VectToArray is

    generic (
        VectWidth    : positive := 32;
        ArrWidth     : positive := 4;
        ArrCellWidth : positive := 8
        );

    port (
        vector_in    : in  std_logic_vector(VectWidth - 1 downto 0);
        array_out    : out RegisterArray(0 to ArrWidth - 1)
        );

end VectToArray;

architecture behav of VectToArray is
begin
    process (vector_in)
    begin
        for i in 0 to ArrWidth - 1 loop
            array_out(i) <= vector_in((VectWidth - 1 - i * ArrCellWidth) downto
                           (VectWidth - (i + 1) * ArrCellWidth));
        end loop;
    end process;
end behav;