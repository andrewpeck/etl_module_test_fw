--This file was auto-generated.
--Modifications might be lost.
library IEEE;
use IEEE.std_logic_1164.all;


package FW_INFO_CTRL is
  type FW_INFO_HOG_INFO_MON_t is record
    GLOBAL_DATE                :std_logic_vector(31 downto 0);
    GLOBAL_TIME                :std_logic_vector(31 downto 0);
    GLOBAL_VER                 :std_logic_vector(31 downto 0);
    GLOBAL_SHA                 :std_logic_vector(31 downto 0);
  end record FW_INFO_HOG_INFO_MON_t;


  type FW_INFO_MON_t is record
    HOG_INFO                   :FW_INFO_HOG_INFO_MON_t;
    UPTIME_MSBS                :std_logic_vector(31 downto 0);
    UPTIME_LSBS                :std_logic_vector(31 downto 0);
  end record FW_INFO_MON_t;




end package FW_INFO_CTRL;