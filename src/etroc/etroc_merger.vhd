----------------------------------------------------------------------------------
-- CMS Endcap Timing Layer
-- ETROC Readout Firmware
-- A. Peck, D. Spitzbart
-- Boston University
--
-- ETROC Data Merger
--
----------------------------------------------------------------------------------
-- Description:
--
-- This module is responsible for taking in data from many ETROCs and merging
-- them into a single data-stream which can be connected to a FIFO
--
-- It is designed to operate with multiple clocks so that the ETROC clock (40
-- MHz) can be slow compared to the DAQ clock (e.g. 320 MHz).
--
-- The maximum "aspect ratio" for the # of inputs that can be handled depends on
-- the expected data rate. The load should be balanced appropriately.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity etroc_merger is
  generic(
    g_NUM_ETROCS  : natural := 24;
    g_FRAME_WIDTH : natural := 40;
    g_ELINK_WIDTH : natural := 8
    );
  port(

    clk_etroc : in std_logic;
    clk_daq   : in std_logic;
    reset     : in std_logic;

    data_i : in std_logic_vector (g_NUM_ETROCS*g_ELINK_WIDTH-1 downto 0);

    data_o  : out std_logic_vector (g_FRAME_WIDTH-1 downto 0);
    valid_o : out std_logic

    );
end etroc_merger;

architecture behavioral of etroc_merger is

  type etroc_data_array_t is array (integer range <>) of
    std_logic_vector(g_FRAME_WIDTH-1 downto 0);

  signal daq_sel : natural range 0 to g_NUM_ETROCS-1;

  signal etroc_busy  : std_logic_vector(g_NUM_ETROCS-1 downto 0);
  signal etroc_empty : std_logic_vector(g_NUM_ETROCS-1 downto 0);
  signal etroc_valid : std_logic_vector(g_NUM_ETROCS-1 downto 0);
  signal etroc_rden  : std_logic_vector(g_NUM_ETROCS-1 downto 0);

  signal etroc_data_to_fifo   : etroc_data_array_t (g_NUM_ETROCS-1 downto 0);
  signal etroc_data_from_fifo : etroc_data_array_t (g_NUM_ETROCS-1 downto 0);

  signal etroc_data : std_logic_vector (g_FRAME_WIDTH-1 downto 0) := (others => '0');

  -- signal rx_frame_mon  : std_logic_vector (g_FRAME_WIDTH-1 downto 0) := (others => '0');

  -- signal rx_start_of_packet : std_logic_vector(g_NUM_ETROCS-1 downto 0);
  -- signal rx_end_of_packet   : std_logic_vector(g_NUM_ETROCS-1 downto 0);

begin


  etroc_rx_gen : for I in 0 to g_NUM_ETROCS-1 generate

    signal valid : std_logic;

    signal elink_i : std_logic_vector (31 downto 0) := (others => '0');
    signal frame   : std_logic_vector (g_FRAME_WIDTH-1 downto 0);

    constant bithi : natural := g_ELINK_WIDTH*I;
    constant bitlo : natural := g_ELINK_WIDTH*(I+1)-1;

    function elink_width_set (width : natural) return std_logic_vector is
    begin
      if (width = 8) then
        return "010";
      elsif (width = 16) then
        return "011";
      elsif (width = 32) then
        return "100";
      else
        assert true report "Invalid elink width selected" severity error;
      end if;
    end;

    -- runtime configuration: 0:2, 1:4, 2:8, 3:16, 4:32
    constant ELINK_WIDTH : std_logic_vector(2 downto 0) := elink_width_set(g_ELINK_WIDTH);

  begin

    -- etroc_rx x24 --> etroc_fifo x24 --> dumb_daq x1 --> wishbone fifo

    --------------------------------------------------------------------------------
    -- Data Decoder
    --------------------------------------------------------------------------------

    elink_i <= std_logic_vector(resize(unsigned(data_i(bithi downto bitlo)), 32));

    etroc_rx_inst : entity work.etroc_rx
      port map (
        clock             => clk_etroc,
        elinkwidth        => ELINK_WIDTH,
        reset             => reset,
        data_i            => elink_i,
        bitslip_i         => '0',       -- use auto-bitslip
        fifo_wr_en_o      => valid,
        fifo_data_o       => etroc_data_to_fifo(I),
        frame_mon_o       => open,
        bcid_o            => open,
        type_o            => open,
        event_cnt_o       => open,
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
        chip_id_o         => open,
        start_of_packet_o => open,
        end_of_packet_o   => open,
        err_o             => open,
        busy_o            => etroc_busy(I),
        idle_o            => open
        );

    etroc_fifo_inst : entity work.fifo_async
      generic map (
        DEPTH          => 1024,
        WR_WIDTH       => 40,
        RD_WIDTH       => 40,
        RELATED_CLOCKS => 1
        )
      port map (
        rst => reset,

        -- write
        wr_clk => clk_etroc,
        wr_en  => valid,
        din    => etroc_data_to_fifo(I),

        -- read
        rd_en  => etroc_rden(I),
        rd_clk => clk_daq,
        dout   => etroc_data_from_fifo(I),
        valid  => valid,
        full   => open,                 -- FIXME: should monitor overflows
        empty  => etroc_empty(I)
        );

  end generate;

  etroc_data <= etroc_data_from_fifo(daq_sel);

  etroc_selector_inst : entity work.etroc_selector
    generic map (
      g_NUM_INPUTS => g_NUM_ETROCS,
      g_WIDTH      => 40
      )
    port map (
      clock    => clk_daq,
      reset_i  => reset,
      data_i   => etroc_data,
      data_sel => daq_sel,
      busy_i   => etroc_busy,
      empty_i  => etroc_empty,
      valid_i  => etroc_valid,
      rd_en_o  => etroc_rden,
      data_o   => data_o,
      wr_en_o  => valid_o
      );

end behavioral;
