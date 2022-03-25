library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.fast_commands_pkg.all;

entity etroc_tx is
  generic(ELINK_WIDTH : positive := 8);
  port(

    clock : in std_logic;
    reset : in std_logic;

    l1a        : in std_logic;
    bc0        : in std_logic;
    link_reset : in std_logic;

    data_o : out std_logic_vector (ELINK_WIDTH-1 downto 0)
    );
end etroc_tx;

architecture behavioral of etroc_tx is

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then

      -- default to idle
      data_o <= IDLE_CMD;

      if (l1a = '1' and bc0 = '1') then
        data_o <= L1ABCR_CMD;
      elsif (l1a = '1') then
        data_o <= L1A_CMD;
      elsif (link_reset = '1') then
        data_o <= LINK_RESET_CMD;
      end if;

    end if;
  end process;

end behavioral;
