library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_Ctrl.all;
use ctrl_lib.FW_INFO_Ctrl.all;

package types is
  constant std_logic0 : std_logic := '0';
  constant std_logic1 : std_logic := '1';
  type std32_array_t is array (integer range <>) of std_logic_vector(31 downto 0);
  type READOUT_BOARD_Mon_array_t is array (integer range <>) of READOUT_BOARD_Mon_t;
  type READOUT_BOARD_Ctrl_array_t is array (integer range <>) of READOUT_BOARD_Ctrl_t;

  type ip_addr_t is array (integer range 3 downto 0) of integer range 0 to 255;
  type mac_addr_t is array (integer range 0 to 5) of std_logic_vector (7 downto 0);

  function to_slv (addr : ip_addr_t) return std_logic_vector;

end package types;

package body types is

  function to_slv (addr : ip_addr_t) return std_logic_vector is
    variable slv : std_logic_vector(31 downto 0);
  begin
    slv(31 downto 24) := std_logic_vector(to_unsigned(addr(3), 8));
    slv(23 downto 16) := std_logic_vector(to_unsigned(addr(2), 8));
    slv(15 downto 8)  := std_logic_vector(to_unsigned(addr(1), 8));
    slv(7 downto 0)   := std_logic_vector(to_unsigned(addr(0), 8));
    return slv;
  end;

end package body types;
