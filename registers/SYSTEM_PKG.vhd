--This file was auto-generated.
--Modifications might be lost.
library IEEE;
use IEEE.std_logic_1164.all;


package SYSTEM_CTRL is
  type SYSTEM_MON_t is record
    L1A_RATE_CNT               :std_logic_vector(31 downto 0);  -- Measured rate of generated triggers in Hz
  end record SYSTEM_MON_t;


  type SYSTEM_CTRL_t is record
    L1A_PULSE                  :std_logic;     -- Write 1 to pulse L1A
    LINK_RESET_PULSE           :std_logic;     -- Write 1 to pulse Link reset
    L1A_RATE                   :std_logic_vector(31 downto 0);  -- Rate of generated triggers f_trig =(2^32-1) * clk_period * rate
    EN_EXT_TRIGGER             :std_logic;                      -- 1 to enable the external SMA trigger
  end record SYSTEM_CTRL_t;


  constant DEFAULT_SYSTEM_CTRL_t : SYSTEM_CTRL_t := (
                                                     L1A_PULSE => '0',
                                                     LINK_RESET_PULSE => '0',
                                                     L1A_RATE => x"00000000",
                                                     EN_EXT_TRIGGER => '0'
                                                    );


end package SYSTEM_CTRL;