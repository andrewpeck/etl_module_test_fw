library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.components.all;

library gbt_sc;
use gbt_sc.sca_pkg.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_Ctrl.all;

entity gbt_controller_wrapper is
  generic(
    g_CLK_FREQ       : integer := 40;
    g_SCAS_PER_LPGBT : integer := 3;
    g_DEBUG_IC       : boolean := false;
    g_DEBUG_SCA      : boolean := false
    );
  port(
    -- reset
    reset_i : in std_logic;

    ctrl_clk : in std_logic;

    mon  : out READOUT_BOARD_SC_MON_t;
    ctrl : in  READOUT_BOARD_SC_CTRL_t;

    -- master
    ic_data_i : in  std_logic_vector (1 downto 0);
    ic_data_o : out std_logic_vector (1 downto 0);

    -- sca
    sca0_data_i : in  std_logic_vector (1 downto 0);
    sca0_data_o : out std_logic_vector (1 downto 0);

    clk40   : in std_logic
    );
end gbt_controller_wrapper;

architecture common_controller of gbt_controller_wrapper is

  signal txclk, rxclk     : std_logic;
  signal txvalid, rxvalid : std_logic;

  -- master
  signal ic_data_i_int : std_logic_vector (1 downto 0);
  signal ic_data_o_int : std_logic_vector (1 downto 0);

  signal sca0_data_i_int : std_logic_vector (1 downto 0);
  signal sca0_data_o_int : std_logic_vector (1 downto 0);

  signal ic_rx_data  : std_logic_vector (7 downto 0);
  signal ic_rx_empty : std_logic;


