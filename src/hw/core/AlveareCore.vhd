library ieee;
use ieee.std_logic_1164.all;
use work.opcodePack.all;
use work.typesPack.all;

entity AlveareCore is
    generic(
        AddressWidthInstr   : positive := 6;
        AddressWidthData    : positive := 4;
        OpCodeBus           : positive := 10;
        OpCodeWidth         : positive := 6;
        InternalOpBus       : positive := 2;
        DataWidth           : positive := 8;
        ClusterWidth        : positive := 2;
        BusWidthData        : positive := 32;
        RamWidthInstr       : positive := 43;
        CharacterNumber     : positive := 11;

        CounterWidth        : positive := 3;
        StackDataWidth      : positive := 17;
        BufferAddressWidth  : positive := 6;

        NCluster            : positive := 1;
        Debug               : boolean := false

        );
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;

        addr_start_instr    : in std_logic_vector(AddressWidthInstr - 1 downto 0);

        no_more_characters  : in std_logic;

        src_en              : in std_logic;
        complete            : out std_logic;
        found               : out std_logic;
        curr_character      : out std_logic_vector(CharacterNumber - 1 downto 0);
        curr_last_match_char: out std_logic_vector(CharacterNumber - 1 downto 0);

        debug_curr_state     : out std_logic_vector(6 downto 0);
        debug_curr_opc       : out std_logic_vector(OpCodeBus - 1 downto 0);
        debug_curr_ref       : out std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);

        addr_instruction_1  : out std_logic_vector(AddressWidthInstr - 1 downto 0);
        addr_instruction_2  : out std_logic_vector(AddressWidthInstr - 1 downto 0);
        instruction_1       : in std_logic_vector(RamWidthInstr - 1 downto 0);
        instruction_2       : in std_logic_vector(RamWidthInstr - 1 downto 0);

        addr_instruction_3  : out std_logic_vector(AddressWidthInstr - 1 downto 0);
        instruction_3       : in std_logic_vector(RamWidthInstr - 1 downto 0);
        addr_data_1         : out std_logic_vector(AddressWidthData - 1 downto 0);
        addr_data_2         : out std_logic_vector(AddressWidthData - 1 downto 0);
        data                : in std_logic_vector( ((NCluster * ClusterWidth*DataWidth) - 1) downto 0 );
        sel_data            : out std_logic_vector(2 downto 0)
        );  
end AlveareCore;

architecture behav of AlveareCore is

    constant FDSel              : positive := 2;


    ------Internal Signals needed to link the different components ----------------
    signal fd_op_code_a             : std_logic_vector(OpCodeBus - 1 downto 0);
    signal fd_instr_data_a          : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal fd_valid_ref_a           : std_logic_vector(ClusterWidth - 1 downto 0);

    signal fd_op_code_b             : std_logic_vector(OpCodeBus - 1 downto 0);
    signal fd_instr_data_b          : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal fd_valid_ref_b           : std_logic_vector(ClusterWidth - 1 downto 0);
    
    signal fd_op_code_c             : std_logic_vector(OpCodeBus - 1 downto 0);
    signal fd_instr_data_c          : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal fd_valid_ref_c           : std_logic_vector(ClusterWidth - 1 downto 0);
    
    signal reg_op_code_a            : std_logic_vector(OpCodeBus - 1 downto 0);
    signal reg_instr_data_a         : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal reg_valid_ref_a          : std_logic_vector(ClusterWidth - 1 downto 0);
    
    signal reg_op_code_b            : std_logic_vector(OpCodeBus - 1 downto 0);
    signal reg_instr_data_b         : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal reg_valid_ref_b          : std_logic_vector(ClusterWidth - 1 downto 0);
    
    signal reg_op_code_c            : std_logic_vector(OpCodeBus - 1 downto 0);
    signal reg_instr_data_c         : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal reg_valid_ref_c          : std_logic_vector(ClusterWidth - 1 downto 0);
    
    signal fd_op_code_start         : std_logic_vector(OpCodeBus - 1 downto 0);
    signal fd_instr_data_start      : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal fd_valid_ref_start       : std_logic_vector(ClusterWidth - 1 downto 0);
    
    signal reg_op_code_start        : std_logic_vector(OpCodeBus - 1 downto 0);
    signal reg_instr_data_start     : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal reg_valid_ref_start      : std_logic_vector(ClusterWidth - 1 downto 0);

    signal mux_opcode               : std_logic_vector(OpCodeBus - 1 downto 0);
    signal mux_instr_data           : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal mux_valid_ref            : std_logic_vector(ClusterWidth - 1 downto 0);
    signal mux_addr_instr           : std_logic_vector(AddressWidthInstr - 1 downto 0);

    signal ex_data_offset           : std_logic_vector(AddressWidthData - 1 downto 0);
    signal ex_match                 : std_logic;
    signal jumps_offset_i           : std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal speculation_flag_i       : std_logic;
    signal backtracking_flag_i      : std_logic;
    signal minimum_cntr_flag_i      : std_logic;
    signal maximum_cntr_flag_i      : std_logic;
    signal lazy_flag_i              : std_logic;

    signal addr_instruction_1_i     : std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal addr_instruction_2_i     : std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal addr_instruction_3_i     : std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal addr_instr_start_i       : std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal reg_addr_instruction_1_i : std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal reg_addr_instruction_2_i : std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal reg_addr_instruction_3_i : std_logic_vector(AddressWidthInstr - 1 downto 0);
    signal reg_addr_instr_start_i   : std_logic_vector(AddressWidthInstr - 1 downto 0);

    signal cp_sel_fd                : std_logic_vector(FDSel - 1 downto 0);
    signal cp_stall                 : std_logic;
    signal cp_dis_comparators       : std_logic_vector(1 downto 0);
    
