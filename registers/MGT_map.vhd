--This file was auto-generated.
--Modifications might be lost.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MGT_Ctrl.all;
entity MGT_wb_interface is
  port (
    clk         : in  std_logic;
    reset       : in  std_logic;
    wb_addr     : in  std_logic_vector(31 downto 0);
    wb_wdata    : in  std_logic_vector(31 downto 0);
    wb_strobe   : in  std_logic;
    wb_write    : in  std_logic;
    wb_rdata    : out std_logic_vector(31 downto 0);
    wb_ack      : out std_logic;
    wb_err      : out std_logic;
    mon         : in  MGT_Mon_t;
    ctrl        : out MGT_Ctrl_t
    );
end entity MGT_wb_interface;
architecture behavioral of MGT_wb_interface is
  signal strobe_r : std_logic := '0';
  signal strobe_pulse : std_logic := '0';
  type slv32_array_t  is array (integer range <>) of std_logic_vector( 31 downto 0);
  signal localRdData : std_logic_vector (31 downto 0) := (others => '0');
  signal localWrData : std_logic_vector (31 downto 0) := (others => '0');
  signal reg_data :  slv32_array_t(integer range 0 to 5);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 5) := (others => x"00000000");
begin  -- architecture behavioral

  wb_rdata <= localRdData;
  localWrData <= wb_wdata;

  strobe_pulse <= '1' when (strobe='1' and strobe_r='0') else '0';
  process (clk) is
  begin
    if (rising_edge(clk)) then
      strobe_r <= strobe;
    end if;
  end process;


  -- acknowledge
  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (reset='1') then
        wb_ack  <= '0';
      else
        wb_ack  <= wb_strobe;
      end if;
    end if;
  end process;

  -- reads from slave
  reads: process (clk) is
  begin  -- process reads
    if rising_edge(clk) then  -- rising clock edge
      localRdData <= x"00000000";
      wb_err <= '0';
      if wb_strobe='1' then
        case to_integer(unsigned(wb_addr(2 downto 0))) is
          when 0 => --0x0
          localRdData( 0)            <=  reg_data( 0)( 0);                        --
          localRdData( 1)            <=  reg_data( 0)( 1);                        --
          localRdData( 2)            <=  reg_data( 0)( 2);                        --
          localRdData( 3)            <=  reg_data( 0)( 3);                        --
          localRdData( 4)            <=  reg_data( 0)( 4);                        --
          localRdData( 5)            <=  reg_data( 0)( 5);                        --
          localRdData( 6)            <=  reg_data( 0)( 6);                        --
          localRdData( 7)            <=  reg_data( 0)( 7);                        --
        when 1 => --0x1
          localRdData( 1)            <=  Mon.STATUS.USERCLK_TX_ACTIVE_OUT;        --
          localRdData( 2)            <=  Mon.STATUS.USERCLK_RX_ACTIVE_OUT;        --
          localRdData( 3)            <=  Mon.STATUS.RESET_RX_CDR_STABLE_OUT;      --
          localRdData( 4)            <=  Mon.STATUS.RESET_TX_DONE_OUT;            --
          localRdData( 5)            <=  Mon.STATUS.RESET_RX_DONE_OUT;            --
        when 2 => --0x2
          localRdData( 9 downto  0)  <=  Mon.STATUS.RXPMARESETDONE_OUT;           --
          localRdData(19 downto 10)  <=  Mon.STATUS.TXPMARESETDONE_OUT;           --
          localRdData(29 downto 20)  <=  Mon.STATUS.GTPOWERGOOD_OUT;              --
        when 4 => --0x4
          localRdData( 8 downto  0)  <=  reg_data( 4)( 8 downto  0);              --DRP Address
          localRdData(12)            <=  reg_data( 4)(12);                        --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(0).RD_RDY;                   --DRP Enable
        when 5 => --0x5
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(0).RD_DATA;                  --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data( 5)(31 downto 16);              --DRP Write Data

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;


  -- Register mapping to ctrl structures
  Ctrl.USERCLK_TX_RESET_IN           <=  reg_data( 0)( 0);               
  Ctrl.USERCLK_RX_RESET_IN           <=  reg_data( 0)( 1);               
  Ctrl.RESET_CLK_FREERUN_IN          <=  reg_data( 0)( 2);               
  Ctrl.RESET_ALL_IN                  <=  reg_data( 0)( 3);               
  Ctrl.RESET_TX_PLL_AND_DATAPATH_IN  <=  reg_data( 0)( 4);               
  Ctrl.RESET_TX_DATAPATH_IN          <=  reg_data( 0)( 5);               
  Ctrl.RESET_RX_PLL_AND_DATAPATH_IN  <=  reg_data( 0)( 6);               
  Ctrl.RESET_RX_DATAPATH_IN          <=  reg_data( 0)( 7);               
  Ctrl.DRP.DRP(0).WR_ADDR            <=  reg_data( 4)( 8 downto  0);     
  Ctrl.DRP.DRP(0).EN                 <=  reg_data( 4)(12);               
  Ctrl.DRP.DRP(0).WR_DATA            <=  reg_data( 5)(31 downto 16);     


  -- writes to slave
  reg_writes: process (clk) is
  begin  -- process reg_writes
    if (rising_edge(clk)) then  -- rising clock edge

      -- action resets
      Ctrl.DRP.DRP(0).WR_EN <= '0';
      


      -- Write on strobe=write=1
      if strobe_pulse='1' and wb_write = '1' then
        case to_integer(unsigned(wb_addr(2 downto 0))) is
        when 0 => --0x0
          reg_data( 0)( 0)            <=  localWrData( 0);                --
          reg_data( 0)( 1)            <=  localWrData( 1);                --
          reg_data( 0)( 2)            <=  localWrData( 2);                --
          reg_data( 0)( 3)            <=  localWrData( 3);                --
          reg_data( 0)( 4)            <=  localWrData( 4);                --
          reg_data( 0)( 5)            <=  localWrData( 5);                --
          reg_data( 0)( 6)            <=  localWrData( 6);                --
          reg_data( 0)( 7)            <=  localWrData( 7);                --
        when 3 => --0x3
          Ctrl.DRP.DRP(0).WR_EN       <=  localWrData( 0);               
        when 4 => --0x4
          reg_data( 4)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data( 4)(12)            <=  localWrData(12);                --DRP Enable
        when 5 => --0x5
          reg_data( 5)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data

        when others => null;

        end case;
      end if; -- write

      -- synchronous reset (active high)
      if reset = '1' then
      reg_data( 0)( 0)  <= DEFAULT_MGT_CTRL_t.USERCLK_TX_RESET_IN;
      reg_data( 0)( 1)  <= DEFAULT_MGT_CTRL_t.USERCLK_RX_RESET_IN;
      reg_data( 0)( 2)  <= DEFAULT_MGT_CTRL_t.RESET_CLK_FREERUN_IN;
      reg_data( 0)( 3)  <= DEFAULT_MGT_CTRL_t.RESET_ALL_IN;
      reg_data( 0)( 4)  <= DEFAULT_MGT_CTRL_t.RESET_TX_PLL_AND_DATAPATH_IN;
      reg_data( 0)( 5)  <= DEFAULT_MGT_CTRL_t.RESET_TX_DATAPATH_IN;
      reg_data( 0)( 6)  <= DEFAULT_MGT_CTRL_t.RESET_RX_PLL_AND_DATAPATH_IN;
      reg_data( 0)( 7)  <= DEFAULT_MGT_CTRL_t.RESET_RX_DATAPATH_IN;
      reg_data( 4)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(0).WR_ADDR;
      reg_data( 4)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(0).EN;
      reg_data( 5)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(0).WR_DATA;

      end if; -- reset
    end if; -- clk
  end process reg_writes;


end architecture behavioral;