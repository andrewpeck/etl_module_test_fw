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

entity etroc_fifo is
  generic(
    WIDTH : positive := 40;
    LOST_CNT_WIDTH : positive := 16;
    DEPTH : positive := 32768
    );
  port(
    clk40        : in std_logic;
    reset        : in std_logic;
    fifo_reset_i : in std_logic;

    fifo_data_i : in std_logic_vector(WIDTH-1 downto 0);
    fifo_wr_en  : in std_logic;

    lost_word_cnt : out std_logic_vector (LOST_CNT_WIDTH-1 downto 0) := (others => '0');
    full_o        : out std_logic;

    fifo_wb_in  : in  ipb_wbus;
    fifo_wb_out : out ipb_rbus
    );
end etroc_fifo;

architecture behavioral of etroc_fifo is

  signal fifo_dout  : std_logic_vector (31 downto 0) := (others => '0');
  signal fifo_rd_en : std_logic                      := '0';
  signal fifo_empty : std_logic                      := '0';
  signal fifo_valid : std_logic                      := '0';
  signal fifo_full  : std_logic                      := '0';

  signal fifo_reset_cnt : integer range 0 to 15 := 0;
  signal fifo_reset     : std_logic             := '0';

begin

  full_o <= fifo_full;

  lost_word__counter : entity work.counter
    generic map (
      width => lost_word_cnt'length
      )
    port map (
      clk    => clk40,
      reset  => reset,
      enable => '1',
      event  => fifo_full and fifo_wr_en,
      count  => lost_word_cnt,
      at_max => open
      );

  process (clk40) is
  begin
    if (rising_edge(clk40)) then

      if (fifo_reset_cnt > 0) then
        fifo_reset <= '1';
      else
        fifo_reset <= '0';
      end if;

      if (fifo_reset_i = '1') then
        fifo_reset_cnt <= 15;
      elsif (fifo_reset_cnt > 0) then
        fifo_reset_cnt <= fifo_reset_cnt - 1;
      end if;

    end if;
  end process;


  fifo_sync_inst : entity work.fifo_sync
    generic map (
      DEPTH             => DEPTH,
      USE_ALMOST_FULL   => 1,
      WR_WIDTH          => 64,
      RD_WIDTH          => 32,
      USE_WR_DATA_COUNT => 0
      )
    port map (
      rst           => fifo_reset,  -- Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
      clk           => clk40,
      wr_en         => fifo_wr_en,
      rd_en         => fifo_rd_en,
      din           => x"000000" & fifo_data_i,
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
