--This file was auto-generated.
--Modifications might be lost.
library IEEE;
use IEEE.std_logic_1164.all;


package MGT_CTRL is
  type MGT_STATUS_MON_t is record
    USERCLK_TX_ACTIVE_OUT      :std_logic;   
    USERCLK_RX_ACTIVE_OUT      :std_logic;   
    RESET_RX_CDR_STABLE_OUT    :std_logic;   
    RESET_TX_DONE_OUT          :std_logic;   
    RESET_RX_DONE_OUT          :std_logic;   
    RXPMARESETDONE_OUT         :std_logic_vector( 9 downto 0);
    TXPMARESETDONE_OUT         :std_logic_vector( 9 downto 0);
    GTPOWERGOOD_OUT            :std_logic_vector( 9 downto 0);
  end record MGT_STATUS_MON_t;


  type MGT_DRP_DRP_MON_t is record
    RD_RDY                     :std_logic;     -- DRP Enable
    RD_DATA                    :std_logic_vector(15 downto 0);  -- DRP Read Data
  end record MGT_DRP_DRP_MON_t;
  type MGT_DRP_DRP_MON_t_ARRAY is array(0 to 0) of MGT_DRP_DRP_MON_t;

  type MGT_DRP_DRP_CTRL_t is record
    WR_EN                      :std_logic;     -- DRP Write Enable
    WR_ADDR                    :std_logic_vector( 8 downto 0);  -- DRP Address
    EN                         :std_logic;                      -- DRP Enable
    WR_DATA                    :std_logic_vector(15 downto 0);  -- DRP Write Data
  end record MGT_DRP_DRP_CTRL_t;
  type MGT_DRP_DRP_CTRL_t_ARRAY is array(0 to 0) of MGT_DRP_DRP_CTRL_t;

  constant DEFAULT_MGT_DRP_DRP_CTRL_t : MGT_DRP_DRP_CTRL_t := (
                                                               WR_EN => '0',
                                                               WR_ADDR => (others => '0'),
                                                               EN => '0',
                                                               WR_DATA => (others => '0')
                                                              );
  type MGT_DRP_MON_t is record
    DRP                        :MGT_DRP_DRP_MON_t_ARRAY;
  end record MGT_DRP_MON_t;


  type MGT_DRP_CTRL_t is record
    DRP                        :MGT_DRP_DRP_CTRL_t_ARRAY;
  end record MGT_DRP_CTRL_t;


  constant DEFAULT_MGT_DRP_CTRL_t : MGT_DRP_CTRL_t := (
                                                       DRP => (others => DEFAULT_MGT_DRP_DRP_CTRL_t )
                                                      );
  type MGT_MON_t is record
    STATUS                     :MGT_STATUS_MON_t;
    DRP                        :MGT_DRP_MON_t;   
  end record MGT_MON_t;


  type MGT_CTRL_t is record
    USERCLK_TX_RESET_IN        :std_logic;   
    USERCLK_RX_RESET_IN        :std_logic;   
    RESET_CLK_FREERUN_IN       :std_logic;   
    RESET_ALL_IN               :std_logic;   
    RESET_TX_PLL_AND_DATAPATH_IN  :std_logic;   
    RESET_TX_DATAPATH_IN          :std_logic;   
    RESET_RX_PLL_AND_DATAPATH_IN  :std_logic;   
    RESET_RX_DATAPATH_IN          :std_logic;   
    DRP                           :MGT_DRP_CTRL_t;
  end record MGT_CTRL_t;


  constant DEFAULT_MGT_CTRL_t : MGT_CTRL_t := (
                                               USERCLK_TX_RESET_IN => '0',
                                               USERCLK_RX_RESET_IN => '0',
                                               RESET_CLK_FREERUN_IN => '0',
                                               RESET_ALL_IN => '0',
                                               RESET_TX_PLL_AND_DATAPATH_IN => '0',
                                               RESET_TX_DATAPATH_IN => '0',
                                               RESET_RX_PLL_AND_DATAPATH_IN => '0',
                                               RESET_RX_DATAPATH_IN => '0',
                                               DRP => DEFAULT_MGT_DRP_CTRL_t
                                              );


end package MGT_CTRL;