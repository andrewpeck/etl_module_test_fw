--This file was auto-generated.
--Modifications might be lost.
library IEEE;
use IEEE.std_logic_1164.all;


package MGT_CTRL is
  type MGT_DRP_DRP_MON_t is record
    RD_RDY                     :std_logic;     -- DRP Enable
    RD_DATA                    :std_logic_vector(15 downto 0);  -- DRP Read Data
  end record MGT_DRP_DRP_MON_t;
  type MGT_DRP_DRP_MON_t_ARRAY is array(0 to 9) of MGT_DRP_DRP_MON_t;

  type MGT_DRP_DRP_CTRL_t is record
    WR_EN                      :std_logic;     -- DRP Write Enable
    WR_ADDR                    :std_logic_vector( 8 downto 0);  -- DRP Address
    EN                         :std_logic;                      -- DRP Enable
    WR_DATA                    :std_logic_vector(15 downto 0);  -- DRP Write Data
  end record MGT_DRP_DRP_CTRL_t;
  type MGT_DRP_DRP_CTRL_t_ARRAY is array(0 to 9) of MGT_DRP_DRP_CTRL_t;

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
    MGT_TX_READY               :std_logic_vector( 9 downto 0);
    MGT_RX_READY               :std_logic_vector( 9 downto 0);
    DRP                        :MGT_DRP_MON_t;                
  end record MGT_MON_t;


  type MGT_CTRL_t is record
    MGT_TX_RESET               :std_logic_vector( 9 downto 0);
    MGT_RX_RESET               :std_logic_vector( 9 downto 0);
    DRP                        :MGT_DRP_CTRL_t;               
    SFP0_TX_DIS                :std_logic;                      -- Controls SFP0 Disable
    SFP1_TX_DIS                :std_logic;                      -- Controls SFP1 Disable
  end record MGT_CTRL_t;


  constant DEFAULT_MGT_CTRL_t : MGT_CTRL_t := (
                                               MGT_TX_RESET => (others => '0'),
                                               MGT_RX_RESET => (others => '0'),
                                               DRP => DEFAULT_MGT_DRP_CTRL_t,
                                               SFP0_TX_DIS => '0',
                                               SFP1_TX_DIS => '0'
                                              );


end package MGT_CTRL;