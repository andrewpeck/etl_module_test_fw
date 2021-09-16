library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_ctrl.all;

library work;
use work.types.all;
use work.lpgbt_pkg.all;
use work.components.all;

library ipbus;
use ipbus.ipbus.all;

entity elink_daq is
  generic(
    UPWIDTH     : natural := 8;
    NUM_UPLINKS : natural := 2
    );
  port(
    clk40  : in  std_logic;
    reset  : in  std_logic;
    ctrl   : in  READOUT_BOARD_CTRL_t;
    mon    : out READOUT_BOARD_MON_t;
    data_i : in  lpgbt_uplink_data_rt_array (NUM_UPLINKS-1 downto 0);

    fifo_wb_in  : in  ipb_wbus;
    fifo_wb_out : out ipb_rbus
    );
end elink_daq;

architecture behavioral of elink_daq is

  signal data   : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');
  signal data_r : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');

  signal elink_sel : integer range 0 to 27;
  signal lpgbt_sel : integer range 0 to 1;

  constant DAQ_FIFO_DEPTH         : positive := 2*32768;
  constant DAQ_FIFO_WORDCNT_WIDTH : positive := integer(ceil(log2(real(DAQ_FIFO_DEPTH))));

  signal fifo_dout  : std_logic_vector (31 downto 0) := (others => '0');
  signal fifo_rd_en : std_logic                      := '0';
  signal fifo_wr_en : std_logic                      := '0';
  signal fifo_empty : std_logic                      := '0';
  signal fifo_valid : std_logic                      := '0';
  signal fifo_full  : std_logic                      := '0';

  signal daq_force_trigger, daq_trigger : std_logic                           := '0';
  signal daq_armed                      : std_logic                           := '0';
  signal daq_rearm                      : std_logic                           := '0';
  signal fifo_capture_depth             : integer range 0 to DAQ_FIFO_DEPTH-1;
  signal fifo_words_captured            : integer range 0 to DAQ_FIFO_DEPTH-1 := 0;

  signal trig0, trig1           : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');
  signal trig0_mask, trig1_mask : std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');

begin

  trig0              <= ctrl.fifo_trig0(UPWIDTH-1 downto 0);
  trig1              <= ctrl.fifo_trig1(UPWIDTH-1 downto 0);
  trig0_mask         <= ctrl.fifo_trig0_mask(UPWIDTH-1 downto 0);
  trig1_mask         <= ctrl.fifo_trig1_mask(UPWIDTH-1 downto 0);
  mon.fifo_armed     <= daq_armed;
  mon.fifo_full      <= fifo_full;
  mon.fifo_empty     <= fifo_empty;
  daq_force_trigger  <= ctrl.fifo_force_trig;
  fifo_capture_depth <= to_integer(unsigned(ctrl.fifo_capture_depth));

  process (clk40) is
  begin
    if (rising_edge(clk40)) then

      if (fifo_wr_en = '1') then
        fifo_words_captured <= fifo_words_captured + 1;
      end if;

      -- trigger
      if ((daq_armed = '1' and
           ((trig1_mask and data) = (trig1_mask and trig1)) and
           ((trig0_mask and data_r) = (trig0_mask and trig0)))
          or daq_force_trigger = '1') then
        fifo_words_captured <= 0;
        daq_armed           <= '0';
        fifo_wr_en          <= '1';
      end if;

      -- reached fifo # of words
      if (fifo_capture_depth = fifo_words_captured) then
        daq_armed           <= '1';
        fifo_wr_en          <= '0';
        fifo_words_captured <= 0;
      end if;

      -- stop writing when it is full, and wait until it is re-armed
      if (fifo_full = '1') then
        daq_armed  <= '0';
        fifo_wr_en <= '0';
      end if;

      -- reset
      if (ctrl.fifo_reset = '1') then
        daq_armed  <= '1';
        fifo_wr_en <= '0';
      end if;

    end if;
  end process;

  -- copy for timing and align to system 40MHz
  elink_sel <= to_integer(unsigned(ctrl.fifo_elink_sel));
  lpgbt_sel <= to_integer(unsigned(std_logic_vector'("" & ctrl.fifo_lpgbt_sel)));  -- vhdl qualify operator

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      data   <= data_i(lpgbt_sel).data(8*(elink_sel+1)-1 downto 8*elink_sel);
      data_r <= data;
    end if;
  end process;

  fifo_sync_1 : entity work.fifo_sync
    generic map (
      DEPTH               => DAQ_FIFO_DEPTH,
      USE_ALMOST_FULL     => 1,
      WR_WIDTH            => 32,
      RD_WIDTH            => 32,
      WR_DATA_COUNT_WIDTH => DAQ_FIFO_WORDCNT_WIDTH,
      USE_WR_DATA_COUNT   => 1
      )
    port map (
      rst           => ctrl.fifo_reset,  -- Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
      clk           => clk40,
      wr_en         => fifo_wr_en,
      rd_en         => fifo_rd_en,
      din           => x"000000" & data,
      dout          => fifo_dout,
      valid         => fifo_valid,
      wr_data_count => open,
      overflow      => open,
      full          => fifo_full,
      almost_full   => open,
      empty         => fifo_empty
      );

  wishbone_fifo_reader_inst : entity work.wishbone_fifo_reader
    port map (
      clk       => clk40,
      sel       => '1',
      reset     => reset,
      ipbus_in  => fifo_wb_in,
      ipbus_out => fifo_wb_out,
      rd_en     => fifo_rd_en,
      din       => fifo_dout,
      valid     => fifo_valid,
      empty     => fifo_empty
      );

end behavioral;
