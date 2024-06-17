library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RamData is
    generic (
        -- Length of a single word stored in a ram cell
        RamWidth            : positive := 8;
        -- Number of bits that can be written to the output port of the Ram
        InternalBusWidth    : positive := 32;
        -- Number of bits  that can be written in the Ram
        ExternalBusWidth    : positive := 128;
        -- Number of bits that defines the length of the address. The DataRam
        -- will have 2^AddressWidth cells
        AddressWidth        : positive := 8
        );
    port (
        -- reset signal. Active low
        rst             : in std_logic;
        -- clock signal
        clk             : in std_logic;
        -- read address
        address_rd_1        : in std_logic_vector(AddressWidth - 1 downto 0);
        address_rd_2        : in std_logic_vector(AddressWidth - 1 downto 0);
        -- write address
        address_wr      : in std_logic_vector(AddressWidth - 1 downto 0);
        -- data to be stored at the write address
        data_in         : in std_logic_vector(ExternalBusWidth - 1 downto 0);
        -- signal of write enable
        we              : in std_logic;
        -- data read, relative to the read address
        data_out_1      : out std_logic_vector(InternalBusWidth - 1 downto 0);
        data_out_2      : out std_logic_vector(InternalBusWidth - 1 downto 0);
        data_out_3      : out std_logic_vector(InternalBusWidth - 1 downto 0);
        data_out_4      : out std_logic_vector(InternalBusWidth - 1 downto 0);
        data_out_5      : out std_logic_vector(InternalBusWidth - 1 downto 0);
        --data out last match
        data_out_6      : out std_logic_vector(InternalBusWidth - 1 downto 0)
        );
end RamData;

architecture behav of RamData is
    -- The Data Ram is composed by an array that exceeds the specified AddressWidth because it
    -- otherwise the last cells of the array could not be read because data_out_1_1 would be undefined
    type RAM is array(INTEGER RANGE <>) of std_logic_vector(RamWidth - 1 downto 0);
    signal b_ram : RAM(0 to (2**AddressWidth - 1));
begin
    read : process (clk, rst, address_rd_1, address_rd_2,b_ram) 
    begin
        if rst = '0' then
            data_out_1 <= (others => '0');
            data_out_2 <= (others => '0');
            data_out_3 <= (others => '0');
            data_out_4 <= (others => '0');
            data_out_5 <= (others => '0');
            data_out_6 <= (others => '0');

        else
            -- This loops collects all the data from the cell addressed by address_rd_1_1 to BusWidth / RamWidth cells ahead.
            -- This becuase the bus can contain more data than the RamWidth.
            for i in InternalBusWidth / RamWidth downto 1 loop
                    data_out_1(i * RamWidth - 1 downto RamWidth * (i - 1)) <= b_ram((to_integer(unsigned(address_rd_1)) + InternalBusWidth / RamWidth - i) mod 2**AddressWidth);
                    data_out_2(i * RamWidth - 1 downto RamWidth * (i - 1)) <= b_ram((to_integer(unsigned(address_rd_1 ) + 1) + InternalBusWidth / RamWidth - i) mod 2**AddressWidth);
                    data_out_3(i * RamWidth - 1 downto RamWidth * (i - 1)) <= b_ram((to_integer(unsigned(address_rd_1) + 2) + InternalBusWidth / RamWidth - i) mod 2**AddressWidth);
                    data_out_4(i * RamWidth - 1 downto RamWidth * (i - 1)) <= b_ram((to_integer(unsigned(address_rd_1) + 3) + InternalBusWidth / RamWidth - i) mod 2**AddressWidth);
                    data_out_5(i * RamWidth - 1 downto RamWidth * (i - 1)) <= b_ram((to_integer(unsigned(address_rd_1 ) + 4) + InternalBusWidth / RamWidth - i) mod 2**AddressWidth);
                    data_out_6(i * RamWidth - 1 downto RamWidth * (i - 1)) <= b_ram((to_integer(unsigned(address_rd_2)) + InternalBusWidth / RamWidth - i) mod 2**AddressWidth);
            end loop;
            -- Data is read everytime address_rd_1 changes
        end if;
    end process read;

    write : process (clk, rst)
    begin
        -- If rst is low the array is set to zero
        if rst = '0' then
            b_ram <= (others => (others => '0'));
        else
            -- for each rising edge of the clock, if write enable is low, data is written at the specified address
            if rising_edge(clk) then
                if we = '1' then
                    for i in ExternalBusWidth / RamWidth downto 1 loop
                        b_ram(to_integer(unsigned(address_wr)) + ExternalBusWidth / RamWidth - i)   <= data_in(i * RamWidth - 1 downto (i - 1) * RamWidth);
                    end loop;
                end if;
            end if;
        end if;
    end process write;
end behav;
