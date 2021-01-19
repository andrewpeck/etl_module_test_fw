
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity pattern_checker is
  generic(
    COUNTER_WIDTH : integer := 32;
    WIDTH : integer := 8
    );
  port(

    clock : in std_logic;

    reset : in std_logic;

    cnt_reset : in std_logic;

    data : in std_logic_vector (WIDTH-1 downto 0);

    check_prbs  : in std_logic;
    check_upcnt : in std_logic;

    prbs_errors_o : out std_logic_vector (COUNTER_WIDTH-1 downto 0);
    upcnt_errors_o : out std_logic_vector (COUNTER_WIDTH-1 downto 0)

    );
end pattern_checker;

architecture behavioral of pattern_checker is

  signal prbs_errs : std_logic_vector (WIDTH-1 downto 0);
  signal upcnt_err : std_logic;

begin

  --------------------------------------------------------------------------------
  -- upcnt check
  --------------------------------------------------------------------------------

  process (clock) is
    variable upcnt : integer range 0 to 2**WIDTH-1 := 0;
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or check_upcnt = '0') then
        upcnt := to_integer(unsigned(data))+1;
      else
        if (upcnt = 2**WIDTH-1) then
          upcnt := 0;
        else
          upcnt := upcnt + 1;
        end if;
      end if;

      upcnt_err <= or_reduce (std_logic_vector(to_unsigned(upcnt, WIDTH)) xor data);

    end if;
  end process;

  upcnt_err_counter : entity work.counter
    generic map (
      roll_over   => false,
      async_reset => false,
      width       => COUNTER_WIDTH
      )
    port map (
      clk    => clock,
      reset  => reset or not check_upcnt or cnt_reset,
      enable => '1',
      event  => upcnt_err,
      count  => upcnt_errors_o,
      at_max => open
      );

  --------------------------------------------------------------------------------
  -- prbs check
  --------------------------------------------------------------------------------

  -- FIXME: need to expand for widths more than 8, just generate multiple
  --
  prbs_any_chk : entity work.prbs_any
    generic map (
      chk_mode    => true,
      inv_pattern => false,
      poly_lenght => 7,
      poly_tap    => 6,
      nbits       => 8)
    port map (
      rst      => reset or not check_prbs,
      clk      => clock,
      data_in  => data,
      en       => '1',
      data_out => prbs_errs
      );

  prbs_err_counter : entity work.counter
    generic map (
      roll_over   => false,
      async_reset => false,
      width       => COUNTER_WIDTH
      )
    port map (
      clk    => clock,
      reset  => reset or not check_prbs or cnt_reset,
      enable => '1',
      -- have to handle the weird case that if the link is idle (e.g. 000000000) the prbs checker
      -- just registers no errors and marks the link as good... zero should not occur in the PRBS generator
      -- since the polynomial just gets stuck
      event  => or_reduce(prbs_errs) or not or_reduce(data),
      count  => prbs_errors_o,
      at_max => open
      );


end behavioral;
