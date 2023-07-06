
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity ttc is
  port(

    clock : in std_logic;
    reset : in std_logic;

    -- ttc outputs
    l1a  : out std_logic;
    bc0  : out std_logic;
    qinj : out std_logic;

    -- trigger injector
    trig_gen_rate : in std_logic_vector (31 downto 0);
    force_trig    : in std_logic;
    ext_trig      : in std_logic;
    ext_trig_en   : in std_logic;

    -- charge injector
    force_qinj     : in std_logic;
    qinj_makes_l1a : in std_logic;
    l1a_delay      : in std_logic_vector (8 downto 0);
    qinj_deadtime  : in std_logic_vector (15 downto 0);
    qinj_gen_rate  : in std_logic_vector (31 downto 0)

    );
end ttc;

architecture behavioral of ttc is

  signal l1a_gen  : std_logic               := '0';
  signal qinj_gen : std_logic               := '0';
  signal bxn      : natural range 0 to 3563 := 0;

  signal qinj_l1a_dly : std_logic_vector (511 downto 0);
  signal qinj_l1a     : std_logic;

  signal qinj_ready    : std_logic;
  signal qinj_dead_cnt : integer range 0 to 2**16-1;

begin

  --------------------------------------------------------------------------------
  -- Trigger Generation
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      l1a <= qinj_l1a or l1a_gen or force_trig or (ext_trig_en and ext_trig);
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
  -- Qinj gen
  --------------------------------------------------------------------------------

  qinj <= qinj_ready and (force_qinj or qinj_gen);

  process (clock) is
  begin
    if (rising_edge(clock)) then

      qinj_l1a <= qinj_l1a_dly(to_integer(unsigned(l1a_delay)));

      qinj_l1a_dly(0) <= qinj_makes_l1a and qinj;

      for I in 1 to qinj_l1a_dly'length-1 loop
        qinj_l1a_dly(I) <= qinj_l1a_dly(I-1);
      end loop;
    end if;
  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      if (qinj_dead_cnt > 0) then
        qinj_ready    <= '0';
        qinj_dead_cnt <= qinj_dead_cnt - 1;
      else

        qinj_ready <= '1';

        if (qinj <= '1') then
          qinj_ready    <= '0';
          qinj_dead_cnt <= to_integer(unsigned(qinj_deadtime));
        end if;

      end if;
    end if;
  end process;


  qinj_gen_inst : entity work.trig_gen
    port map (
      sys_clk    => clock,
      sys_rst    => reset,
      sys_bx_stb => '1',
      rate       => qinj_gen_rate,
      trig       => qinj_gen
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
