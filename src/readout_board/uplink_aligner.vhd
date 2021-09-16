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

entity uplink_aligner is
  generic(
    UPWIDTH     : natural := 8;
    NUM_UPLINKS : natural := 1;
    NUM_ELINKS : natural := 28
    );
  port(
    clk40 : in std_logic;

    daq_uplink_ctrl  : in READOUT_BOARD_LPGBT_DAQ_UPLINK_CTRL_t;
    trig_uplink_ctrl : in READOUT_BOARD_LPGBT_TRIGGER_UPLINK_CTRL_t;

    data_i : in  lpgbt_uplink_data_rt_array (NUM_UPLINKS-1 downto 0);
    data_o : out lpgbt_uplink_data_rt_array (NUM_UPLINKS-1 downto 0)

    );
end uplink_aligner;

architecture behavioral of uplink_aligner is

  type align_cnt_array is array (27 downto 0) of
    std_logic_vector(integer(ceil(log2(real(UPWIDTH))))-1 downto 0);
  type align_cnt_array_2d is array (NUM_UPLINKS-1 downto 0) of align_cnt_array;
  signal align_cnts : align_cnt_array_2d;

begin


  align_cnts(0)(0)  <= daq_uplink_ctrl.align_0;
  align_cnts(0)(1)  <= daq_uplink_ctrl.align_1;
  align_cnts(0)(2)  <= daq_uplink_ctrl.align_2;
  align_cnts(0)(3)  <= daq_uplink_ctrl.align_3;
  align_cnts(0)(4)  <= daq_uplink_ctrl.align_4;
  align_cnts(0)(5)  <= daq_uplink_ctrl.align_5;
  align_cnts(0)(6)  <= daq_uplink_ctrl.align_6;
  align_cnts(0)(7)  <= daq_uplink_ctrl.align_7;
  align_cnts(0)(8)  <= daq_uplink_ctrl.align_8;
  align_cnts(0)(9)  <= daq_uplink_ctrl.align_9;
  align_cnts(0)(10) <= daq_uplink_ctrl.align_10;
  align_cnts(0)(11) <= daq_uplink_ctrl.align_11;
  align_cnts(0)(12) <= daq_uplink_ctrl.align_12;
  align_cnts(0)(13) <= daq_uplink_ctrl.align_13;
  align_cnts(0)(14) <= daq_uplink_ctrl.align_14;
  align_cnts(0)(15) <= daq_uplink_ctrl.align_15;
  align_cnts(0)(16) <= daq_uplink_ctrl.align_16;
  align_cnts(0)(17) <= daq_uplink_ctrl.align_17;
  align_cnts(0)(18) <= daq_uplink_ctrl.align_18;
  align_cnts(0)(19) <= daq_uplink_ctrl.align_19;
  align_cnts(0)(20) <= daq_uplink_ctrl.align_20;
  align_cnts(0)(21) <= daq_uplink_ctrl.align_21;
  align_cnts(0)(22) <= daq_uplink_ctrl.align_22;
  align_cnts(0)(23) <= daq_uplink_ctrl.align_23;
  align_cnts(0)(24) <= daq_uplink_ctrl.align_24;
  align_cnts(0)(25) <= daq_uplink_ctrl.align_25;
  align_cnts(0)(26) <= daq_uplink_ctrl.align_26;
  align_cnts(0)(27) <= daq_uplink_ctrl.align_27;

  align_cnts(1)(0)  <= trig_uplink_ctrl.align_0;
  align_cnts(1)(1)  <= trig_uplink_ctrl.align_1;
  align_cnts(1)(2)  <= trig_uplink_ctrl.align_2;
  align_cnts(1)(3)  <= trig_uplink_ctrl.align_3;
  align_cnts(1)(4)  <= trig_uplink_ctrl.align_4;
  align_cnts(1)(5)  <= trig_uplink_ctrl.align_5;
  align_cnts(1)(6)  <= trig_uplink_ctrl.align_6;
  align_cnts(1)(7)  <= trig_uplink_ctrl.align_7;
  align_cnts(1)(8)  <= trig_uplink_ctrl.align_8;
  align_cnts(1)(9)  <= trig_uplink_ctrl.align_9;
  align_cnts(1)(10) <= trig_uplink_ctrl.align_10;
  align_cnts(1)(11) <= trig_uplink_ctrl.align_11;
  align_cnts(1)(12) <= trig_uplink_ctrl.align_12;
  align_cnts(1)(13) <= trig_uplink_ctrl.align_13;
  align_cnts(1)(14) <= trig_uplink_ctrl.align_14;
  align_cnts(1)(15) <= trig_uplink_ctrl.align_15;
  align_cnts(1)(16) <= trig_uplink_ctrl.align_16;
  align_cnts(1)(17) <= trig_uplink_ctrl.align_17;
  align_cnts(1)(18) <= trig_uplink_ctrl.align_18;
  align_cnts(1)(19) <= trig_uplink_ctrl.align_19;
  align_cnts(1)(20) <= trig_uplink_ctrl.align_20;
  align_cnts(1)(21) <= trig_uplink_ctrl.align_21;
  align_cnts(1)(22) <= trig_uplink_ctrl.align_22;
  align_cnts(1)(23) <= trig_uplink_ctrl.align_23;
  align_cnts(1)(24) <= trig_uplink_ctrl.align_24;
  align_cnts(1)(25) <= trig_uplink_ctrl.align_25;
  align_cnts(1)(26) <= trig_uplink_ctrl.align_26;
  align_cnts(1)(27) <= trig_uplink_ctrl.align_27;

  uplink_aligners_lpgbtloop : for I in 0 to NUM_UPLINKS-1 generate
    uplink_aligners_linkloop : for J in 0 to NUM_ELINKS-1 generate
      signal align_cnt : std_logic_vector (integer(ceil(log2(real(UPWIDTH))))-1 downto 0);

      -- don't care about bus coherence here..
      -- switching doesn't need to be glitchless
      attribute ASYNC_REG              : string;
      attribute ASYNC_REG of align_cnt : signal is "true";

    begin

      process (clk40) is
      begin
        if (rising_edge(clk40)) then
          align_cnt <= align_cnts (I)(J);
        end if;
      end process;

      frame_aligner_inst : entity work.frame_aligner
        generic map (WIDTH => UPWIDTH)
        port map (
          clock => clk40,
          cnt   => align_cnt,
          din   => data_i(I).data(UPWIDTH*(J+1)-1 downto UPWIDTH*J),
          dout  => data_o(I).data(UPWIDTH*(J+1)-1 downto UPWIDTH*J)
          );

    end generate;
  end generate;

end behavioral;
