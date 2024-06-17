library ieee;
use ieee.std_logic_1164.all;
use work.genericsPack.all;

package OpcodePack is

    -- opcodes in natural form/ positions in the decoder bus
    constant op_or    	 	: natural := 0; -- OR operator
    constant op_and   	    : natural := 1; -- AND operator
    constant op_nop      	: natural := 10; -- no operation
    constant op_cp_counter 	: natural := 5; -- counter
    constant op_cp_or   	: natural := 7; -- )| 
    constant op_opar    	: natural := 6; -- (
    constant op_not   	 	: natural := 3; -- .
    constant op_cp_count_l  : natural := 4;
	constant op_range   	: natural := 2; -- RANGE operator
    --not more used
    constant op_cp_star     : natural := 9; 
    constant op_cp      	: natural := 8; -- )
    -- not more used


    -- format of instructions
    --
    -- +---+-------+-------+
    -- ¦ 6 ¦ 5 4 3 ¦ 2 1 0 ¦
    -- +---+-------+-------+
    -- ¦ ( ¦      |¦ )|    ¦
    -- ¦   ¦   &   ¦ )count¦
    -- ¦   ¦       ¦       ¦
    -- ¦   ¦   [  ]¦ )     ¦
    -- |   | !     |       |
    -- +---+-------+-------+

    --opcodes position in instruction
    constant opParpos   	: natural := 6; --open parenthesis (6)
    constant opIpos     	: natural := 5; -- range/and/or/. opcodes (5..3)
    constant opEpos     	: natural := 2; -- closed parenthesis opcodes(2..0)
    
    --internal/external operators bitwise representation
    constant opIWidth   	: natural := 3; -- bits to represent the internal operators
    constant opEWidth   	: natural := 3; -- bits to represent the internal operators
    constant opParWidth 	: natural := 1; -- open parenthesis operator

    ----------------------------------- opcodes in binary form ---------------------------

    --internal
    constant opc_not    	: std_logic := '1';
    constant opc_or    		: std_logic_vector(opIWidth - 2 downto 0) := "01"; --0x08 (assuming before no operators)
    constant opc_and    	: std_logic_vector(opIWidth - 2 downto 0) := "10"; --0x16
	constant opc_range  	: std_logic_vector(opIWidth - 2 downto 0) := "11"; --0x20
    -- external
    constant opc_cp_counter : std_logic_vector(opEWidth - 1 downto 0) := "010"; --0x02
    constant opc_cp_count_l : std_logic_vector(opEWidth - 1 downto 0) := "001"; --0x07
    -- no more used
    constant opc_cp_star    : std_logic_vector(opEWidth - 1 downto 0) := "111"; --0x01
    constant opc_cp      	: std_logic_vector(opEWidth - 1 downto 0) := "100"; --0x04
    -- no more used
    constant opc_cp_or   	: std_logic_vector(opEWidth - 1 downto 0) := "011"; --0x03


    --open parenthesis
    constant opc_opar    	: std_logic := '1'; --0x40

    --nop
    constant opc_nop    	: std_logic_vector(OpCodeWidth - 1 downto 0) := (others => '0'); --0x00
end OpcodePack;

-- package body OpcodePack is
-- end package body OpcodePack;
