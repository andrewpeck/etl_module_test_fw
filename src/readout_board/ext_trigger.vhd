library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity ext_trigger is
  port(
    clock         : in  std_logic;
    clock_320     : in  std_logic;
    ext_trigger_i : in  std_logic;
    ext_trigger_o : out std_logic
    );
end ext_trigger;

architecture behavioral of ext_trigger is
  signal ext_trigger : std_logic := '0';

  attribute mark_debug : string;
  attribute mark_debug of ext_trigger : signal is "true";
begin

  ext_trigger_o <= ext_trigger;

  ext_rx_gen : if (true) generate
    signal trigger_pos     : std_logic := '0';
    signal trigger_neg     : std_logic := '0';
    signal trigger_pos_r1  : std_logic := '0';
    signal trigger_neg_r1  : std_logic := '0';
    signal trigger_or      : std_logic;
    signal ext_trigger_320 : std_logic;
    signal trigger_cnt     : integer range 0 to 8 := 0;
    signal armed           : boolean;

    attribute mark_debug of trigger_pos : signal is "true";
    attribute mark_debug of trigger_neg : signal is "true";
    attribute mark_debug of trigger_pos_r1 : signal is "true";
    attribute mark_debug of trigger_neg_r1 : signal is "true";
    attribute mark_debug of trigger_or : signal is "true";
    attribute mark_debug of ext_trigger_320 : signal is "true";
    attribute mark_debug of trigger_cnt : signal is "true";
    attribute mark_debug of armed : signal is "true";

  begin

    process (clock_320) is
    begin
      if (rising_edge(clock_320)) then
        trigger_pos <= ext_trigger_i;
      end if;
    end process;

    process (clock_320) is
    begin
      if (falling_edge(clock_320)) then
        trigger_neg <= ext_trigger_i;
      end if;
    end process;

    process (clock_320) is
    begin
      if (rising_edge(clock_320)) then
        trigger_pos_r1 <= trigger_pos;
        trigger_neg_r1 <= trigger_neg;
      end if;
    end process;

    trigger_or      <= trigger_pos_r1 or trigger_neg_r1;

    ext_trigger_320 <= '1' when trigger_cnt > 0 else '0';

    process (clock_320) is
    begin
      if (rising_edge(clock_320)) then

        if (armed and trigger_or = '1') then
          armed           <= false;
          trigger_cnt     <= 8;
        elsif (trigger_cnt > 0) then
          armed           <= false;
          trigger_cnt     <= trigger_cnt - 1;
        elsif (trigger_or = '0') then
          armed <= true;
        end if;

      end if;
    end process;

    process (clock) is
    begin
      if (rising_edge(clock)) then
        ext_trigger <= ext_trigger_320;
      end if;
    end process;

  end generate;

end behavioral;
