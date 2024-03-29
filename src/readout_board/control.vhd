library ipbus;
use ipbus.ipbus.all;
use ipbus.ipbus_decode_etl_test_fw.all;

library ctrl_lib;
use ctrl_lib.READOUT_BOARD_Ctrl.all;
use ctrl_lib.FW_INFO_Ctrl.all;
use ctrl_lib.SYSTEM_Ctrl.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity control is
  generic(
    NUM_RBS   : integer              := 8;
    EN_LPGBTS : integer range 0 to 1 := 1;
    DEBUG     : boolean              := false
    );
  port(

    reset_i : in std_logic;
    clock   : in std_logic;

    daq_ipb_w_array : out ipb_wbus_array(NUM_RBS - 1 downto 0);
    daq_ipb_r_array : in  ipb_rbus_array(NUM_RBS - 1 downto 0);

    fw_info_mon : in FW_INFO_Mon_t;

    system_mon  : in  SYSTEM_Mon_t;
    system_ctrl : out SYSTEM_Ctrl_t;

    readout_board_mon  : in  READOUT_BOARD_Mon_array_t (NUM_RBS-1 downto 0);
    readout_board_ctrl : out READOUT_BOARD_Ctrl_array_t (NUM_RBS-1 downto 0);

    pci_ipb_w : in  ipb_wbus;
    pci_ipb_r : out ipb_rbus;

    eth_ipb_w : in  ipb_wbus;
    eth_ipb_r : out ipb_rbus

    );
end control;

