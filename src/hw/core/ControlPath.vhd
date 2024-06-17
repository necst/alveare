library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.opcodePack.all;
use work.stackPack.all;

entity ControlPath is
    generic(

        AddrWidthInstr      : positive := 6;
        AddrWidthData       : positive := 6;
        OpBusWidth          : positive := 11;
        ClusterWidth        : positive := 4;
        InternalOpBus       : positive := 2;
        CounterWidth        : positive := 1;
        CharacterNumber     : positive := 11;

        -- StackDataWidth    : width of each element of the buffer contained in the stack
        StackDataWidth      : positive := 23;
        -- BufferAddressWidth: with of the address space of the buffer inside of
        -- the stack (2^BufferAddressWidth is the number of the elements in the stack)
        BufferAddressWidth  : positive := 6;
        DataWidth           : positive := 8;
        NCluster            : positive := 4;
        Debug               : boolean  := false
        );
    port(
        -- External signal

        clk                 : in std_logic;
        -- reset active low
        rst                 : in std_logic;
        --enable the search of the reg exp
        src_en              : in std_logic;
        --the address starting point of the instruction
        addr_start_instr    : in std_logic_vector(AddrWidthInstr - 1 downto 0); 
        -- 
        --
        -- 1 if a match is found
        found               : out std_logic;
        --end of search, if also found is high a match is found
        complete            : out std_logic;
        -- Control signal
        
        no_more_characters  : in std_logic;
        curr_character      : out std_logic_vector(CharacterNumber - 1 downto 0);
        curr_last_match_char: out std_logic_vector(CharacterNumber - 1 downto 0);
        --input offset signal coming from the FD stage whenever a jump is the current instruction
        jumps_offset        : in std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
        -- input  signal that comes whenever a open parenthesis to understand which kind of computation we expect
        speculation_flag    : in std_logic;
        backtracking_flag   : in std_logic;
		minimum_cntr_flag   : in std_logic;
        maximum_cntr_flag   : in std_logic;
        lazy_flag           : in std_logic;

        -- address of the first instruction in the instruction memory
        addr_instruction_1  : out std_logic_vector(AddrWidthInstr - 1 downto 0);
        -- address of the second instruction in the instruction memory
        addr_instruction_2  : out std_logic_vector(AddrWidthInstr - 1 downto 0);
        --address of special instruction in order to avoid loss of clock cycles
        addr_instruction_3  : out std_logic_vector(AddrWidthInstr - 1 downto 0);
        -- address of the data in the buffer data memory
        addr_data_1         : out std_logic_vector(AddrWidthData - 1 downto 0);
        addr_data_2         : out std_logic_vector(AddrWidthData - 1 downto 0);

        curr_instr_addr	 	: in std_logic_vector(AddrWidthInstr - 1 downto 0);

        sel_data            : out std_logic_vector(2 downto 0);
        -- 1 is to stop the execute stage
        stall               : out std_logic;
        -- "00" stands for the FD_A "01" for the FD_B, "10" for the FD_C, "11" for the start addr
        sel_fd              : out std_logic_vector(1 downto 0);
        -- Internal signal

        debug_curr_state    : out std_logic_vector(6 downto 0);

        --op code from fd stage
        op_code             : in std_logic_vector(OpBusWidth - 1 downto 0);
        --a match is found in the current execution stage
        match               : in std_logic;
        -- offset for the new data address
        data_offset         : in std_logic_vector(AddrWidthData - 1 downto 0);

        disable_comparators : out std_logic_vector(1 downto 0)
        );
end ControlPath;

architecture behav of ControlPath is

    
    ---Internal signals

    -- accumulator of the matching, needed to spot a match in nop stage
    signal match_acc                		: std_logic;
    signal match_acc_next           		: std_logic;
    -- address of when the match is started
    signal last_match               		: std_logic_vector(AddrWidthData - 1 downto 0);
    signal last_match_next          		: std_logic_vector(AddrWidthData - 1 downto 0);