begin


    FETCH_DECODE_A  : entity work.FetchDecode
        generic map(
            ClusterWidth        => ClusterWidth,
            OpCodeBus           => OpCodeBus,
            OpCodeWidth         => OpCodeWidth,
            DataWidth           => DataWidth
            )
        port map(
            instruction         => instruction_1,
            op_code_out         => fd_op_code_a,
            valid_ref           => fd_valid_ref_a,
            instr_data          => fd_instr_data_a
            );

    FETCH_DECODE_B  : entity work.FetchDecode
        generic map(
            ClusterWidth        => ClusterWidth,
            OpCodeBus           => OpCodeBus,
            OpCodeWidth         => OpCodeWidth,
            DataWidth           => DataWidth
            )
        port map(
            instruction         => instruction_2,
            op_code_out         => fd_op_code_b,
            valid_ref           => fd_valid_ref_b,
            instr_data          => fd_instr_data_b
            );

    FETCH_DECODE_C  : entity work.FetchDecode
        generic map(
            ClusterWidth        => ClusterWidth,
            OpCodeBus           => OpCodeBus,
            OpCodeWidth         => OpCodeWidth,
            DataWidth           => DataWidth
            )
        port map(
            instruction         => instruction_3,
            op_code_out         => fd_op_code_c,
            valid_ref           => fd_valid_ref_c,
            instr_data          => fd_instr_data_c
            );
            
------------------------------------------------------

    INSTR_1_ADDR_REG    : entity work.Reg
        generic map(
            DataWidth           => AddressWidthInstr
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => addr_instruction_1_i,
            data_out            => reg_addr_instruction_1_i
            );

    INSTR_2_ADDR_REG    : entity work.Reg
        generic map(
            DataWidth           => AddressWidthInstr
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => addr_instruction_2_i,
            data_out            => reg_addr_instruction_2_i
            );

    INSTR_3_ADDR_REG    : entity work.Reg
        generic map(
            DataWidth           => AddressWidthInstr
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => addr_instruction_3_i,
            data_out            => reg_addr_instruction_3_i
            );


    START_ADDR_REG    : entity work.Reg
        generic map(
            DataWidth           => AddressWidthInstr
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => addr_instr_start_i,
            data_out            => reg_addr_instr_start_i
            );
            
    -------------------
    OPCODE_REG_A        : entity work.Reg
        generic map(
            DataWidth           => OpCodeBus
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_op_code_a,
            data_out            => reg_op_code_a
            );

    VALID_REF_REG_A : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_valid_ref_a,
            data_out            => reg_valid_ref_a
            );

    INSTR_DATA_REG_A    : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth * DataWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_instr_data_a,
            data_out            => reg_instr_data_a
            );

