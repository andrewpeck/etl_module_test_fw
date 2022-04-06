library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package dataformat_pkg is

  constant REVERSE                   : boolean                        := true;
  constant MAGIC_WORD                : std_logic_vector (15 downto 0) := x"3C5C";
  constant SPECIAL_BIT_INDEX         : natural                        := 39;
  constant TRAILER_SPECIAL_BIT_VALUE : std_logic                      := '0';

  constant HEADER_MAGIC : std_logic_vector (1 downto 0) := "00";
  constant FILLER_MAGIC : std_logic_vector (1 downto 0) := "10";

  -- header
  subtype BCID_RANGE is natural range 11 downto 0;
  subtype TYPE_RANGE is natural range 13 downto 12;
  subtype L1COUNTER_RANGE is natural range 21 downto 14;
  subtype HEADER_OR_FILLER_RANGE is natural range 23 downto 22;
  subtype MAGIC_RANGE is natural range 39 downto 24;

  -- data
  subtype TOT_RANGE is natural range 8 downto 0;
  subtype CAL_RANGE is natural range 18 downto 9;
  subtype TOA_RANGE is natural range 28 downto 19;
  subtype COL_ID_RANGE is natural range 32 downto 29;
  subtype ROW_ID_RANGE is natural range 36 downto 33;
  subtype EA_RANGE is natural range 38 downto 37;

  -- trailer
  subtype CRC_RANGE is natural range 7 downto 0;
  subtype HITS_RANGE is natural range 15 downto 8;
  subtype STATUS_RANGE is natural range 21 downto 16;
  subtype CHIPID_RANGE is natural range 38 downto 22;

end package dataformat_pkg;
