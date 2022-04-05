library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package components is

  component ila_sca
    port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(7 downto 0);
      probe1  : in std_logic_vector(7 downto 0);
      probe2  : in std_logic_vector(7 downto 0);
      probe3  : in std_logic_vector(31 downto 0);
      probe4  : in std_logic_vector(7 downto 0);
      probe5  : in std_logic_vector(7 downto 0);
      probe6  : in std_logic_vector(0 downto 0);
      probe7  : in std_logic_vector(7 downto 0);
      probe8  : in std_logic_vector(0 downto 0);
      probe9  : in std_logic_vector(0 downto 0);
      probe10 : in std_logic_vector(0 downto 0);
      probe11 : in std_logic_vector(0 downto 0);
      probe12 : in std_logic_vector(7 downto 0);
      probe13 : in std_logic_vector(7 downto 0);
      probe14 : in std_logic_vector(7 downto 0);
      probe15 : in std_logic_vector(31 downto 0);
      probe16 : in std_logic_vector(1 downto 0);
      probe17 : in std_logic_vector(1 downto 0);
      probe18 : in std_logic_vector(0 downto 0)
      );
  end component;

  component ila_sc
    port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(1 downto 0);
      probe1  : in std_logic_vector(1 downto 0);
      probe2  : in std_logic_vector(1 downto 0);
      probe3  : in std_logic_vector(1 downto 0);
      probe4  : in std_logic_vector(7 downto 0);
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

  component ila_lpgbt
    port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(223 downto 0);
      probe1  : in std_logic_vector(0 downto 0);
      probe2  : in std_logic_vector(0 downto 0);
      probe3  : in std_logic_vector(0 downto 0);
      probe4  : in std_logic_vector(0 downto 0);
      probe5  : in std_logic_vector(1 downto 0);
      probe6  : in std_logic_vector(1 downto 0);
      probe7  : in std_logic_vector(39 downto 0);
      probe8  : in std_logic_vector(39 downto 0);
      probe9  : in std_logic_vector(0 downto 0)
      );
  end component;

  component ila_elink_daq
    port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(7 downto 0);
      probe1  : in std_logic
      );
  end component;

end package components;
