library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package dataformat_pkg is

  constant REVERSE : boolean := true;

  constant HEADER_IDENTIFIER_FRAME  : std_logic_vector (39 downto 0) := x"3C5C000000";
  constant HEADER_IDENTIFIER_MASK   : std_logic_vector (39 downto 0) := x"FFFFC00000";
  constant FILLER_IDENTIFIER_FRAME  : std_logic_vector (39 downto 0) := x"3C5C800000";
  constant FILLER_IDENTIFIER_MASK   : std_logic_vector (39 downto 0) := x"FFFFC00000";
  constant TRAILER_IDENTIFIER_FRAME : std_logic_vector (39 downto 0) := x"0000000000";
  constant TRAILER_IDENTIFIER_MASK  : std_logic_vector (39 downto 0) := x"8000000000";
  constant DATA_IDENTIFIER_FRAME    : std_logic_vector (39 downto 0) := x"8000000000";
  constant DATA_IDENTIFIER_MASK     : std_logic_vector (39 downto 0) := x"8000000000";

  -- header
  subtype BCID_RANGE is natural range 11 downto 0;
  subtype TYPE_RANGE is natural range 13 downto 12;
  subtype L1COUNTER_RANGE is natural range 21 downto 14;

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
