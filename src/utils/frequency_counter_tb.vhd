library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.math_real.uniform;
use ieee.math_real.floor;

entity fcnt_tb is
end fcnt_tb;

architecture test of fcnt_tb is

  file file_RESULTS   : text;
  constant clk1_period : time := 30.0 us;
  constant clk2_period : time := 10.0 us;
  constant sim_period : time := 40000 us;

  signal reset : std_logic := '1';
  signal clock1, clock2 : std_logic := '0';

  signal rate : std_logic_vector (31 downto 0) := (others => '0');

begin

  proc1_clk : process
  begin
    wait for clk1_period/2.0;
    clock1 <= '0';
    wait for clk1_period/2.0;
    clock1 <= '1';
  end process;

  proc2_clk : process
  begin
    wait for clk2_period/2.0;
    clock2 <= '0';
    wait for clk2_period/2.0;
    clock2 <= '1';
  end process;

  proc_reset : process
  begin
    reset <= '1';
    wait for 100 ns;
    wait until rising_edge(clock1);
    reset <= '0';
    wait;
  end process;

  frequency_counter_1: entity work.frequency_counter
    generic map (
      clk_a_freq => 3333
      )
    port map (
      reset => reset,
      clk_a => clock1,
      clk_b => clock2,
      rate  => rate
      );

  --proc_finish : process
  --begin
  --  wait for sim_period;
  --  std.env.finish;
  --end process;

  fopen : process
  begin
    file_open(file_RESULTS, "output_file.txt", write_mode);
    wait;
  end process;

  proc_data_o : process
  begin
    wait on rate;
    assert false report "data" & integer'image(to_integer(unsigned(rate))) severity note;
      --write(file_RESULTS, "0x" & to_hstring(unsigned(data)) & LF);  -- Hexadecimal representation
  end process;

end test;
