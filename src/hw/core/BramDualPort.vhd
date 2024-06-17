-- True-Dual-Port BRAM with Byte-wide Write Enable
-- Read First mode --
-- bytewrite_tdp_ram_rf.vhd
--
-- READ_FIRST ByteWide WriteEnable Block RAM Template
-- used single clk for both the ports
-- assumption: keep attention to use the same address cuncorrently from both the ports
-- multi data w data enable, remove if not used
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity BramDualPort is
generic(
     Size                : integer  := 256;
     AddressWidth        : integer  := 8;
     InternalBusWidth    : positive := 32;
     RamDataWidth        : integer  := 8
);

port(
          clk          : in  std_logic;
          en_a         : in  std_logic;
          we_a         : in  std_logic_vector(InternalBusWidth / RamDataWidth - 1 downto 0);
          addr_a       : in  std_logic_vector(AddressWidth - 1 downto 0);
          data_in_a    : in  std_logic_vector(InternalBusWidth - 1 downto 0);
          data_out_a   : out std_logic_vector(InternalBusWidth - 1 downto 0); 
          en_b         : in  std_logic;
          we_b         : in  std_logic_vector(InternalBusWidth / RamDataWidth - 1 downto 0);
          addr_b       : in  std_logic_vector(AddressWidth - 1 downto 0);
          data_in_b    : in  std_logic_vector(InternalBusWidth - 1 downto 0);
          data_out_b   : out std_logic_vector(InternalBusWidth - 1 downto 0)
);
end BramDualPort;


architecture behav of BramDualPort is

    type ram_type is array (0 to SIZE - 1) of std_logic_vector(InternalBusWidth - 1 downto 0);
    shared variable RAM : ram_type := (others => (others => '0'));
    constant We_Width : positive := InternalBusWidth/RamDataWidth;


    begin

    -- check of the Size parameter
    assert Size = 2**AddressWidth report
     "Size GENERIC error: must be 2 to the power of AddressWidth"
       severity failure;
    ------- Port A -------
    process(clk)
    begin
      if rising_edge(clk) then
         if en_a = '1' then
            data_out_a <= RAM(conv_integer(addr_a));
            for i in 0 to We_Width - 1 loop 
              if we_a(i) = '1' then
                  RAM(conv_integer(addr_a))((i + 1) * RamDataWidth - 1 downto i * RamDataWidth) := data_in_a((i + 1) * RamDataWidth - 1 downto i * RamDataWidth);
              end if;
            end loop;
         end if;
      end if;

    end process;

    ------- Port B ------- 
    process(clk)
    begin
         if rising_edge(clk) then
          if en_b = '1' then
            data_out_b <= RAM(conv_integer(addr_b));
            for i in 0 to We_Width - 1 loop
              if we_b(i) = '1' then
                RAM(conv_integer(addr_b))((i + 1) * RamDataWidth - 1 downto i * RamDataWidth) := data_in_b((i + 1) * RamDataWidth - 1 downto i * RamDataWidth);
              end if; 
            end loop;
          end if;
         end if;
    end process;
end behav;