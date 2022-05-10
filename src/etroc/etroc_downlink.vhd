----------------------------------------------------------------------------------
-- CMS Endcap Timing Layer
-- ETROC Readout Firmware
-- A. Peck, D. Spitzbart
-- Boston University
--
-- ETROC Downlink
--
----------------------------------------------------------------------------------
-- Description:
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity etroc_downlink is
  generic(
    g_DOWNWIDTH : natural := 8 -- width in bits of a downlink (8=320 Mbps)
    );
  port(

    clock      : in std_logic;
    reset      : in std_logic;
    l1a        : in std_logic;
    bc0        : in std_logic;
    link_reset : in std_logic;

    fast_cmd_data  : in std_logic_vector (g_DOWNWIDTH-1 downto 0);
    fast_cmd_idle  : in std_logic_vector (g_DOWNWIDTH-1 downto 0);
    fast_cmd_pulse : in std_logic;


    data_o : out std_logic_vector (31 downto 0);

    -- 0 = fast command, 1 = counter, 2 = prbs, 3 = software
    dl_src : in natural range 0 to 3

    );
end etroc_downlink;

architecture behavioral of etroc_downlink is

  -- FIXME: this should concat based on g_DOWNWIDTH;
  function repeat_byte (x : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(x'length*4-1 downto 0);
  begin
    result := x & x & x & x;
    return result;
  end;

  signal counter : integer range 0 to 2**g_DOWNWIDTH-1       := 0;
  signal cnt_slv : std_logic_vector (g_DOWNWIDTH-1 downto 0) := (others => '0');

  signal fast_cmd_fw, fast_cmd_sw : std_logic_vector (g_DOWNWIDTH-1 downto 0) := (others => '0');

  signal prbs_gen         : std_logic_vector (g_DOWNWIDTH-1 downto 0) := (others => '0');
  signal prbs_gen_reverse : std_logic_vector (g_DOWNWIDTH-1 downto 0) := (others => '0');

  function reverse_vector (a : std_logic_vector)
    return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'REVERSe_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_vector

begin

  prbs_gen_reverse <= reverse_vector(prbs_gen);

  --------------------------------------------------------------------------------
  -- Downlink Data Generation
  --------------------------------------------------------------------------------

  -- up counter

  cnt_slv <= std_logic_vector (to_unsigned(counter, cnt_slv'length));

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (counter = 2**g_DOWNWIDTH-1) then
        counter <= 0;
      else
        counter <= counter + 1;
      end if;
    end if;
  end process;

  -- prbs generation

  prbs_any_gen : entity work.prbs_any
    generic map (
      chk_mode    => false,
      inv_pattern => false,
      poly_lenght => 7,
      poly_tap    => 6,
      nbits       => 8
      )
    port map (
      rst      => reset,
      clk      => clock,
      data_in  => (others => '0'),
      en       => '1',
      data_out => prbs_gen
      );

  --------------------------------------------------------------------------------
  -- lpgbt downlink multiplexing
  --------------------------------------------------------------------------------
  --
  -- Choose between different data sources
  --
  --  + up count
  --  + prbs-7 generation
  --  + programmable fast command

  process (clock) is
  begin
    if (rising_edge(clock)) then
      case dl_src is

        when 0 =>
          data_o <= repeat_byte(fast_cmd_fw);
        when 1 =>
          data_o <= repeat_byte(cnt_slv);
        when 2 =>
          data_o <= repeat_byte(prbs_gen_reverse);
        when 3 =>
          data_o <= repeat_byte(fast_cmd_sw);
        when others =>
          data_o <= repeat_byte(fast_cmd_fw);

      end case;
    end if;
  end process;

  -- Fast command pulse
  --  + make it so that the fast commands are just one pulse wide
  --    (gated by the strobe)

  fast_cmd_sw <= fast_cmd_data when fast_cmd_pulse = '1' else fast_cmd_idle;

  etroc_tx_inst : entity work.etroc_tx
    port map (
      clock      => clock,
      reset      => reset,
      l1a        => l1a,
      bc0        => bc0,
      link_reset => link_reset,
      data_o     => fast_cmd_fw
      );

end behavioral;
