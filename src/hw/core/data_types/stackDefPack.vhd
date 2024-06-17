library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.genericsPack.all;

package Stackpack is

--constant StackDataWidth           : natural := 24;

constant counterMSB             : natural := StackDataWidth - 1;
constant counterLSB             : natural := StackDataWidth - CounterWidth;
constant op_codeMSB             : natural := counterLSB - 1;
constant op_codeLSB             : natural := counterLSB - OpCodeBus;
constant matchAccum             : natural := op_codeLSB - 1;
constant specialaddrMSB         : natural := matchAccum - 1;
constant specialaddrLSB         : natural := matchAccum - AddressWidthInstr;
constant contextaddrMSB         : natural := specialaddrLSB - 1;
constant contextaddrLSB         : natural := specialaddrLSB - AddressWidthData;

end Stackpack;

-- package body Stackpack is
-- end package body Stackpack;
