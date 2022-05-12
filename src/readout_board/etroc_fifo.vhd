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
    DEPTH : positive := 32768
    );
  port(
    wr_clk       : in std_logic;
    rd_clk       : in std_logic;
    reset        : in std_logic;
    fifo_reset_i : in std_logic;

    fifo_data_i : in std_logic_vector(WIDTH-1 downto 0);
    fifo_wr_en  : in std_logic;

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

  process (wr_clk) is
  begin
    if (rising_edge(wr_clk)) then

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

  fifo_sync_inst : entity work.fifo_async
    generic map (
      DEPTH             => DEPTH,
      WR_WIDTH          => 64,
      RD_WIDTH          => 32,
      FIFO_READ_LATENCY => 2,
      RELATED_CLOCKS    => 1
      )
    port map (
      rst    => fifo_reset,             -- Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
      wr_clk => wr_clk,
      rd_clk => rd_clk,
      wr_en  => fifo_wr_en,
      rd_en  => fifo_rd_en,
      din    => x"000000" & fifo_data_i,
      dout   => fifo_dout,
      valid  => fifo_valid,
      full   => fifo_full,
      empty  => fifo_empty
      );

  wishbone_fifo_reader_inst : entity work.wishbone_fifo_reader
    port map (
      clk       => rd_clk,
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
