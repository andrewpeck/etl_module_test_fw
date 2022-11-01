library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity extender is
  generic(
    LENGTH : integer   := 8;
    POL    : std_logic := '1'
    );
  port(
    clk : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic
    );
end extender;

architecture behavioral of extender is
  signal cnt : integer range 0 to LENGTH-1 := 0;
begin

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (cnt > 0 or d = '1') then
        q <= POL;
      else
        q <= not POL;
      end if;
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (d = '1') then
        cnt <= LENGTH-1;
      elsif (cnt > 0) then
        cnt <= cnt - 1;
      end if;
    end if;
  end process;

end behavioral;
