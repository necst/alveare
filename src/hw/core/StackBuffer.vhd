library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity StackBuffer is
    generic(
        BufferAddressWidth : positive := 3;
        StackDataWidth     : positive := 16
        );
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;
        we                  : in std_logic;
        pop                 : in std_logic;
        empty           : out std_logic;
        full                : out std_logic;
        data_in         : in std_logic_vector(StackDataWidth - 1 downto 0);
        data_out        : out std_logic_vector(StackDataWidth - 1 downto 0)
        );
end StackBuffer;

architecture Behavioral of StackBuffer is

  -- pointer to the top of the stack
  signal current_pointer : std_logic_vector (BufferAddressWidth-1 downto 0) := (others => '0');

  -- buffer: list of elements
  type BUFFER_TYPE is array (INTEGER RANGE <>) of std_logic_vector(StackDataWidth-1 downto 0);
  signal buf : BUFFER_TYPE(0 to (2**BufferAddressWidth - 1));

begin

  -- concurrent assignements
  data_out <= buf(to_integer(unsigned(current_pointer(BufferAddressWidth-1 downto 0)-1)));
  -- the stack is empty when the pointer comes to 0
  empty    <= '1' when (current_pointer = 0)                     else '0';
  -- the stack is full when the pointer comes to the last elements of the buffer
  full     <= '1' when (current_pointer = 2**BufferAddressWidth) else '0';

  process (clk, rst)
  begin

    if rst = '0' then
      -- initialization of the stack structure
      current_pointer <= (others => '0');
      for i in 0 to natural(2**BufferAddressWidth - 1) loop
        buf(i)        <= (others => '0');
      end loop;  -- i

    elsif rising_edge(clk) then
      -- operations with the stack
      if we = '1' then
        -- write operation: inserts an element into the buffer and moves the pointer
        buf(to_integer(unsigned(current_pointer))) <= data_in;
        current_pointer                            <= current_pointer+1;
      elsif pop = '1' then
        -- popping element from the stack implies to move the stack pointer
        current_pointer                            <= current_pointer -1;
      end if;
    end if;

  end process;

end Behavioral;