---------------------------------------------------------   

    
    OPCODE_REG_B        : entity work.Reg
        generic map(
            DataWidth           => OpCodeBus
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_op_code_b,
            data_out            => reg_op_code_b
            );

    VALID_REF_REG_B : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_valid_ref_b,
            data_out            => reg_valid_ref_b
            );

    INSTR_DATA_REG_B    : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth * DataWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_instr_data_b,
            data_out            => reg_instr_data_b
            );

-----------------------------------------------------------
    
    OPCODE_REG_C        : entity work.Reg
        generic map(
            DataWidth           => OpCodeBus
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_op_code_c,
            data_out            => reg_op_code_c
            );

    VALID_REF_REG_C : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_valid_ref_c,
            data_out            => reg_valid_ref_c
            );

    INSTR_DATA_REG_C    : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth * DataWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_instr_data_c,
            data_out            => reg_instr_data_c
            );
 
--------------------------------------------------------
    
    OPCODE_REG_START   : entity work.Reg
        generic map(
            DataWidth           => OpCodeBus
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_op_code_start,
            data_out            => reg_op_code_start
            );

    VALID_REF_REG_START : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_valid_ref_start,
            data_out            => reg_valid_ref_start
            );

    INSTR_DATA_REG_START    : entity work.Reg
        generic map(
            DataWidth           => ClusterWidth * DataWidth
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data_in             => fd_instr_data_start,
            data_out            => reg_instr_data_start
            );

-----------------------------------------------------------

    FD_MUX_OPCODE           : entity work.Mux4In
        generic map(
            DataWidth           => OpCodeBus,
            SelWidth            => FDSel
            )
        port map(
            data_in_1           => reg_op_code_a,
            data_in_2           => reg_op_code_b,
            data_in_3           => reg_op_code_c,
            data_in_4           => reg_op_code_start,
            sel                 => cp_sel_fd,
            data_out            => mux_opcode

            );

    FD_MUX_VAL_REF          : entity work.Mux4In
        generic map(
            DataWidth           => ClusterWidth,
            SelWidth            => FDSel
            )
        port map(
            data_in_1           =>reg_valid_ref_a,
            data_in_2           =>reg_valid_ref_b,
            data_in_3           =>reg_valid_ref_c,
            data_in_4           =>reg_valid_ref_start,
            sel                 =>cp_sel_fd,
            data_out            =>mux_valid_ref

            );

    FD_MUX_INS_DATA             : entity work.Mux4In
        generic map(
            DataWidth           => ClusterWidth * DataWidth,
            SelWidth            => FDSel
            )
        port map(
            data_in_1           =>reg_instr_data_a,
            data_in_2           =>reg_instr_data_b,
            data_in_3           =>reg_instr_data_c,
            data_in_4           =>reg_instr_data_start,
            sel                 =>cp_sel_fd,
            data_out            =>mux_instr_data

            );

    FD_MUX_INS_ADDR             : entity work.Mux4In
        generic map(
            DataWidth           => AddressWidthInstr,
            SelWidth            => FDSel
            )
        port map(
            data_in_1           =>reg_addr_instruction_1_i,
            data_in_2           =>reg_addr_instruction_2_i,
            data_in_3           =>reg_addr_instruction_3_i,
            data_in_4           =>reg_addr_instr_start_i,
            sel                 =>cp_sel_fd,
            data_out            =>mux_addr_instr
            );
            