begin


  sca_ila_gen : if (g_DEBUG_SCA) generate
    ila_sca_inst : ila_sca
      port map (
        clk                  => clk40,
        probe0(7 downto 0)   => mon.rx.rx_address,
        probe1(7 downto 0)   => mon.rx.rx_channel,
        probe2(7 downto 0)   => mon.rx.rx_control,
        probe3(31 downto 0)  => mon.rx.rx_data,
        probe4(7 downto 0)   => mon.rx.rx_err,
        probe5(7 downto 0)   => mon.rx.rx_len,
        probe6(0)            => mon.rx.rx_received,
        probe7(7 downto 0)   => mon.rx.rx_transid,
        probe8(0)            => ctrl.sca_enable,
        probe9(0)            => ctrl.start_reset,
        probe10(0)           => ctrl.start_connect,
        probe11(0)           => ctrl.inj_crc_err,
        probe12(7 downto 0)  => ctrl.tx_transid,
        probe13(7 downto 0)  => ctrl.tx_channel,
        probe14(7 downto 0)  => ctrl.tx_cmd,
        probe15(31 downto 0) => ctrl.tx_data,
        probe16(1 downto 0)  => sca0_data_o_int,
        probe17(1 downto 0)  => sca0_data_i_int,
        probe18(0)           => ctrl.start_command
        );
  end generate;

  ic_ila_gen : if (g_DEBUG_IC) generate
    ila_sc_inst : ila_sc
      port map (
        clk                  => clk40,
        probe0(1 downto 0)   => ic_data_i,
        probe1(1 downto 0)   => ic_data_o,
        probe2(1 downto 0)   => sca0_data_i,
        probe3(1 downto 0)   => sca0_data_o,
        probe4(1 downto 0)   => ic_data_i_int,
        probe5(1 downto 0)   => ic_data_o_int,
        probe6(1 downto 0)   => sca0_data_i_int,
        probe7(1 downto 0)   => sca0_data_o_int,
        probe8(0)            => '1',
        probe9(0)            => '1',
        probe10(0)           => '1',
        probe11(0)           => '1',
        probe12(0)           => reset_i,
        probe13(0)           => ctrl.rx_reset,
        probe14(0)           => ctrl.tx_reset,
        probe15(0)           => ctrl.tx_start_write,
        probe16(0)           => ctrl.tx_start_read,
        probe17(7 downto 0)  => ctrl.tx_gbtx_addr,
        probe18(15 downto 0) => ctrl.tx_register_addr,
        probe19(15 downto 0) => ctrl.tx_num_bytes_to_read,
        probe20(0)           => '1',
        probe21(0)           => ctrl.tx_wr,
        probe22(7 downto 0)  => mon.rx_data_from_gbtx,
        probe23(7 downto 0)  => ctrl.tx_data_to_gbtx,
        probe24(0)           => mon.tx_ready,
        probe25(0)           => mon.rx_empty
        );
  end generate;

  -- register inputs/outputs
  process (rxclk) is
  begin
    if (rising_edge(rxclk)) then
      ic_data_i_int   <= ic_data_i;
      sca0_data_i_int <= sca0_data_i;
    end if;
  end process;

  process (txclk) is
  begin
    if (rising_edge(txclk)) then
      ic_data_o   <= ic_data_o_int;
      sca0_data_o <= sca0_data_o_int;
    end if;
  end process;

  assert g_CLK_FREQ = 40 report "SC clk frequency must be 40MHz" severity error;

  clk40_gen : if (g_CLK_FREQ = 40) generate
    txclk   <= clk40;
    rxclk   <= clk40;
    txvalid <= '1';
    rxvalid <= '1';
  end generate;

  --------------------------------------------------------------------------------
  -- Master LPGBT (w/SCAs)
  --------------------------------------------------------------------------------

  master_gbtsc_top_inst : entity gbt_sc.gbtsc_top
    generic map (
      g_IC_FIFO_DEPTH => 8,
      g_ToLpGBT       => 1,             -- 1 = LPGBT, 0=GBTX
      g_SCA_COUNT     => g_SCAS_PER_LPGBT
      )
    port map (

      -- tx to lpgbt-fpga
      tx_clk_i  => txclk,
      tx_clk_en => txvalid,

      -- rx from lpgbt-fpga
      rx_clk_i  => rxclk,
      rx_clk_en => txvalid,

      -- IC data to/from lpgbt-fpga
      ic_data_i => ic_data_i_int,
      ic_data_o => ic_data_o_int,

      -- EC data to/from lpgbt-fpga
      ec_data_o(0) => sca0_data_o_int,
      ec_data_i(0) => sca0_data_i_int,

      -- reset
      rx_reset_i => reset_i or ctrl.rx_reset,
      tx_reset_i => reset_i or ctrl.tx_reset,

      -- initiate read/write sequences w/ lgpbt (drains FIFO)
      tx_start_write_i => ctrl.tx_start_write,
      tx_start_read_i  => ctrl.tx_start_read,

      -- read/write settings
      tx_gbtx_address_i  => ctrl.tx_gbtx_addr,
      tx_register_addr_i => ctrl.tx_register_addr,
      tx_nb_to_be_read_i => ctrl.tx_num_bytes_to_read,

      -- write into internal FIFO (on control clock domain)
      wr_clk_i          => ctrl_clk,
      tx_wr_i           => ctrl.tx_wr,
      tx_data_to_gbtx_i => ctrl.tx_data_to_gbtx,

      -- read from internal FIFO (on control clock domain)
      rd_clk_i            => ctrl_clk,
      rx_rd_i             => '1',
      rx_data_from_gbtx_o => ic_rx_data,

      -- FIFO status
      tx_ready_o => mon.tx_ready,       --! IC core ready for a transaction
      rx_empty_o => ic_rx_empty,

      -- SCA Control
      rx_address_o(0)  => mon.rx.rx_address,
      rx_channel_o(0)  => mon.rx.rx_channel,
      rx_control_o(0)  => mon.rx.rx_control,
      rx_data_o(0)     => mon.rx.rx_data,
      rx_error_o(0)    => mon.rx.rx_err,
      rx_len_o(0)      => mon.rx.rx_len,
      rx_received_o(0) => mon.rx.rx_received,
      rx_transID_o(0)  => mon.rx.rx_transID,

      sca_enable_i(0)     => ctrl.sca_enable,
      start_reset_cmd_i   => ctrl.start_reset,
      start_connect_cmd_i => ctrl.start_connect,
      start_command_i     => ctrl.start_command,
      inject_crc_error    => ctrl.inj_crc_err,
      tx_address_i        => ctrl.tx_address,
      tx_transID_i        => ctrl.tx_transID,
      tx_channel_i        => ctrl.tx_channel,
      tx_command_i        => ctrl.tx_cmd,
      tx_data_i           => ctrl.tx_data
      );

  gbt_ic_rx_1 : entity work.gbt_ic_rx
    port map (
      clock_i    => rxclk,
      reset_i    => reset_i,
      frame_i    => ic_rx_data,
      valid_i    => not ic_rx_empty,
      chip_adr_o => open,
      data_o     => mon.rx_data_from_gbtx,

      length_o             => open,
      reg_adr_o            => open,
      uplink_parity_ok_o   => open,
      downlink_parity_ok_o => open,
      err_o                => open,
      valid_o              => open
      );

end common_controller;