----------------                      Stack related signals         --------------------------
    signal rst_stack_ctr            		: std_logic;
    signal stack_push               		: std_logic;
    signal stack_push_next          		: std_logic;
    signal stack_din                		: std_logic_vector(StackDataWidth - 1 downto 0);
    signal stack_dout               		: std_logic_vector(StackDataWidth - 1 downto 0);
    signal stack_empty              		: std_logic;
    signal stack_full               		: std_logic;
    signal stack_pop                		: std_logic;
    signal stack_pop_next           		: std_logic;
    --status 
    signal stack_curr_character_in       	: std_logic_vector(CharacterNumber - 1 downto 0);
    signal stack_curr_character_in_next 	: std_logic_vector(CharacterNumber - 1 downto 0);
    signal stack_curr_character_out      	: std_logic_vector(CharacterNumber - 1 downto 0);
    signal stack_addr_backtracking_in       : std_logic_vector(AddrWidthInstr - 1 downto 0);
    signal stack_addr_backtracking_in_next	: std_logic_vector(AddrWidthInstr - 1 downto 0);
    signal stack_addr_backtracking_out   	: std_logic_vector(AddrWidthInstr - 1 downto 0);
    signal stack_state_match_in          	: std_logic;
    signal stack_state_match_in_next     	: std_logic;
    signal stack_state_match_out         	: std_logic;
    signal stack_match_acc_in            	: std_logic_vector(BufferAddressWidth + 1 - 1 downto 0);
    signal stack_match_acc_in_next       	: std_logic_vector(BufferAddressWidth + 1 - 1 downto 0);
    signal stack_match_acc_out           	: std_logic_vector(BufferAddressWidth + 1 - 1 downto 0);
    signal stack_min_max_in              	: std_logic_vector(BufferAddressWidth*2 - 1 downto 0);
    signal stack_min_max_in_next         	: std_logic_vector(BufferAddressWidth*2 - 1 downto 0);
    signal stack_min_max_out             	: std_logic_vector(BufferAddressWidth*2 - 1 downto 0);
    signal stack_last_match_in           	: std_logic_vector(AddrWidthData - 1 downto 0);
    signal stack_last_match_in_next      	: std_logic_vector(AddrWidthData - 1 downto 0);
    signal stack_last_match_out          	: std_logic_vector(AddrWidthData - 1 downto 0);
    signal stack_c_l_match_char_in       	: std_logic_vector(CharacterNumber - 1 downto 0);
    signal stack_c_l_match_char_in_next  	: std_logic_vector(CharacterNumber - 1 downto 0);
    signal stack_c_l_match_char_out      	: std_logic_vector(CharacterNumber - 1 downto 0); 
    signal stack_addr_data_in            	: std_logic_vector(AddrWidthData - 1 downto 0);
    signal stack_addr_data_in_next       	: std_logic_vector(AddrWidthData - 1 downto 0);
    signal stack_addr_data_out           	: std_logic_vector(AddrWidthData - 1 downto 0);

    --FSM related signals
    type STATE_TYPE is (RESET, NOP, FD, EX_NM, EX_M, RECOVER_0, RECOVER_1, RECOVER_2, RECOVER_3, COUNTER_CHECK, LAZY_0, LAZY_1, STL_BRAM);
    signal state 							: STATE_TYPE;
    signal state_next_i             		: STATE_TYPE;

    -- "00" stands for the FD_A "01" for the FD_B, "10" for the FD_C, "11" for the start addr
    signal sel_fd_i                  		: std_logic_vector(1 downto 0);
    signal sel_fd_next_i             		: std_logic_vector(1 downto 0);

    signal sel_data_i                		: std_logic_vector(2 downto 0);
    signal sel_data_next_i           		: std_logic_vector(2 downto 0);
    --I/O signals
    -- address of the next data
    signal ram_addr                  		: std_logic_vector(AddrWidthData - 1 downto 0);
    signal ram_addr_next             		: std_logic_vector(AddrWidthData - 1 downto 0);
    -- address of the special instruction
    signal addr_instruction_1_i      		: std_logic_vector(AddrWidthInstr - 1 downto 0);
    -- addres of the current matching instruction
    signal addr_instruction_2_i      		: std_logic_vector(AddrWidthInstr - 1 downto 0);
    -- address of the special instruction
    signal addr_instruction_3_i      		: std_logic_vector(AddrWidthInstr - 1 downto 0);
    -- address of the special instruction
    signal addr_instruction_1_i_next 		: std_logic_vector(AddrWidthInstr - 1 downto 0);
    -- address of the current matching instruction
    signal addr_instruction_2_i_next 		: std_logic_vector(AddrWidthInstr - 1 downto 0);
    -- address of the special instruction
    signal addr_instruction_3_i_next 		: std_logic_vector(AddrWidthInstr - 1 downto 0);
    -- internal signal for the complete
    signal complete_i                		: std_logic;
    signal complete_next_i           		: std_logic;
    -- internal signal for the found
    signal found_i                      	: std_logic;
    signal found_next_i           	    	: std_logic;
    -- internal signal for the stall, needed to be sequential the stall
    signal stall_i                   		: std_logic;
    signal stall_i_next                		: std_logic;
    --buondaries for counter op
    signal min_bound               			: std_logic_vector(BufferAddressWidth - 1 downto 0);
    signal min_bound_next            		: std_logic_vector(BufferAddressWidth - 1 downto 0);
    signal max_bound                 		: std_logic_vector(BufferAddressWidth - 1 downto 0);
    signal max_bound_next            		: std_logic_vector(BufferAddressWidth - 1 downto 0);
    signal infinite_bound            		: std_logic;

    -- Already defined in stackDefpack, but needed in order to have customizable IP
    constant counterMSB             		: natural := StackDataWidth - 1;
    constant counterLSB             		: natural := StackDataWidth - CounterWidth;
    constant op_codeMSB             		: natural := counterLSB - 1;
    constant op_codeLSB             		: natural := counterLSB - OpBusWidth;
    constant matchAccum             		: natural := op_codeLSB - 1;
    constant specialaddrMSB         		: natural := matchAccum - 1;
    constant specialaddrLSB         		: natural := matchAccum - AddrWidthInstr;
    constant contextaddrMSB         		: natural := specialaddrLSB - 1;
    constant contextaddrLSB         		: natural := specialaddrLSB - AddrWidthData;
    constant char_padding               	: std_logic_vector(CharacterNumber - AddrWidthData - 1 downto 0) := (others => '0');
    constant match_counter_padding          : std_logic_vector(BufferAddressWidth - 1 downto 0) := (others => '0');

    signal match_counter            		: std_logic_vector(BufferAddressWidth - 1 downto 0);
    signal match_counter_next       		: std_logic_vector(BufferAddressWidth - 1 downto 0);
    -- if 0 the counter is reset
    signal rst_match_counter            	: std_logic;
    signal rst_match_counter_next       	: std_logic;
    signal jumps_offset_next_i      		: std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal jumps_offset_i           		: std_logic_vector(ClusterWidth * DataWidth - 1 downto 0);
    signal stack_data_addr          		: std_logic_vector (AddrWidthData - 1 downto 0);
        --this two have to be removed with the move of start case of open par
    signal last_data_match          		: std_logic_vector (AddrWidthData - 1 downto 0);
    signal last_previous_match      		: std_logic_vector (AddrWidthData - 1 downto 0);
    signal restart_data_addr        		: std_logic_vector (AddrWidthData - 1 downto 0);
    signal curr_character_i         		: std_logic_vector(CharacterNumber - 1 downto 0);
    signal curr_character_next_i    		: std_logic_vector(CharacterNumber - 1 downto 0); 

    signal disable_comparators_i         	: std_logic_vector(1 downto 0);
    signal en_comp_ctrl                  	: std_logic;
    signal en_comp_ctrl_next             	: std_logic;
    signal recovered                     	: std_logic;
    signal recovered_next                	: std_logic;

    signal curr_last_match_char_i        	: std_logic_vector(CharacterNumber - 1 downto 0);
    signal curr_last_match_char_next_i   	: std_logic_vector(CharacterNumber - 1 downto 0);