architecture behavioral of control is

  signal ipb_w : ipb_wbus;
  signal ipb_r : ipb_rbus;

  signal loopback : std_logic_vector (31 downto 0) := x"01234567";

  signal ipb_w_array : ipb_wbus_array(N_SLAVES - 1 downto 0);
  signal ipb_r_array : ipb_rbus_array(N_SLAVES - 1 downto 0);

  component ila_ipb
    port (
      clk    : in std_logic;
      probe0 : in std_logic_vector(31 downto 0);
      probe1 : in std_logic_vector(31 downto 0);
      probe2 : in std_logic_vector(0 downto 0);
      probe3 : in std_logic_vector(0 downto 0);
      probe4 : in std_logic_vector(31 downto 0);
      probe5 : in std_logic_vector(0 downto 0);
      probe6 : in std_logic_vector(0 downto 0)
      );
  end component;

  signal reset : std_logic := '0';

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then
      reset <= reset_i;
    end if;
  end process;


  --------------------------------------------------------------------------------
  -- arbiter to handle requests to/from 2 masters, ethernet and pcie
  --------------------------------------------------------------------------------

  ipbus_arb_inst : entity ipbus.ipbus_arb
    generic map (N_BUS => 2)
    port map (
      clk          => clock,
      rst          => reset,
      ipb_m_out(0) => eth_ipb_w,
      ipb_m_out(1) => pci_ipb_w,
      ipb_m_in(0)  => eth_ipb_r,
      ipb_m_in(1)  => pci_ipb_r,
      ipb_req(0)   => eth_ipb_w.ipb_strobe,
      ipb_req(1)   => pci_ipb_w.ipb_strobe,
      ipb_grant    => open,
      ipb_out      => ipb_w,
      ipb_in       => ipb_r
      );

  --------------------------------------------------------------------------------
  -- Special Loopback register at Adr 0...
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      ipb_r_array(N_SLV_LOOPBACK).ipb_ack <= '0';
      ipb_r_array(N_SLV_LOOPBACK).ipb_err <= '0';
      if (ipb_w_array(N_SLV_LOOPBACK).ipb_strobe) then
        ipb_r_array(N_SLV_LOOPBACK).ipb_ack <= '1';
        if (ipb_w_array(N_SLV_LOOPBACK).ipb_write) then
          loopback <= ipb_w_array(N_SLV_LOOPBACK).ipb_wdata;
        else
          ipb_r_array(N_SLV_LOOPBACK).ipb_rdata <= loopback;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- ipbus fabric selector
  --------------------------------------------------------------------------------

  fabric : entity ipbus.ipbus_fabric_sel
    generic map(
      NSLV      => N_SLAVES,
      SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in          => ipb_w,
      ipb_out         => ipb_r,
      sel             => ipbus_sel_etl_test_fw(ipb_w.ipb_addr),
      ipb_to_slaves   => ipb_w_array,
      ipb_from_slaves => ipb_r_array
      );

  --------------------------------------------------------------------------------
  -- System
  --------------------------------------------------------------------------------

  SYSTEM_wb_map : entity ctrl_lib.SYSTEM_wb_map
    port map (
      clk       => clock,
      reset     => reset,
      wb_addr   => ipb_w_array(N_SLV_SYSTEM).ipb_addr,
      wb_wdata  => ipb_w_array(N_SLV_SYSTEM).ipb_wdata,
      wb_strobe => ipb_w_array(N_SLV_SYSTEM).ipb_strobe,
      wb_write  => ipb_w_array(N_SLV_SYSTEM).ipb_write,
      wb_rdata  => ipb_r_array(N_SLV_SYSTEM).ipb_rdata,
      wb_ack    => ipb_r_array(N_SLV_SYSTEM).ipb_ack,
      wb_err    => ipb_r_array(N_SLV_SYSTEM).ipb_err,
      mon       => system_mon,
      ctrl      => system_ctrl
      );

  --------------------------------------------------------------------------------
  -- FW Info
  --------------------------------------------------------------------------------

  FW_INFO_wb_map : entity ctrl_lib.FW_INFO_wb_map
    port map (
      clk       => clock,
      reset     => reset,
      wb_addr   => ipb_w_array(N_SLV_FW_INFO).ipb_addr,
      wb_wdata  => ipb_w_array(N_SLV_FW_INFO).ipb_wdata,
      wb_strobe => ipb_w_array(N_SLV_FW_INFO).ipb_strobe,
      wb_write  => ipb_w_array(N_SLV_FW_INFO).ipb_write,
      wb_rdata  => ipb_r_array(N_SLV_FW_INFO).ipb_rdata,
      wb_ack    => ipb_r_array(N_SLV_FW_INFO).ipb_ack,
      wb_err    => ipb_r_array(N_SLV_FW_INFO).ipb_err,
      mon       => fw_info_mon
      );

  --------------------------------------------------------------------------------
  -- Readout Board
  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- ETROC DAQ
  --------------------------------------------------------------------------------

  daqgen : for I in 0 to NUM_RBS-1 generate
    constant BASE : integer := N_SLV_DAQ_RB0;
  begin
    daq_ipb_w_array(I) <= ipb_w_array(BASE+I);

    ipb_r_array(BASE+I).ipb_rdata <= daq_ipb_r_array(I).ipb_rdata;
    ipb_r_array(BASE+I).ipb_ack   <= daq_ipb_r_array(I).ipb_ack
                                         when
                                         to_integer(unsigned(ipbus_sel_etl_test_fw(ipb_w.ipb_addr)))
                                         = BASE+I
                                         else '0';
    ipb_r_array(BASE+I).ipb_err <= daq_ipb_r_array(I).ipb_err;
  end generate;

  --------------------------------------------------------------------------------
  -- Readout Boards
  --------------------------------------------------------------------------------

  rbgen : for I in 0 to NUM_RBS-1 generate
    constant BASE  : integer := N_SLV_READOUT_BOARD_0;
  begin
    rb_en : if (EN_LPGBTS = 1) generate

      READOUT_BOARD_wb_map_inst : entity ctrl_lib.READOUT_BOARD_wb_map
        port map (
          clk       => clock,
          reset     => reset,
          wb_addr   => ipb_w_array(BASE+I).ipb_addr,
          wb_wdata  => ipb_w_array(BASE+I).ipb_wdata,
          wb_strobe => ipb_w_array(BASE+I).ipb_strobe,
          wb_write  => ipb_w_array(BASE+I).ipb_write,
          wb_rdata  => ipb_r_array(BASE+I).ipb_rdata,
          wb_ack    => ipb_r_array(BASE+I).ipb_ack,
          wb_err    => ipb_r_array(BASE+I).ipb_err,
          mon       => readout_board_mon(I),
          ctrl      => readout_board_ctrl(I)
          );

      rb_debug_ilas : if (DEBUG) generate
        ila_ipb_rb_inst : ila_ipb
          port map (
            clk       => clock,
            probe0    => ipb_w_array(BASE+I).ipb_addr,
            probe1    => ipb_w_array(BASE+I).ipb_wdata,
            probe2(0) => ipb_w_array(BASE+I).ipb_strobe,
            probe3(0) => ipb_w_array(BASE+I).ipb_write,
            probe4    => ipb_r_array(BASE+I).ipb_rdata,
            probe5(0) => ipb_r_array(BASE+I).ipb_ack,
            probe6(0) => ipb_r_array(BASE+I).ipb_err
            );
      end generate;

    end generate;
  end generate;

  debug_ilas : if (DEBUG) generate

    ila_ipb_master_inst : ila_ipb
      port map (
        clk       => clock,
        probe0    => ipb_w.ipb_addr,
        probe1    => ipb_w.ipb_wdata,
        probe2(0) => ipb_w.ipb_strobe,
        probe3(0) => ipb_w.ipb_write,
        probe4    => ipb_r.ipb_rdata,
        probe5(0) => ipb_r.ipb_ack,
        probe6(0) => ipb_r.ipb_err
        );


    ila_ipb_fwinfo_inst : ila_ipb
      port map (
        clk       => clock,
        probe0    => ipb_w_array(N_SLV_FW_INFO).ipb_addr,
        probe1    => ipb_w_array(N_SLV_FW_INFO).ipb_wdata,
        probe2(0) => ipb_w_array(N_SLV_FW_INFO).ipb_strobe,
        probe3(0) => ipb_w_array(N_SLV_FW_INFO).ipb_write,
        probe4    => ipb_r_array(N_SLV_FW_INFO).ipb_rdata,
        probe5(0) => ipb_r_array(N_SLV_FW_INFO).ipb_ack,
        probe6(0) => ipb_r_array(N_SLV_FW_INFO).ipb_err
        );

  end generate;

end behavioral;
