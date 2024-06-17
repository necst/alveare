library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity Stack is
    generic(
        AddrWidthInstr      : positive := 6;
        AddrWidthData       : positive := 6;
        CharacterNumber     : positive := 11;
        MinMaxWidth         : positive := 4;
        -- BufferAddressWidth: with of the address space of the buffer inside of
        -- the stack (2^BufferAddressWidth is the number of the elements in the stack)
        BufferAddressWidth  : positive := 6
        );
    port(
        clk                        : in std_logic;
        rst                        : in std_logic;
        push                       : in std_logic;
        pop                        : in std_logic;
        empty                      : out std_logic;
        full                       : out std_logic;
        curr_character_in          : in std_logic_vector(CharacterNumber - 1 downto 0);
        curr_character_out         : out std_logic_vector(CharacterNumber - 1 downto 0);
        addr_instr_backtracking_in : in std_logic_vector(AddrWidthInstr - 1 downto 0);
        addr_instr_backtracking_out: out std_logic_vector(AddrWidthInstr - 1 downto 0);
        state_match_in             : in std_logic;
        state_match_out            : out std_logic;
        match_acc_in               : in std_logic_vector(BufferAddressWidth + 1 - 1 downto 0);
        match_acc_out              : out std_logic_vector(BufferAddressWidth + 1 - 1 downto 0);
         -- 2 means min and max signals, embedded in one signal for simplicity
        min_max_in                 : in std_logic_vector(MinMaxWidth*2 - 1 downto 0);
         -- 2 means min and max signals, embedded in one signal for simplicity
        min_max_out                : out std_logic_vector(MinMaxWidth*2 - 1 downto 0);
        last_match_in              : in std_logic_vector(AddrWidthData - 1 downto 0);
        last_match_out             : out std_logic_vector(AddrWidthData - 1 downto 0);
        curr_last_match_char_in    : in std_logic_vector(CharacterNumber - 1 downto 0);
        curr_last_match_char_out   : out std_logic_vector(CharacterNumber - 1 downto 0); 
        addr_data_in               : in std_logic_vector(AddrWidthData - 1 downto 0);
        addr_data_out              : out std_logic_vector(AddrWidthData - 1 downto 0)
        );
end Stack;

architecture Behavioral of Stack is

  -- pointer to the top of the stack
  signal current_pointer   : std_logic_vector (BufferAddressWidth-1 downto 0);
  signal en_i              : std_logic;
  signal state_match_in_i  : std_logic_vector(0 downto 0);
  signal state_match_out_i : std_logic_vector(0 downto 0);
  signal full_i            : std_logic;
  signal empty_i           : std_logic;
begin
    en_i                <= '1';--push or pop;
    state_match_out     <= state_match_out_i(0);
    state_match_in_i(0) <= state_match_in;
    BRAM1 : entity work.bram_single_port
    generic map(
        DataWidth => CharacterNumber,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer,
     data_in   =>  curr_character_in,
     data_out  =>  curr_character_out
    );

    BRAM2 : entity work.bram_single_port
    generic map(
        DataWidth => AddrWidthInstr,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer ,
     data_in   =>  addr_instr_backtracking_in,
     data_out  =>  addr_instr_backtracking_out
    );

    BRAM3 : entity work.bram_single_port
    generic map(
        DataWidth => 1,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer,
     data_in   =>  state_match_in_i,
     data_out  =>  state_match_out_i
    );

    BRAM4 : entity work.bram_single_port
    generic map(
        DataWidth => 1+BufferAddressWidth,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer,
     data_in   =>  match_acc_in,
     data_out  =>  match_acc_out
    );

    BRAM5 : entity work.bram_single_port
    generic map(
        DataWidth => MinMaxWidth*2,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer,
     data_in   =>  min_max_in,
     data_out  =>  min_max_out
    );

    BRAM6 : entity work.bram_single_port
    generic map(
        DataWidth => AddrWidthData,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer,
     data_in   =>  last_match_in,
     data_out  =>  last_match_out
    );

    BRAM7 : entity work.bram_single_port
    generic map(
        DataWidth => CharacterNumber,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer,
     data_in   =>  curr_last_match_char_in,
     data_out  =>  curr_last_match_char_out
    );

    BRAM8 : entity work.bram_single_port
    generic map(
        DataWidth => AddrWidthData,
        AddrWidth => BufferAddressWidth
    )
    port map(
     clk       =>  clk,
     we        =>  push,
     en        =>  en_i,
     addr      =>  current_pointer,
     data_in   =>  addr_data_in,
     data_out  =>  addr_data_out
    );
  -- concurrent assignements
  -- the stack is empty when the pointer comes to 0
  empty_i      <= '1' when (current_pointer = 0 or (current_pointer = 1 and pop = '1')) else '0';
  -- the stack is full when the pointer comes to the last elements of the buffer
  full_i       <= '1' when (current_pointer = 2**BufferAddressWidth) else '0';
  empty        <= empty_i;
  full         <= full_i;
  process (clk, rst)
  begin

    if rst = '0' then
      -- initialization of the stack structure
      current_pointer <= (others => '0');

    elsif rising_edge(clk) then
      -- operations with the stack
      if push = '1' and full_i = '0' then
        -- write operation: inserts an element into the buffer and moves the pointer
        current_pointer                            <= current_pointer + 1;
      elsif pop = '1' and current_pointer > 0 then
        -- popping element from the stack implies to move the stack pointer
        current_pointer                            <= current_pointer - 1;
      end if;
    end if;

  end process;

end Behavioral;