begin


    STACK_BUFFER : entity work.Stack
        generic map(
            AddrWidthInstr      	    => AddrWidthInstr,
            AddrWidthData     		    => AddrWidthData,
            CharacterNumber     		=> CharacterNumber,
            MinMaxWidth                 => BufferAddressWidth,
            -- BufferAddressWidth: with of the address space of the buffer inside of
            -- the stack (2^BufferAddressWidth is the number of the elements in the stack)
            BufferAddressWidth  		=> BufferAddressWidth
        )
        port map (
            clk                         => clk,
            rst                         => rst_stack_ctr,
            push                        => stack_push,
            pop                         => stack_pop,
            empty                       => stack_empty,
            full                        => stack_full,
            curr_character_in           => stack_curr_character_in,
            curr_character_out          => stack_curr_character_out,
            addr_instr_backtracking_in  => stack_addr_backtracking_in,
            addr_instr_backtracking_out => stack_addr_backtracking_out,
            state_match_in              => stack_state_match_in,
            state_match_out             => stack_state_match_out,
            match_acc_in                => stack_match_acc_in,
            match_acc_out               => stack_match_acc_out,
            min_max_in                  => stack_min_max_in,
            min_max_out                 => stack_min_max_out,
            last_match_in               => stack_last_match_in,
            last_match_out              => stack_last_match_out,
            curr_last_match_char_in     => stack_c_l_match_char_in,
            curr_last_match_char_out    => stack_c_l_match_char_out,
            addr_data_in                => stack_addr_data_in,
            addr_data_out               => stack_addr_data_out
        );

    synch_state  : process (clk, rst)
    begin
        if rising_edge(clk) then
            -- Synchronous reset active low
            if rst = '0' then
                state                    <= RESET;
            else
                state                    <= state_next_i;
            end if;
            -- status updating
            curr_character_i             <= curr_character_next_i;
            ram_addr                     <= ram_addr_next;
            addr_instruction_2_i         <= addr_instruction_2_i_next;            
            curr_last_match_char_i       <= curr_last_match_char_next_i;
            match_acc                    <= match_acc_next;
            sel_data_i                   <= sel_data_next_i;
            complete_i                   <= complete_next_i;
            last_match                   <= last_match_next;
            match_counter                <= match_counter_next;
            min_bound                    <= min_bound_next;
            max_bound                    <= max_bound_next;
            --------------------------actually not usefull in the state
            rst_match_counter            <= rst_match_counter_next;
            addr_instruction_3_i         <= addr_instruction_3_i_next;
            addr_instruction_1_i         <= addr_instruction_1_i_next;
            en_comp_ctrl                 <= en_comp_ctrl_next;
            sel_fd_i                     <= sel_fd_next_i;
            --stack command
            stack_pop                    <= stack_pop_next;
            stack_push                   <= stack_push_next;
            --stack register updating
            stack_curr_character_in      <= stack_curr_character_in_next;
            stack_addr_backtracking_in   <= stack_addr_backtracking_in_next;
            stack_state_match_in         <= stack_state_match_in_next;
            stack_match_acc_in           <= stack_match_acc_in_next;
            stack_min_max_in             <= stack_min_max_in_next;
            stack_last_match_in          <= stack_last_match_in_next;
            stack_c_l_match_char_in      <= stack_c_l_match_char_in_next;
            stack_addr_data_in           <= stack_addr_data_in_next;
            recovered                    <= recovered_next;
            found_i                      <= found_next_i;
            stall_i                      <= stall_i_next;
    end if;

    end process;

    -- Register and FSM
    combinatory_FSM_proc : process(state, lazy_flag, rst_match_counter, infinite_bound, minimum_cntr_flag, min_bound, max_bound, curr_instr_addr, match_counter, stack_addr_data_out, stack_c_l_match_char_out, stack_last_match_out, stack_min_max_out, stack_match_acc_out, stack_state_match_out, stack_addr_backtracking_out, stack_curr_character_out, stack_addr_data_in, stack_c_l_match_char_in, stack_last_match_in, stack_min_max_in, stack_curr_character_in, stack_match_acc_in, stack_addr_backtracking_in_next, stack_state_match_in, jumps_offset, restart_data_addr, match_acc, data_offset, addr_start_instr, src_en, complete_i, curr_character_i, match, op_code, ram_addr, addr_instruction_1_i, addr_instruction_2_i, addr_instruction_3_i, sel_data_i, sel_fd_i, last_match, curr_last_match_char_i, stack_addr_backtracking_in, recovered, no_more_characters, speculation_flag, backtracking_flag, maximum_cntr_flag, stall_i, stack_empty, found_i)
    begin
        rst_stack_ctr                   <= '1';
        state_next_i                    <= state;
        sel_data_next_i                 <= sel_data_i;
        sel_fd_next_i                   <= sel_fd_i;
        -- fetch data
        ram_addr_next                   <= ram_addr;
        --reset address
        last_match_next                 <= last_match;----;
        curr_character_next_i           <= curr_character_i;
        curr_last_match_char_next_i     <= curr_last_match_char_i;
        addr_instruction_1_i_next       <= addr_instruction_1_i;
        addr_instruction_2_i_next       <= addr_instruction_2_i;
        addr_instruction_3_i_next       <= addr_instruction_3_i;
        match_acc_next                  <= match_acc;
        complete_next_i                 <= complete_i;
        match_counter_next              <= match_counter;
        min_bound_next 				    <= min_bound;
        max_bound_next 				    <= max_bound;
        rst_match_counter_next          <= '0';
        --
        stack_push_next                 <= '0';
        stack_pop_next                  <= '0';
        --
        stack_curr_character_in_next    <= stack_curr_character_in;
        stack_addr_backtracking_in_next <= stack_addr_backtracking_in;
        stack_state_match_in_next       <= stack_state_match_in;
        stack_match_acc_in_next         <= stack_match_acc_in;
        stack_min_max_in_next           <= stack_min_max_in;
        stack_last_match_in_next        <= stack_last_match_in;
        stack_c_l_match_char_in_next    <= stack_c_l_match_char_in;
        stack_addr_data_in_next         <= stack_addr_data_in;
        recovered_next                  <= recovered;
        found_next_i                    <= found_i;
        stall_i_next                    <= stall_i;

        -------------------- FSM sequentially active --------------------
        case( state ) is
        -------------------- Reset stage --------------------
            when RESET  =>
                state_next_i                 <= NOP;
                sel_data_next_i              <= (others => '0');
                sel_fd_next_i                <= (others => '0');
                match_acc_next               <= '0';
                complete_next_i              <= '0';
                stall_i_next                 <= '0';
                ram_addr_next                <= (others => '0');
                match_counter_next           <= (others => '0');
                rst_stack_ctr                <= '0';
                stack_din                    <= (others => '0');
                jumps_offset_next_i          <= (others => '0');
                curr_character_next_i        <= (others => '0');
                curr_last_match_char_next_i  <= (others => '0');
                recovered_next               <= '0';
                last_match_next 			 <= (others => '0');
                rst_match_counter_next       <= '0';
                --
                stack_push_next              <= '0';
                stack_pop_next               <= '0';
                --
                stack_curr_character_in_next     <= (others => '0');
                stack_addr_backtracking_in_next   <= (others => '0');
                stack_state_match_in_next    <= '0';
                stack_match_acc_in_next      <= (others => '0');
                stack_min_max_in_next        <= (others => '0');
                stack_last_match_in_next     <= (others => '0');
                stack_c_l_match_char_in_next <= (others => '0');
                stack_addr_data_in_next      <= (others => '0');
                addr_instruction_1_i_next    <= addr_start_instr;
                addr_instruction_2_i_next    <= addr_start_instr;
                addr_instruction_3_i_next    <= addr_start_instr;

            -------------------- NOP stage -------------------- 
            when NOP    =>
                found_next_i                   <= match_acc;
                if src_en = '1' and complete_i = '0' then 
                    state_next_i               <= FD;
                    -- fetch instructions
                    addr_instruction_2_i_next  <= addr_start_instr + 1;
                    addr_instruction_3_i_next  <= addr_start_instr + 2; 
                    --reset bram track
                end if ;

            -------------------- Fetch and Decode stage --------------------
            when FD     =>
                state_next_i        <= EX_NM;

            ------------ Execution stage, currently not matching-----------

            -- In execution: in the previous state there was no match
            when EX_NM  =>
                stall_i_next       <= '0';
                sel_data_next_i    <= (others => '0');
                sel_fd_next_i      <= "11";
                -- End of data need to exit
                if no_more_characters = '1' then
                    complete_next_i     <= '1';
                    match_acc_next      <= '0';
                    state_next_i        <= NOP;
                -- open parenthesis operator
                elsif op_code(op_opar) = '1' then
                -- start my reg exp with an open parenthesis
                    sel_fd_next_i                               <= "01";
                    match_acc_next                              <= '0';
                    if rst_match_counter = '0' then
                        match_counter_next 						<= (others => '0');
                    end if;
                    if lazy_flag = '1' and recovered = '1' then
                        match_counter_next 						<= match_counter;
                    end if;
                    --if i'm starting with a jump I have to prefetch the jumped instruction
                    addr_instruction_2_i_next                   <= addr_instruction_2_i + 1;
                    if speculation_flag = '1' then
                        addr_instruction_3_i_next               <= addr_start_instr + curr_instr_addr + jumps_offset(AddrWidthInstr - 1 downto 0);
                    else
                        addr_instruction_3_i_next               <= addr_instruction_2_i;
                    end if ;
                    jumps_offset_next_i                         <= jumps_offset;
                    --saving context in the stack
                    stack_curr_character_in_next    <= curr_character_i;
                    --non definitiva
                    state_next_i                                <= EX_NM;
                    if backtracking_flag = '1' then
                        stack_addr_backtracking_in_next     <= addr_start_instr + curr_instr_addr + jumps_offset(2*AddrWidthInstr - 1 downto AddrWidthInstr);                 
                        addr_instruction_1_i_next           <= addr_start_instr + curr_instr_addr + jumps_offset(2*AddrWidthInstr - 1 downto AddrWidthInstr);
                        stack_state_match_in_next           <= '0';
                        if minimum_cntr_flag = '1' then
                        	stack_min_max_in_next(BufferAddressWidth*2 - 1 downto BufferAddressWidth) <= jumps_offset(4*AddrWidthInstr - 1 downto AddrWidthInstr*3);
  							min_bound_next <= jumps_offset(4*AddrWidthInstr - 1 downto AddrWidthInstr*3);
  						end if;
  						if maximum_cntr_flag = '1' then
  							stack_min_max_in_next(BufferAddressWidth - 1 downto 0) <= jumps_offset(3*AddrWidthInstr - 1 downto AddrWidthInstr*2);
  							max_bound_next <= jumps_offset(3*AddrWidthInstr - 1 downto AddrWidthInstr*2);
                            if lazy_flag = '1' and jumps_offset(3*AddrWidthInstr - 1 downto AddrWidthInstr*2) = match_counter_padding then
                                addr_instruction_2_i_next         <= addr_start_instr + curr_instr_addr + jumps_offset(AddrWidthInstr - 1 downto 0);
                                state_next_i                      <= LAZY_0;
                            end if;
  						end if;
                        stack_match_acc_in_next         <= match_acc&match_counter;
                        stack_last_match_in_next        <= last_match;
                        stack_c_l_match_char_in_next    <= curr_last_match_char_i;
                        stack_addr_data_in_next         <= ram_addr;
                        stack_push_next                 <= '1';
                    else
                        addr_instruction_1_i_next       <= addr_start_instr;
                    end if;
                elsif stall_i = '0' then
                    if match = '1' then -- start the point of matching
                    -- Store the starting point of matching
                        last_match_next            <= ram_addr;
                        -- if the operator is )| execution will jump at the end of the or chain (saved in FD_C)
                        if op_code(op_cp_or) = '1' then
                            sel_fd_next_i              <= "10";
                            addr_instruction_2_i_next  <= addr_instruction_3_i + 1;
                        -- if the operator is ? lazy
                        elsif op_code(op_cp_count_l) = '1' and (match_counter + 1 < min_bound) then
                            sel_fd_next_i              <= "11";
                            addr_instruction_2_i_next  <= addr_instruction_1_i + 1;
                            match_counter_next         <= match_counter + 1;
                            rst_match_counter_next     <= '1';
                        -- greedy approach 
                        elsif op_code(op_cp_counter) = '1' and (match_counter + 1 < max_bound or infinite_bound = '1') then
                            sel_fd_next_i              <= "10";
                            addr_instruction_2_i_next  <= addr_instruction_3_i + 1;
                            match_counter_next         <= match_counter + 1;
                            rst_match_counter_next     <= '1';
                        else 
                        -- use the prefetcher
                            sel_fd_next_i              <= "01";
                            addr_instruction_2_i_next  <= addr_instruction_2_i + 1;
                        end if;

                        -- Fetch new instruction and data
                        ram_addr_next              <= ram_addr + data_offset;
                        sel_data_next_i            <= data_offset(2 downto 0);
                        match_acc_next             <= '1';
                        -- maintain active only the clusters that match
                        curr_character_next_i      <= curr_character_i + (char_padding & data_offset);
                        curr_last_match_char_next_i<= curr_character_i;                        
                        state_next_i <= EX_M;
                    else
                        match_acc_next               <= '0';
                        state_next_i                 <= EX_NM;
                        recovered_next               <= '0';
                    -- matching nothing
                        if op_code(op_cp_or) = '1' then
                            sel_fd_next_i                <= "01";
                            addr_instruction_2_i_next    <= addr_instruction_2_i + 1;
                            stack_pop_next               <= '1';
                            recovered_next               <= recovered;
                        elsif (op_code(op_cp_counter) = '1' or op_code(op_cp_count_l) = '1') and min_bound = 0 then
                            sel_fd_next_i                <= "01";
                            addr_instruction_2_i_next    <= addr_instruction_2_i + 1;
                            stack_pop_next               <= '1';
                            match_acc_next               <= '1';
                                                    -- Fetch new instruction and data
                            ram_addr_next              <= ram_addr + data_offset;
                            sel_data_next_i            <= data_offset(2 downto 0);
                            -- maintain active only the clusters that match
                            
                            curr_character_next_i      <= curr_character_i + (char_padding & data_offset);
                            curr_last_match_char_next_i<= curr_character_i;
                            state_next_i                 <= EX_M;                   
                        else
                            sel_data_next_i              <= data_offset(2 downto 0);
                            curr_character_next_i        <= curr_character_i + (char_padding & data_offset);
                            ram_addr_next                <= ram_addr + data_offset;
                            if (op_code(op_cp_counter) = '1' or op_code(op_cp_count_l) = '1') and min_bound > 0 then
                                stack_pop_next           <= '1';
                            elsif op_code(op_cp) = '1' and recovered = '1' then
                               curr_character_next_i    <= curr_character_i + 1;
                               sel_data_next_i          <= "001";
                               ram_addr_next            <= ram_addr + 1;
                            end if;
                        -- use the prefetcher
                            sel_fd_next_i                <= "11";
                            addr_instruction_2_i_next    <= addr_start_instr;
                            addr_instruction_2_i_next    <= addr_start_instr + 1;
                            addr_instruction_3_i_next    <= addr_start_instr + 2;
                        end if;
                    end if;
                end if;

            ------------ Execution stage, currently matching-----------

            -- Execution and in the previous state a match was found
            when EX_M   =>
                sel_data_next_i     <= (others => '0');
                sel_fd_next_i       <= "11";
                recovered_next      <= '0';
                        -- End of data need to exit
                if op_code(op_nop) = '1' then
                    complete_next_i     <= '1';
                    state_next_i        <= NOP;
                                    -- open parenthesis operator
                elsif no_more_characters = '1' then
                    complete_next_i     <= '1';
                    match_acc_next      <= '0';
                    state_next_i        <= NOP;
                -- end of the valid instructions/reg exp
                elsif op_code(op_opar) = '1' then
                    if rst_match_counter = '0' then
                        match_counter_next 						<= (others => '0');
                    end if;
                    if lazy_flag = '1' and recovered = '1' then
                        match_counter_next 						<= match_counter;
                    end if;
                -- start my reg exp with an open parenthesis
                    sel_fd_next_i                               <= "01";
                    --if i'm starting with a jump I have to prefetch the jumped instruction
                    addr_instruction_2_i_next                   <= addr_instruction_2_i + 1;
                    if speculation_flag = '1' then
                        addr_instruction_3_i_next               <= addr_start_instr + curr_instr_addr + jumps_offset(AddrWidthInstr - 1 downto 0);
                    else
                        addr_instruction_3_i_next               <= addr_instruction_2_i;
                    end if ;
                    jumps_offset_next_i                         <= jumps_offset;
                    stack_curr_character_in_next           <= curr_character_i;
                    state_next_i                           <= EX_M;
                    if backtracking_flag = '1' then
                        stack_addr_backtracking_in_next    <= addr_start_instr + curr_instr_addr + jumps_offset(2*AddrWidthInstr - 1 downto AddrWidthInstr);
                        addr_instruction_1_i_next          <= addr_start_instr + curr_instr_addr + jumps_offset(2*AddrWidthInstr - 1 downto AddrWidthInstr);
                        stack_state_match_in_next          <= '1';
                        stack_match_acc_in_next            <= match_acc&match_counter;
                        if minimum_cntr_flag = '1' then
                        	stack_min_max_in_next(BufferAddressWidth*2 - 1 downto BufferAddressWidth) <= jumps_offset(4*AddrWidthInstr - 1 downto AddrWidthInstr*3);
  						end if;
  						if maximum_cntr_flag = '1' then
  							stack_min_max_in_next(BufferAddressWidth - 1 downto 0) <= jumps_offset(3*AddrWidthInstr - 1 downto AddrWidthInstr*2);
                            if lazy_flag = '1' and jumps_offset(3*AddrWidthInstr - 1 downto AddrWidthInstr*2) = match_counter_padding then
                                addr_instruction_2_i_next         <= addr_start_instr + curr_instr_addr + jumps_offset(AddrWidthInstr - 1 downto 0);
                                state_next_i                      <= LAZY_0;
                            end if;
                        end if;
                        if rst_match_counter = '0' then
                            stack_match_acc_in_next         <= match_acc&match_counter_padding;
                        else
                            stack_match_acc_in_next         <= match_acc&match_counter;
                        end if;
                        
                        stack_last_match_in_next        <= last_match;
                        stack_c_l_match_char_in_next    <= curr_last_match_char_i;
                        stack_addr_data_in_next         <= ram_addr;
                        stack_push_next                 <= '1';
                    else
                        addr_instruction_1_i_next       <= addr_start_instr;
                    end if;             
                elsif match = '1' then
                    if op_code(op_cp_or) = '1' then
                        sel_fd_next_i              <= "10";
                        addr_instruction_2_i_next  <= addr_instruction_3_i + 1;
                    elsif op_code(op_cp_count_l) = '1' and (match_counter + 1 < min_bound) then
                        sel_fd_next_i              <= "11";
                        addr_instruction_2_i_next  <= addr_instruction_1_i + 1;
                        match_counter_next         <= match_counter + 1;
                        rst_match_counter_next     <= '1';
                   elsif op_code(op_cp_counter) = '1' and (match_counter + 1 < max_bound or infinite_bound = '1') then
                        sel_fd_next_i              <= "10";
                        addr_instruction_2_i_next  <= addr_instruction_3_i + 1;
                        match_counter_next         <= match_counter + 1;
                        rst_match_counter_next     <= '1';
                    else 
                        -- use the prefetcher
                        sel_fd_next_i              <= "01";
                        addr_instruction_2_i_next  <= addr_instruction_2_i + 1;
                    end if;
                    match_acc_next             <= '1';
                    ram_addr_next              <= ram_addr + data_offset;
                    curr_character_next_i      <= curr_character_i + (char_padding & data_offset);
                    sel_data_next_i            <= data_offset(2 downto 0);
                    state_next_i               <= EX_M;

                else -- not matching rollback
                    if op_code(op_cp_or) = '1' then
                        sel_fd_next_i              <= "01";
                        addr_instruction_2_i_next  <= addr_instruction_2_i + 1;
                        stack_pop_next             <= '1';
                    elsif (op_code(op_cp_counter) = '1' or op_code(op_cp_count_l) = '1') and min_bound <= match_counter then
                        sel_fd_next_i              <= "01";
                        addr_instruction_2_i_next  <= addr_instruction_2_i + 1;
                        stack_pop_next             <= '1';
                        match_counter_next         <= (others => '0');
                    else 
                         -- use the prefetcher
                        sel_fd_next_i              <= "11";
                        ram_addr_next              <= restart_data_addr;                                    
                        --addr_instruction_2_i_next  <= addr_instruction_2_i + 1;
                        curr_character_next_i      <= curr_last_match_char_i + 1;
                        sel_data_next_i            <= "101";
                        addr_instruction_2_i_next  <= addr_start_instr + 1;
                        if op_code(op_cp_counter) = '1' or op_code(op_cp_count_l) = '1' then
                            state_next_i               <= COUNTER_CHECK;
                            stack_pop_next             <= '1';
                        elsif stack_empty = '1' then                                                
                            state_next_i               <= EX_NM;
                        else
                            stack_pop_next             <= '1';
                            state_next_i               <= RECOVER_0;
                        end if;
                        match_acc_next             <= '0';
                    end if;
                end if;
            when COUNTER_CHECK =>
                if stack_empty = '1' then                                                
                    state_next_i               <= EX_NM;
                else
                    stack_pop_next             <= '1';
                    state_next_i               <= RECOVER_0;
                end if;
            when LAZY_0 =>
                addr_instruction_2_i_next      <= addr_instruction_2_i + 1;
                state_next_i                   <= LAZY_1;
            when LAZY_1 =>
                sel_fd_next_i                  <= "01";
                state_next_i                   <= EX_M;
            when RECOVER_0 =>
                state_next_i                   <= RECOVER_1;
            when RECOVER_1 =>
                state_next_i                   <= RECOVER_2;
            when RECOVER_2 =>
                curr_character_next_i          <= stack_curr_character_out;
                ram_addr_next                  <= stack_addr_data_out;
                sel_data_next_i                <= "000";
                match_acc_next                 <= stack_match_acc_out(BufferAddressWidth + 1 - 1);
                match_counter_next             <= stack_match_acc_out(BufferAddressWidth - 1 downto 0);
                min_bound_next				   <= stack_min_max_out(BufferAddressWidth*2 - 1 downto BufferAddressWidth);
                max_bound_next				   <= stack_min_max_out(BufferAddressWidth - 1 downto 0);
                last_match_next                <= stack_last_match_out;
                curr_last_match_char_next_i    <= stack_c_l_match_char_out;
                sel_fd_next_i                  <= "01";
                state_next_i                   <= RECOVER_3;
                -- il massimo non dovrebbe essere controllato, dovrebbe essere già controllato
                if stack_min_max_out(BufferAddressWidth*2 - 1 downto BufferAddressWidth) > stack_match_acc_out(BufferAddressWidth - 1 downto 0) or
                    stack_min_max_out(BufferAddressWidth downto 0) <= stack_match_acc_out(BufferAddressWidth - 1 downto 0) then 
                    if stack_empty = '1' then
                        addr_instruction_1_i_next      <= addr_start_instr;
                        addr_instruction_2_i_next      <= addr_start_instr;
                        addr_instruction_3_i_next      <= addr_start_instr + 1;
                        ram_addr_next                  <= stack_addr_data_out + 1;
                        curr_character_next_i          <= stack_curr_character_out + 1;
                    else
                        stack_pop_next                 <= '1';
                        state_next_i                   <= RECOVER_0;
                    end if;
                else
                    addr_instruction_2_i_next      <= stack_addr_backtracking_out;
                end if;
            when RECOVER_3 =>
                recovered_next                 <= '1';
                addr_instruction_2_i_next  <= addr_instruction_2_i + 1;
                if stack_state_match_out = '1' then
                    state_next_i               <= EX_M;
                else
                    state_next_i               <= EX_NM;
                end if;   
            ------------ Failure state-----------
            -- Something goes wrong
            when others =>
                state_next_i        <= RESET;
        end case;
    end process;

    infinite_bound        <= '1' when (max_bound = std_logic_vector(to_unsigned(2**BufferAddressWidth -1, BufferAddressWidth))) else '0';
    sel_data              <= sel_data_i;
    curr_last_match_char  <= curr_last_match_char_i;
    curr_character        <= curr_character_i;
    sel_fd                <= sel_fd_i;
    stall                 <= stall_i;
    complete              <= complete_i;
    found                 <= found_i;
    addr_data_1           <= ram_addr;
    addr_data_2           <= last_match + 1;
    found                 <= found_i;
    addr_instruction_1    <= addr_instruction_1_i;
    addr_instruction_2    <= addr_instruction_2_i;
    addr_instruction_3    <= addr_instruction_3_i;

    compute_data_address : process(data_offset, last_match, stack_dout )
    begin
        stack_data_addr     <= stack_dout(contextAddrMSB downto contextAddrLSB);
        --this two have to be removed with the move of start case of open par
        last_data_match     <= last_match + data_offset;
        restart_data_addr   <= last_match + 1;

    end process ; -- compute_data_address

    enable_comparators : process (state, en_comp_ctrl)
    begin
        case (state) is
            when EX_NM  =>
                disable_comparators     <= "10";
                en_comp_ctrl_next       <= '0';
            when EX_M   =>
                if en_comp_ctrl = '0' then
                    en_comp_ctrl_next   <= '1';
                    disable_comparators <= "01";
                else
                    en_comp_ctrl_next   <= en_comp_ctrl;
                    disable_comparators <= "00";
                end if;
            when NOP =>
                disable_comparators 	<= "11";
                en_comp_ctrl_next   	<= '0';
            when FD =>
                disable_comparators 	<= "11";
                en_comp_ctrl_next   	<= '0';
            when others =>
                en_comp_ctrl_next   	<= en_comp_ctrl;
                disable_comparators 	<= "00";
        end case;
    end process;
hw_debug_generate: if Debug generate


    debug_curr_state <= std_logic_vector(to_unsigned(STATE_TYPE'POS(state),7));
end generate; --hw_debug_generate

end behav;
