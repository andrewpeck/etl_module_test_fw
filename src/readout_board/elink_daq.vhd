library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.types.all;
use work.lpgbt_pkg.all;
use work.components.all;

library ipbus;
use ipbus.ipbus.all;

entity elink_daq is
  generic(
    UPWIDTH        : natural  := 8;
    NUM_UPLINKS    : natural  := 2;
    DAQ_FIFO_DEPTH : positive := 2*32768
    );
  port(
    clk40      : in std_logic;
    reset      : in std_logic;
    fifo_reset : in std_logic;

    fixed_pattern : in std_logic;

    trig0, trig1, trig2, trig3, trig4, trig5, trig6, trig7, trig8, trig9 :
        in std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');
    mask0, mask1, mask2, mask3, mask4, mask5, mask6, mask7, mask8, mask9 :
        in std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');

    force_trig : in std_logic;

    armed : out std_logic;
    full  : out std_logic;
    empty : out std_logic;

    fifo_capture_depth : in integer range 0 to DAQ_FIFO_DEPTH-1;

    data_i : in lpgbt_uplink_data_rt_array (NUM_UPLINKS-1 downto 0);

    reverse_bits : in std_logic;

    elink_sel : in integer range 0 to 27;
    lpgbt_sel : in integer range 0 to 1;

    fifo_wb_in  : in  ipb_wbus;
    fifo_wb_out : out ipb_rbus
    );
end elink_daq;

architecture behavioral of elink_daq is

  function reverse_vector (a : std_logic_vector)
    return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'REVERse_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_vector

  signal data_norev, data_rev, data,
    data_r0, data_r1, data_r2, data_r3, data_r4,
    data_r5, data_r6, data_r7, data_r8, data_r9 :
    std_logic_vector (UPWIDTH-1 downto 0) := (others => '0');

  constant DAQ_FIFO_WORDCNT_WIDTH : positive := integer(ceil(log2(real(DAQ_FIFO_DEPTH))));

  signal fifo_dout  : std_logic_vector (31 downto 0) := (others => '0');
  signal fifo_rd_en : std_logic                      := '0';
  signal fifo_wr_en : std_logic                      := '0';
  signal fifo_empty : std_logic                      := '0';
  signal fifo_valid : std_logic                      := '0';
  signal fifo_full  : std_logic                      := '0';

  signal daq_armed           : std_logic                           := '0';
  signal fifo_words_captured : integer range 0 to DAQ_FIFO_DEPTH-1 := 0;

  signal trigger    : std_logic;
  signal trig_match : boolean;

  signal fifo_din_mux : std_logic_vector (31 downto 0) := (others => '0');
  signal fifo_wen_mux : std_logic := '0';

begin

  armed <= daq_armed;
  full  <= fifo_full;
  empty <= fifo_empty;

  data_rev   <= reverse_vector(data_norev);
  data_norev <= data_i(lpgbt_sel).data(8*(elink_sel+1)-1 downto 8*elink_sel);

  trig_match <=
    ((mask9 and data_r0) = (mask9 and trig9)) and
    ((mask8 and data_r1) = (mask8 and trig8)) and
    ((mask7 and data_r2) = (mask7 and trig7)) and
    ((mask6 and data_r3) = (mask6 and trig6)) and
    ((mask5 and data_r4) = (mask5 and trig5)) and
    ((mask4 and data_r5) = (mask4 and trig4)) and
    ((mask3 and data_r6) = (mask3 and trig3)) and
    ((mask2 and data_r7) = (mask2 and trig2)) and
    ((mask1 and data_r8) = (mask1 and trig1)) and
    ((mask0 and data_r9) = (mask0 and trig0));

  trigger <= '1' when (force_trig = '1' or
                       (daq_armed = '1' and trig_match)) else '0';

  process (clk40) is
  begin
    if (rising_edge(clk40)) then

      if (fifo_wr_en = '1') then
        fifo_words_captured <= fifo_words_captured + 1;
      end if;

      -- trigger
      if (trigger = '1') then
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
      if (fifo_reset = '1') then
        daq_armed  <= '1';
        fifo_wr_en <= '0';
      end if;

    end if;
  end process;

  process (clk40) is
  begin
    if (rising_edge(clk40)) then

      if (reverse_bits = '1') then
        data <= data_rev;
      else
        data <= data_norev;
      end if;

      data_r0 <= data;
      data_r1 <= data_r0;
      data_r2 <= data_r1;
      data_r3 <= data_r2;
      data_r4 <= data_r3;
      data_r5 <= data_r4;
      data_r6 <= data_r5;
      data_r7 <= data_r6;
      data_r8 <= data_r7;
      data_r9 <= data_r8;

    end if;
  end process;

  process (clk40) is
  begin
    if (rising_edge(clk40)) then
      if (fixed_pattern = '0') then
        fifo_din_mux <= x"000000" & data_r9;
        fifo_wen_mux <= fifo_wr_en;
      else
        fifo_din_mux <= x"000000" & x"AA";
        fifo_wen_mux <= '1';
      end if;
    end if;
  end process;


  fifo_sync_inst : entity work.fifo_sync
    generic map (
      DEPTH               => DAQ_FIFO_DEPTH,
      USE_ALMOST_FULL     => 1,
      WR_WIDTH            => 32,
      RD_WIDTH            => 32,
      WR_DATA_COUNT_WIDTH => DAQ_FIFO_WORDCNT_WIDTH,
      USE_WR_DATA_COUNT   => 1
      )
    port map (
      rst           => fifo_reset,      -- Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
      clk           => clk40,
      wr_en         => fifo_wen_mux,
      rd_en         => fifo_rd_en,
      din           => fifo_din_mux,
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

  ila_elink_daq_inst : ila_elink_daq
    port map (
      clk                => clk40,
      probe0(7 downto 0) => data,
      probe1             => trigger
      );

end behavioral;
