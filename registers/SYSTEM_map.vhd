--This file was auto-generated.
--Modifications might be lost.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SYSTEM_Ctrl.all;
entity SYSTEM_wb_map is
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
    mon         : in  SYSTEM_Mon_t;
    ctrl        : out SYSTEM_Ctrl_t
    );
end entity SYSTEM_wb_map;
architecture behavioral of SYSTEM_wb_map is
  signal strobe_r : std_logic := '0';
  signal strobe_pulse : std_logic := '0';
  type slv32_array_t  is array (integer range <>) of std_logic_vector( 31 downto 0);
  signal localRdData : std_logic_vector (31 downto 0) := (others => '0');
  signal localWrData : std_logic_vector (31 downto 0) := (others => '0');
  signal reg_data :  slv32_array_t(integer range 0 to 1287);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 1287) := (others => x"00000000");
begin  -- architecture behavioral

  wb_rdata <= localRdData;
  localWrData <= wb_wdata;

  strobe_pulse <= '1' when (wb_strobe='1' and strobe_r='0') else '0';
  process (clk) is
  begin
    if (rising_edge(clk)) then
      strobe_r <= wb_strobe;
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
        case to_integer(unsigned(wb_addr(10 downto 0))) is
          when 0 => --0x0
          localRdData( 9 downto  0)  <=  reg_data( 0)( 9 downto  0);        --
          localRdData(21 downto 12)  <=  reg_data( 0)(21 downto 12);        --
        when 1 => --0x1
          localRdData( 9 downto  0)  <=  Mon.MGT_TX_READY;                  --
          localRdData(21 downto 12)  <=  Mon.MGT_RX_READY;                  --
        when 64 => --0x40
          localRdData( 0)            <=  reg_data(64)( 0);                  --Controls SFP0 Disable
          localRdData( 1)            <=  reg_data(64)( 1);                  --Controls SFP1 Disable
        when 1280 => --0x500
          localRdData( 2)            <=  reg_data(1280)( 2);                --1 for QINJ to make L1As
          localRdData(11 downto  3)  <=  reg_data(1280)(11 downto  3);      --Number of clock cycles to delay the L1A after a QINJ
          localRdData(31 downto 16)  <=  reg_data(1280)(31 downto 16);      --Minimum deadtime between charge injections
        when 1281 => --0x501
          localRdData(31 downto  0)  <=  reg_data(1281)(31 downto  0);      --Rate of generated qinj f_trig =(2^32-1) * clk_period * rate
        when 1282 => --0x502
          localRdData(31 downto  0)  <=  reg_data(1282)(31 downto  0);      --Rate of generated triggers f_trig =(2^32-1) * clk_period * rate
        when 1283 => --0x503
          localRdData(31 downto  0)  <=  Mon.L1A_RATE_CNT;                  --Measured rate of generated triggers in Hz
        when 1287 => --0x507
          localRdData( 0)            <=  reg_data(1287)( 0);                --1 to enable the external SMA trigger

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;


  -- Register mapping to ctrl structures
  Ctrl.MGT_TX_RESET    <=  reg_data( 0)( 9 downto  0);       
  Ctrl.MGT_RX_RESET    <=  reg_data( 0)(21 downto 12);       
  Ctrl.SFP0_TX_DIS     <=  reg_data(64)( 0);                 
  Ctrl.SFP1_TX_DIS     <=  reg_data(64)( 1);                 
  Ctrl.QINJ_MAKES_L1A  <=  reg_data(1280)( 2);               
  Ctrl.L1A_DELAY       <=  reg_data(1280)(11 downto  3);     
  Ctrl.QINJ_DEADTIME   <=  reg_data(1280)(31 downto 16);     
  Ctrl.QINJ_RATE       <=  reg_data(1281)(31 downto  0);     
  Ctrl.L1A_RATE        <=  reg_data(1282)(31 downto  0);     
  Ctrl.EN_EXT_TRIGGER  <=  reg_data(1287)( 0);               


  -- writes to slave
  reg_writes: process (clk) is
  begin  -- process reg_writes
    if (rising_edge(clk)) then  -- rising clock edge

      -- action resets
      Ctrl.L1A_PULSE <= '0';
      Ctrl.QINJ_PULSE <= '0';
      


      -- Write on strobe=write=1
      if strobe_pulse='1' and wb_write = '1' then
        case to_integer(unsigned(wb_addr(10 downto 0))) is
        when 0 => --0x0
          reg_data( 0)( 9 downto  0)    <=  localWrData( 9 downto  0);      --
          reg_data( 0)(21 downto 12)    <=  localWrData(21 downto 12);      --
        when 64 => --0x40
          reg_data(64)( 0)              <=  localWrData( 0);                --Controls SFP0 Disable
          reg_data(64)( 1)              <=  localWrData( 1);                --Controls SFP1 Disable
        when 1280 => --0x500
          Ctrl.L1A_PULSE                <=  localWrData( 0);               
          Ctrl.QINJ_PULSE               <=  localWrData(12);               
          reg_data(1280)( 2)            <=  localWrData( 2);                --1 for QINJ to make L1As
          reg_data(1280)(11 downto  3)  <=  localWrData(11 downto  3);      --Number of clock cycles to delay the L1A after a QINJ
          reg_data(1280)(31 downto 16)  <=  localWrData(31 downto 16);      --Minimum deadtime between charge injections
        when 1281 => --0x501
          reg_data(1281)(31 downto  0)  <=  localWrData(31 downto  0);      --Rate of generated qinj f_trig =(2^32-1) * clk_period * rate
        when 1282 => --0x502
          reg_data(1282)(31 downto  0)  <=  localWrData(31 downto  0);      --Rate of generated triggers f_trig =(2^32-1) * clk_period * rate
        when 1287 => --0x507
          reg_data(1287)( 0)            <=  localWrData( 0);                --1 to enable the external SMA trigger

        when others => null;

        end case;
      end if; -- write

      -- synchronous reset (active high)
      if reset = '1' then
      reg_data( 0)( 9 downto  0)  <= DEFAULT_SYSTEM_CTRL_t.MGT_TX_RESET;
      reg_data( 0)(21 downto 12)  <= DEFAULT_SYSTEM_CTRL_t.MGT_RX_RESET;
      reg_data(64)( 0)  <= DEFAULT_SYSTEM_CTRL_t.SFP0_TX_DIS;
      reg_data(64)( 1)  <= DEFAULT_SYSTEM_CTRL_t.SFP1_TX_DIS;
      reg_data(1280)( 0)  <= DEFAULT_SYSTEM_CTRL_t.L1A_PULSE;
      reg_data(1280)( 2)  <= DEFAULT_SYSTEM_CTRL_t.QINJ_MAKES_L1A;
      reg_data(1280)(11 downto  3)  <= DEFAULT_SYSTEM_CTRL_t.L1A_DELAY;
      reg_data(1280)(12)  <= DEFAULT_SYSTEM_CTRL_t.QINJ_PULSE;
      reg_data(1280)(31 downto 16)  <= DEFAULT_SYSTEM_CTRL_t.QINJ_DEADTIME;
      reg_data(1281)(31 downto  0)  <= DEFAULT_SYSTEM_CTRL_t.QINJ_RATE;
      reg_data(1282)(31 downto  0)  <= DEFAULT_SYSTEM_CTRL_t.L1A_RATE;
      reg_data(1287)( 0)  <= DEFAULT_SYSTEM_CTRL_t.EN_EXT_TRIGGER;

      end if; -- reset
    end if; -- clk
  end process reg_writes;


end architecture behavioral;