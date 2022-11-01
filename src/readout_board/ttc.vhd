
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity ttc is
  port(

    clock      : in  std_logic;
    reset      : in  std_logic;
    l1a        : out std_logic;
    bc0        : out std_logic;
    link_reset : out std_logic;

    force_trig  : in std_logic;
    ext_trig    : in std_logic;
    ext_trig_en : in std_logic;

    trig_gen_rate : in std_logic_vector (31 downto 0)

    );
end ttc;

architecture behavioral of ttc is

  signal l1a_gen : std_logic               := '0';
  signal bxn     : natural range 0 to 3563 := 0;

begin

  --------------------------------------------------------------------------------
  -- Trigger Generation
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      l1a <= l1a_gen or force_trig or (ext_trig_en and ext_trig);
    end if;
  end process;

  trig_gen_inst : entity work.trig_gen
    port map (
      sys_clk    => clock,
      sys_rst    => reset,
      sys_bx_stb => '1',
      rate       => trig_gen_rate,
      trig       => l1a_gen
      );

  --------------------------------------------------------------------------------
  -- BXN Bookkeeping
  --------------------------------------------------------------------------------

  bc0 <= '1' when bxn = 0 else '0';

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (bxn = 3563) then
        bxn <= 0;
      else
        bxn <= bxn + 1;
      end if;
    end if;
  end process;

end behavioral;