-----------------------------------------------------------

    EXECUTE         : entity work.Execute
        generic map(
            InternalOpBus       => InternalOpBus,
            ClusterWidth        => ClusterWidth,
            NCluster            => NCluster,
            DataWidth           => DataWidth,
            AddressWidthData    => AddressWidthData,
            BusWidthData        => BusWidthData
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            data                => data,
            data_offset         => ex_data_offset,
            reference           => mux_instr_data,
            match               => ex_match,
            valid_ref           => mux_valid_ref,
            operator            => mux_opcode(InternalOpBus - 1 downto 0),
            stall               => cp_stall,
            disable_comparators => cp_dis_comparators
            );

    CONTROL_PATH    : entity work.ControlPath
        generic map(
            AddrWidthInstr      => AddressWidthInstr,
            AddrWidthData       => AddressWidthData,
            OpBusWidth          => OpCodeBus,
            InternalOpBus       => InternalOpBus,
            CounterWidth        => CounterWidth,
            BufferAddressWidth  => BufferAddressWidth,
            StackDataWidth      => StackDataWidth,
            DataWidth           => DataWidth,
            ClusterWidth        => ClusterWidth,
            NCluster            => NCluster,
            CharacterNumber     => CharacterNumber,
            Debug               => Debug
            )
        port map(
            clk                 => clk,
            rst                 => rst,
            src_en              => src_en,
            addr_start_instr    => addr_start_instr,
            
            no_more_characters  => no_more_characters,


            debug_curr_state    => debug_curr_state,

            found               => found,
            complete            => complete,
            curr_character      => curr_character,
            curr_last_match_char=> curr_last_match_char,

            jumps_offset        => jumps_offset_i,
            speculation_flag    => speculation_flag_i,
            backtracking_flag   => backtracking_flag_i,
            minimum_cntr_flag   => minimum_cntr_flag_i,
            maximum_cntr_flag   => maximum_cntr_flag_i,
            lazy_flag           => lazy_flag_i,

            addr_instruction_1  => addr_instruction_1_i,
            addr_instruction_2  => addr_instruction_2_i,
            addr_instruction_3  => addr_instruction_3_i,

            addr_data_1         => addr_data_1,
            addr_data_2         => addr_data_2,
            curr_instr_addr     => mux_addr_instr,
            sel_data            => sel_data,
            sel_fd              => cp_sel_fd,
            op_code             => mux_opcode,
            match               => ex_match,
            data_offset         => ex_data_offset,
            stall               => cp_stall,
            disable_comparators => cp_dis_comparators
            );

        Offset : process(mux_opcode(op_opar), mux_instr_data)
        begin
            if mux_opcode(op_opar) = '1' then
                jumps_offset_i         <= mux_instr_data;
            else
                jumps_offset_i         <= (others => '0');
            end if ;
            
        end process ; -- Offset

        call_flags : process( mux_opcode(op_opar), mux_instr_data)
        begin
            if mux_opcode(op_opar) = '1' then
                minimum_cntr_flag_i    <= mux_instr_data(ClusterWidth * DataWidth - 1);
                maximum_cntr_flag_i    <= mux_instr_data(ClusterWidth * DataWidth - 2);
                backtracking_flag_i    <= mux_instr_data(ClusterWidth * DataWidth - 3);
                speculation_flag_i     <= mux_instr_data(ClusterWidth * DataWidth - 4);
                lazy_flag_i            <= mux_instr_data(ClusterWidth * DataWidth - 5); 
            else
                speculation_flag_i     <= '0';
                backtracking_flag_i    <= '0';
                minimum_cntr_flag_i    <= '0';
                maximum_cntr_flag_i    <= '0';
                lazy_flag_i            <= '0';
            end if ;
        end process ;
        
        start_addr_update : process( addr_start_instr, addr_instruction_1_i, fd_instr_data_a, fd_valid_ref_a, fd_op_code_a)
        begin
            if addr_start_instr = addr_instruction_1_i then
                fd_op_code_start         <= fd_op_code_a;
                fd_instr_data_start      <= fd_instr_data_a;
                fd_valid_ref_start       <= fd_valid_ref_a;
                addr_instr_start_i       <= addr_instruction_1_i;
            else
                fd_op_code_start         <= fd_op_code_start;
                fd_instr_data_start      <= fd_instr_data_start;
                fd_valid_ref_start       <= fd_valid_ref_start;
                addr_instr_start_i       <= addr_instr_start_i;
            end if ;
        end process ;

        addr_instruction_1 <= addr_instruction_1_i;
        addr_instruction_2 <= addr_instruction_2_i;
        addr_instruction_3 <= addr_instruction_3_i;

hw_debug_generate: if Debug generate
        debug_curr_opc <= mux_opcode;
        debug_curr_ref <= mux_instr_data;
end generate; --hw_debug_generate

end behav;
