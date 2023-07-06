library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;
use ieee.numeric_std.all;

use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_filler_tb is
end tx_filler_tb;

architecture behavioral of tx_filler_tb is

  signal clock : std_logic;
  signal rst   : std_logic;
  signal l1a   : std_logic;
  signal bc0   : std_logic;
  signal tlast : std_logic;
  signal tnext : std_logic;
  signal dout  : std_logic_vector (7 downto 0);
  signal din : std_logic_vector (31 downto 0) := (others => '0');


  constant clk_period : time := 30.0 ns;
  constant sim_period : time := 4000000 ns;

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
    rst <= '1';
    wait for 100 ns;
    wait until rising_edge(clock);
    rst <= '0';
    wait;
  end process;

  proc_finish : process
  begin
    wait for sim_period;
    std.env.finish;
  end process;

  tx_filler_generator_inst : entity work.tx_filler_generator
    port map (
      clock => clock,
      rst   => rst,
      l1a   => l1a,
      bc0   => bc0,
      tlast => tlast,
      tnext => tnext,
      dout  => dout);

  din <= x"000000" & dout;

  etroc_rx_1: entity work.etroc_rx
    port map (
      clock             => clock,
      reset             => rst,
      data_i            => din,
      elinkwidth        => "010",
      zero_suppress     => '1',
      raw_data_mode     => '0',
      bitslip_i         => '0',
      bitslip_auto_i    => '1',
      state_mon_o       => open,
      frame_mon_o       => open,
      fifo_data_o       => open,
      fifo_wr_en_o      => open,
      bcid_o            => open,
      type_o            => open,
      event_cnt_o       => open,
      start_of_packet_o => open,
      cal_o             => open,
      tot_o             => open,
      toa_o             => open,
      col_o             => open,
      row_o             => open,
      ea_o              => open,
      data_en_o         => open,
      stat_o            => open,
      hitcnt_o          => open,
      crc_o             => open,
      crc_calc_o        => open,
      chip_id_o         => open,
      end_of_packet_o   => open,
      locked_o          => open,
      err_o             => open,
      busy_o            => open,
      idle_o            => open
      );

end behavioral;
