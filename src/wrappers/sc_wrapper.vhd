library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library gbt_sc;
use gbt_sc.sca_pkg.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_Ctrl.all;

entity gbt_controller_wrapper is
  generic(
    g_CLK_FREQ       : integer := 40;
    g_SCAS_PER_LPGBT : integer := 3
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

    clk320  : in std_logic;
    clk40   : in std_logic;
    valid_i : in std_logic
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

  component ila_sc
    port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(1 downto 0);
      probe1  : in std_logic_vector(1 downto 0);
      probe2  : in std_logic_vector(1 downto 0);
      probe3  : in std_logic_vector(1 downto 0);
      probe4  : in std_logic_vector(1 downto 0);
      probe5  : in std_logic_vector(1 downto 0);
      probe6  : in std_logic_vector(1 downto 0);
      probe7  : in std_logic_vector(1 downto 0);
      probe8  : in std_logic_vector(0 downto 0);
      probe9  : in std_logic_vector(0 downto 0);
      probe10 : in std_logic_vector(0 downto 0);
      probe11 : in std_logic_vector(0 downto 0);
      probe12 : in std_logic_vector(0 downto 0);
      probe13 : in std_logic_vector(0 downto 0);
      probe14 : in std_logic_vector(0 downto 0);
      probe15 : in std_logic_vector(0 downto 0);
      probe16 : in std_logic_vector(0 downto 0);
      probe17 : in std_logic_vector(7 downto 0);
      probe18 : in std_logic_vector(15 downto 0);
      probe19 : in std_logic_vector(15 downto 0);
      probe20 : in std_logic_vector(0 downto 0);
      probe21 : in std_logic_vector(0 downto 0);
      probe22 : in std_logic_vector(7 downto 0);
      probe23 : in std_logic_vector(7 downto 0);
      probe24 : in std_logic_vector(0 downto 0);
      probe25 : in std_logic_vector(0 downto 0)
      );
  end component;

begin

  -- ila_sc_inst : ila_sc
  --   port map (
  --     clk                  => clk40,
  --     probe0(1 downto 0)   => ic_data_i,
  --     probe1(1 downto 0)   => ic_data_o,
  --     probe2(1 downto 0)   => sca0_data_i,
  --     probe3(1 downto 0)   => sca0_data_o,
  --     probe4(1 downto 0)   => ic_data_i_int,
  --     probe5(1 downto 0)   => ic_data_o_int,
  --     probe6(1 downto 0)   => sca0_data_i_int,
  --     probe7(1 downto 0)   => sca0_data_o_int,
  --     probe8(0)            => valid_i,
  --     probe9(0)            => '1',
  --     probe10(0)           => '1',
  --     probe11(0)           => '1',
  --     probe12(0)           => reset_i,
  --     probe13(0)           => ctrl.rx_reset,
  --     probe14(0)           => ctrl.tx_reset,
  --     probe15(0)           => ctrl.tx_start_write,
  --     probe16(0)           => ctrl.tx_start_read,
  --     probe17(7 downto 0)  => ctrl.tx_gbtx_addr,
  --     probe18(15 downto 0) => ctrl.tx_register_addr,
  --     probe19(15 downto 0) => ctrl.tx_num_bytes_to_read,
  --     probe20(0)           => ctrl.rx_rd,
  --     probe21(0)           => ctrl.tx_wr,
  --     probe22(7 downto 0)  => mon.rx_data_from_gbtx,
  --     probe23(7 downto 0)  => ctrl.tx_data_to_gbtx,
  --     probe24(0)           => mon.tx_ready,
  --     probe25(0)           => mon.rx_empty
  --     );

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

  clk40_gen : if (g_CLK_FREQ = 40) generate
    txclk   <= clk40;
    rxclk   <= clk40;
    txvalid <= '1';
    rxvalid <= '1';
  end generate;

  clk320_gen : if (g_CLK_FREQ = 320) generate
    txclk   <= clk320;
    rxclk   <= clk320;
    txvalid <= valid_i;
    rxvalid <= valid_i;
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
      rx_rd_i             => ctrl.rx_rd,
      rx_data_from_gbtx_o => mon.rx_data_from_gbtx,

      -- FIFO status
      tx_ready_o => mon.tx_ready,       --! IC core ready for a transaction
      rx_empty_o => mon.rx_empty,

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

end common_controller;
