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

entity module_tb is
end module_tb;

architecture test of module_tb is

  file file_RESULTS   : text;
  constant clk_period : time := 30.0 ns;
  constant sim_period : time := 400000 ns;

  signal reset : std_logic := '1';
  signal clock : std_logic := '0';

  signal data : std_logic_vector (7 downto 0) := (others => '0');


  -- Vector reverse function
  -- Reverse function is used to reverse the CRC before sending it. The standard
  -- requires to send the 16 bits from the LSB to the MSB.
  function reverse_v (
    a : in std_logic_vector)
    return std_logic_vector is

    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'REVERSe_range) is a;

  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;

    return result;
  end;

begin

  proc_clk : process
  begin
    wait for clk_period/2.0;
    clock <= '0';
    wait for clk_period/2.0;
    clock <= '1';
  end process;

  proc_reset : process
  begin
    reset <= '1';
    wait for 100 ns;
    wait until rising_edge(clock);
    reset <= '0';
    wait;
  end process;


  proc_finish : process
  begin
    wait for sim_period;
    std.env.finish;
  end process;

  fopen : process
  begin
    file_open(file_RESULTS, "output_file.txt", write_mode);
    wait;
  end process;

  proc_data_o : process
  begin
    wait until rising_edge(clock);
    --assert false report "data" & integer'image(to_integer(unsigned(data_o))) severity note;
    write(file_RESULTS, "0x" & to_hstring(unsigned(
      reverse_v(data)
     --data(0) & data(1) & data(2) & data(3) & data(4) & data(5) data(6) & data(7)
      )) & LF);                         -- Hexadecimal representation
  end process;

  PRBS_ANY_1 : entity work.PRBS_ANY
    generic map (
      CHK_MODE    => false,
      INV_PATTERN => false,
      POLY_LENGHT => 7,
      POLY_TAP    => 6,
      NBITS       => 8
      )
    port map (
      RST      => reset,
      CLK      => clock,
      DATA_IN  => (others => '0'),
      EN       => not reset,
      DATA_OUT => data
      );

end test;
