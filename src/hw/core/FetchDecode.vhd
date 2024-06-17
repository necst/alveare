library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.opcodePack.all;

entity FetchDecode is
    generic(
        -- Number of comparators in each cluster
        ClusterWidth    : positive := 4;
        -- Number of operators that are present in the one-hot vector
        OpCodeBus       : positive := 11; 
        -- Number of bits of the instruction which represent the opcode
        OpCodeWidth     : positive := 7;
        -- Length of the data that has to be checked (Usually is 8 corresponding to the ASCII encoding)
        DataWidth       : positive := 8
        );
    port(
        -- Instruction semt by the Instruction Ram
        instruction     : in std_logic_vector((DataWidth * ClusterWidth + OpCodeWidth + ClusterWidth) - 1 downto 0);
        -- One-hot vector representing the decoded opcode
        op_code_out     : out std_logic_vector(OpCodeBus - 1 downto 0);
        -- Vector of bits: if a bit is "1" it means that the corresponding reference character is valid
        -- and has to be counted in the comparison
        valid_ref       : out std_logic_vector(ClusterWidth - 1 downto 0);
        -- Reference data decoded from the instruction
        instr_data      : out std_logic_vector((DataWidth * ClusterWidth) - 1 downto 0)
        );
end FetchDecode;

architecture behav of FetchDecode is
    -- Internal Signals
    signal instr_data_i : std_logic_vector((DataWidth * ClusterWidth) - 1 downto 0);
    signal op_code_i    : std_logic_vector(OpCodeWidth - 1 downto 0);
begin
    -- Extraction of the instruction data to pass as reference to the Execute
    instr_data_i                <= instruction((DataWidth * ClusterWidth) - 1 downto 0);
    instr_data                  <= instr_data_i;

    -- Extraction of the opcode and generation of the opcode one-hot vector
    op_code_i                   <= instruction((DataWidth * ClusterWidth + OpCodeWidth) - 1 downto (ClusterWidth * DataWidth));
    -- internal operators
    op_code_out(op_or)          <= '1' when op_code_i(opIpos - 1 downto opIpos-opIWidth+1) = opc_or else '0';
    op_code_out(op_and)         <= '1' when op_code_i(opIpos - 1 downto opIpos-opIWidth+1) = opc_and else '0';
    op_code_out(op_not)         <= '1' when op_code_i(opIpos) = opc_not else '0';   
    op_code_out(op_range)       <= '1' when op_code_i(opIpos - 1 downto opIpos-opIWidth+1) = opc_range else '0';
    -- external operators
    op_code_out(op_cp_counter)  <= '1' when op_code_i(opEpos downto opEpos-opEWidth+1) = opc_cp_counter else '0';
    op_code_out(op_cp_count_l)  <= '1' when op_code_i(opEpos downto opEpos-opEWidth+1) = opc_cp_count_l else '0';
    -- to remove
    op_code_out(op_cp_star)     <= '1' when op_code_i(opEpos downto opEpos-opEWidth+1) = opc_cp_star else '0';
    -- end remove
    op_code_out(op_cp_or)       <= '1' when op_code_i(opEpos downto opEpos-opEWidth+1) = opc_cp_or else '0';
    op_code_out(op_cp)          <= '1' when op_code_i(opEpos downto opEpos-opEWidth+1) = opc_cp else '0';
    -- open braketss
    op_code_out(op_opar)        <= '1' when op_code_i(opParpos) = opc_opar else '0';
    --end of program
    op_code_out(op_nop)         <= '1' when op_code_i = opc_nop else '0';

    -- This process calculates the valid_reference vector
    process (instruction)
    begin
        for i in 0 to ClusterWidth - 1 loop
            if instruction(DataWidth * ClusterWidth + OpCodeWidth + i) = '0' then
                valid_ref(i) <= '0';
            else
                valid_ref(i) <= '1';
            end if;
        end loop;
    end process;

end behav;
