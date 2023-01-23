library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package fast_commands_pkg is
  constant IDLE_CMD       : std_logic_vector(7 downto 0) := x"F0";
  constant LINK_RESET_CMD : std_logic_vector(7 downto 0) := x"33";
  constant L1ACR_CMD      : std_logic_vector(7 downto 0) := x"66";
  constant L1A_CMD        : std_logic_vector(7 downto 0) := x"96";
  constant L1ABCR_CMD     : std_logic_vector(7 downto 0) := x"99";
end package fast_commands_pkg;
