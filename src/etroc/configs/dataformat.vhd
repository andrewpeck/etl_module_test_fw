library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

constant REVERSE : boolean := true;

constant HEADER_IDENTIFIER_FRAME	: std_logic_vector (39 downto 0) := x"3C5C000000";
constant HEADER_IDENTIFIER_MASK	: std_logic_vector (39 downto 0) := x"FFFFC00000";
constant DATA_IDENTIFIER_FRAME	: std_logic_vector (39 downto 0) := x"8000000000";
constant DATA_IDENTIFIER_MASK	: std_logic_vector (39 downto 0) := x"8000000000";
constant FILLER_IDENTIFIER_FRAME	: std_logic_vector (39 downto 0) := x"3C5C800000";
constant FILLER_IDENTIFIER_MASK	: std_logic_vector (39 downto 0) := x"FFFFC00000";
constant TRAILER_IDENTIFIER_FRAME	: std_logic_vector (39 downto 0) := x"0000000000";
constant TRAILER_IDENTIFIER_MASK	: std_logic_vector (39 downto 0) := x"8000000000";

package dataformat_pkg is

  -- header
  subtype BCID_RANGE is natural range 11 down to 0;
  subtype TYPE_RANGE is natural range 13 down to 12;
  subtype L1COUNTER_RANGE is natural range 21 down to 14;

  -- data
  subtype TOT_RANGE is natural range 8 down to 0;
  subtype CAL_RANGE is natural range 18 down to 9;
  subtype TOA_RANGE is natural range 29 down to 19;
  subtype COUNTER_A_RANGE is natural range 8 down to 0;
  subtype BCID_RANGE is natural range 20 down to 9;
  subtype ROW_ID2_RANGE is natural range 24 down to 21;
  subtype COL_ID2_RANGE is natural range 28 down to 25;
  subtype ROW_ID_RANGE is natural range 32 down to 29;
  subtype COL_ID_RANGE is natural range 36 down to 33;
  subtype EA_RANGE is natural range 38 down to 37;

  -- trailer
  subtype CRC_RANGE is natural range 7 down to 0;
  subtype HITS_RANGE is natural range 15 down to 8;
  subtype STATUS_RANGE is natural range 21 down to 16;
  subtype CHIPID_RANGE is natural range 38 down to 22;

end package dataformat_pkg;