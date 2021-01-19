----------------------------------------------------------------------------------
-- Description:
--   This module slips bits to accomodate different tx frame alignments
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity frame_aligner is
  generic (
    WIDTH : integer := 8
    );
  port(
    clock : in  std_logic;
    cnt   : in  std_logic_vector(integer(ceil(log2(real(WIDTH))))-1 downto 0);
    din   : in  std_logic_vector(WIDTH-1 downto 0);
    dout  : out std_logic_vector(WIDTH-1 downto 0)
    );
end frame_aligner;

architecture behavioral of frame_aligner is

  signal buf  : std_logic_vector(WIDTH*2-1 downto 0) := (others => '0');
  signal data : std_logic_vector(WIDTH-1 downto 0)   := (others => '0');

  signal shift : integer;

begin

  shift <= to_integer(unsigned(cnt));

  process(clock)
  begin
    if (rising_edge(clock)) then
      buf  <= buf(WIDTH-1 downto 0) & din(WIDTH-1 downto 0);
      data <= buf(WIDTH-1 + shift downto shift);
    end if;
  end process;

  dout <= data;

end behavioral;
