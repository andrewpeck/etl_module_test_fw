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
    REPO_SHA                   :std_logic_vector(31 downto 0);  -- This is the number you want to use, the rest are confusing and useless
  end record FW_INFO_HOG_INFO_MON_t;


  type FW_INFO_MON_t is record
    HOG_INFO                   :FW_INFO_HOG_INFO_MON_t;
    UPTIME_MSBS                :std_logic_vector(31 downto 0);
    UPTIME_LSBS                :std_logic_vector(31 downto 0);
    CLK_40_FREQ                :std_logic_vector(31 downto 0);
    CLK320_FREQ                :std_logic_vector(31 downto 0);
    REFCLK_FREQ                :std_logic_vector(31 downto 0);
    IPBCLK_FREQ                :std_logic_vector(31 downto 0);
    CLK125_FREQ                :std_logic_vector(31 downto 0);
    CLK300_FREQ                :std_logic_vector(31 downto 0);
    CLKUSR_FREQ                :std_logic_vector(31 downto 0);
    TXCLK0_FREQ                :std_logic_vector(31 downto 0);
    TXCLK1_FREQ                :std_logic_vector(31 downto 0);
    TXCLK2_FREQ                :std_logic_vector(31 downto 0);
    TXCLK3_FREQ                :std_logic_vector(31 downto 0);
    TXCLK4_FREQ                :std_logic_vector(31 downto 0);
    TXCLK5_FREQ                :std_logic_vector(31 downto 0);
    TXCLK6_FREQ                :std_logic_vector(31 downto 0);
    TXCLK7_FREQ                :std_logic_vector(31 downto 0);
    TXCLK8_FREQ                :std_logic_vector(31 downto 0);
    TXCLK9_FREQ                :std_logic_vector(31 downto 0);
    RXCLK0_FREQ                :std_logic_vector(31 downto 0);
    RXCLK1_FREQ                :std_logic_vector(31 downto 0);
    RXCLK2_FREQ                :std_logic_vector(31 downto 0);
    RXCLK3_FREQ                :std_logic_vector(31 downto 0);
    RXCLK4_FREQ                :std_logic_vector(31 downto 0);
    RXCLK5_FREQ                :std_logic_vector(31 downto 0);
    RXCLK6_FREQ                :std_logic_vector(31 downto 0);
    RXCLK7_FREQ                :std_logic_vector(31 downto 0);
    RXCLK8_FREQ                :std_logic_vector(31 downto 0);
    RXCLK9_FREQ                :std_logic_vector(31 downto 0);
  end record FW_INFO_MON_t;




end package FW_INFO_CTRL;