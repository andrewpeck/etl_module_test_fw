library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.fast_commands_pkg.all;

entity etroc_tx is
  generic(
    ELINK_WIDTH : positive := 8
    );
  port(

    clock : in std_logic;
    reset : in std_logic;

    l1a_inj_dly : in std_logic_vector (15 downto 0);

    l1a_i      : in std_logic;
    l1a_qinj   : in std_logic;
    bc0        : in std_logic;
    ecr        : in std_logic;
    qinj       : in std_logic;
    ws_stop    : in std_logic;
    ws_start   : in std_logic;
    stop       : in std_logic;
    link_reset : in std_logic;

    data_o : out std_logic_vector (ELINK_WIDTH-1 downto 0)
    );
end etroc_tx;

architecture behavioral of etroc_tx is

  signal l1a_dly_cnt : integer range 0 to 2**16-1;
  signal l1a_dly_inj : std_logic := '0';
  signal l1a_dly_gen : std_logic := '0';

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then

      -- default to idle
      data_o <= IDLE_CMD;

      if (l1a = '1' and bc0 = '1') then
        data_o <= L1ABCR_CMD;
      elsif (l1a = '1' and ecr = '1') then
        data_o <= L1ACR_CMD;
      elsif (l1a = '1') then
        data_o <= L1A_CMD;
      elsif (l1a_qinj = '1' or qinj = '1') then
        data_o <= INJQ_CMD;
      elsif (ws_start = '1') then
        data_o <= WS_START_CMD;
      elsif (ws_stop = '1') then
        data_o <= WS_STOP_CMD;
      elsif (stop = '1') then
        data_o <= STP_CMD;
      elsif (bc0 = '1') then
        data_o <= BCR_CMD;
      elsif (link_reset = '1') then
        data_o <= LINK_RESET_CMD;
      end if;

    end if;  -- rising_edge(clock)
  end process;

  --------------------------------------------------------------------------------
  -- L1A + Charge Injection Synchronization
  --
  -- Allows for the option to generate an a Qinj with an L1A coming some
  -- programmable number of clock cycles later
  --
  --------------------------------------------------------------------------------

  l1a <= l1a_i or l1a_dly_gen;

  process (clock) is
  begin

    if (rising_edge(clock)) then

      if (l1a_qinj = '1') then
        l1a_dly_cnt <= to_integer(unsigned(l1a_inj_dly));
      elsif (l1a_dly_cnt > 0) then
        l1a_dly_cnt <= l1a_dly_cnt - 1;
      end if;

    end if;
  end process;

  process (l1a_inj_dly, l1a_qinj) is
  begin
    if (l1a_inj_dly = x"0000") then
      l1a_dly_gen <= l1a_qinj;
    elsif (l1a_dly_cnt = 1) then
      l1a_dly_gen <= '1';
    else
      l1a_dly_gen <= '0';
    end if;
  end process;

end behavioral;
