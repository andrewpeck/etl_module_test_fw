--This file was auto-generated.
--Modifications might be lost.
library IEEE;
use IEEE.std_logic_1164.all;


package SYSTEM_CTRL is
  type SYSTEM_MON_t is record
    MGT_TX_READY               :std_logic_vector( 9 downto 0);
    MGT_RX_READY               :std_logic_vector( 9 downto 0);
    L1A_RATE_CNT               :std_logic_vector(31 downto 0);  -- Measured rate of generated triggers in Hz
  end record SYSTEM_MON_t;


  type SYSTEM_CTRL_t is record
    MGT_TX_RESET               :std_logic_vector( 9 downto 0);
    MGT_RX_RESET               :std_logic_vector( 9 downto 0);
    SFP0_TX_DIS                :std_logic;                      -- Controls SFP0 Disable
    SFP1_TX_DIS                :std_logic;                      -- Controls SFP1 Disable
    L1A_PULSE                  :std_logic;                      -- Write 1 to pulse L1A
    QINJ_MAKES_L1A             :std_logic;                      -- 1 for QINJ to make L1As
    L1A_DELAY                  :std_logic_vector( 8 downto 0);  -- Number of clock cycles to delay the L1A after a QINJ
    QINJ_PULSE                 :std_logic;                      -- Write 1 to pulse QINJ
    QINJ_DEADTIME              :std_logic_vector(15 downto 0);  -- Minimum deadtime between charge injections
    QINJ_RATE                  :std_logic_vector(31 downto 0);  -- Rate of generated qinj f_trig =(2^32-1) * clk_period * rate
    L1A_RATE                   :std_logic_vector(31 downto 0);  -- Rate of generated triggers f_trig =(2^32-1) * clk_period * rate
    EN_EXT_TRIGGER             :std_logic;                      -- 1 to enable the external SMA trigger
  end record SYSTEM_CTRL_t;


  constant DEFAULT_SYSTEM_CTRL_t : SYSTEM_CTRL_t := (
                                                     MGT_TX_RESET => (others => '0'),
                                                     MGT_RX_RESET => (others => '0'),
                                                     SFP0_TX_DIS => '0',
                                                     SFP1_TX_DIS => '0',
                                                     L1A_PULSE => '0',
                                                     QINJ_MAKES_L1A => '1',
                                                     L1A_DELAY => "110010000",
                                                     QINJ_PULSE => '0',
                                                     QINJ_DEADTIME => x"00ff",
                                                     QINJ_RATE => x"00000000",
                                                     L1A_RATE => x"00000000",
                                                     EN_EXT_TRIGGER => '0'
                                                    );


end package SYSTEM_CTRL;