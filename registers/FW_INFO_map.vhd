--This file was auto-generated.
--Modifications might be lost.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.FW_INFO_Ctrl.all;
entity FW_INFO_wb_map is
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
    mon         : in  FW_INFO_Mon_t
    );
end entity FW_INFO_wb_map;
architecture behavioral of FW_INFO_wb_map is
  signal strobe_r : std_logic := '0';
  signal strobe_pulse : std_logic := '0';
  type slv32_array_t  is array (integer range <>) of std_logic_vector( 31 downto 0);
  signal localRdData : std_logic_vector (31 downto 0) := (others => '0');
  signal localWrData : std_logic_vector (31 downto 0) := (others => '0');
  signal reg_data :  slv32_array_t(integer range 0 to 33);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 33) := (others => x"00000000");
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
        case to_integer(unsigned(wb_addr(5 downto 0))) is
          when 0 => --0x0
          localRdData(31 downto  0)  <=  Mon.HOG_INFO.GLOBAL_DATE;      --
        when 1 => --0x1
          localRdData(31 downto  0)  <=  Mon.HOG_INFO.GLOBAL_TIME;      --
        when 2 => --0x2
          localRdData(31 downto  0)  <=  Mon.HOG_INFO.GLOBAL_VER;       --
        when 3 => --0x3
          localRdData(31 downto  0)  <=  Mon.HOG_INFO.GLOBAL_SHA;       --
        when 5 => --0x5
          localRdData(31 downto  0)  <=  Mon.UPTIME_MSBS;               --
        when 6 => --0x6
          localRdData(31 downto  0)  <=  Mon.UPTIME_LSBS;               --
        when 7 => --0x7
          localRdData(31 downto  0)  <=  Mon.CLK_40_FREQ;               --
        when 8 => --0x8
          localRdData(31 downto  0)  <=  Mon.CLK320_FREQ;               --
        when 9 => --0x9
          localRdData(31 downto  0)  <=  Mon.REFCLK_FREQ;               --
        when 10 => --0xa
          localRdData(31 downto  0)  <=  Mon.IPBCLK_FREQ;               --
        when 11 => --0xb
          localRdData(31 downto  0)  <=  Mon.CLK125_FREQ;               --
        when 12 => --0xc
          localRdData(31 downto  0)  <=  Mon.CLK300_FREQ;               --
        when 13 => --0xd
          localRdData(31 downto  0)  <=  Mon.CLKUSR_FREQ;               --
        when 14 => --0xe
          localRdData(31 downto  0)  <=  Mon.TXCLK0_FREQ;               --
        when 15 => --0xf
          localRdData(31 downto  0)  <=  Mon.TXCLK1_FREQ;               --
        when 16 => --0x10
          localRdData(31 downto  0)  <=  Mon.TXCLK2_FREQ;               --
        when 17 => --0x11
          localRdData(31 downto  0)  <=  Mon.TXCLK3_FREQ;               --
        when 18 => --0x12
          localRdData(31 downto  0)  <=  Mon.TXCLK4_FREQ;               --
        when 19 => --0x13
          localRdData(31 downto  0)  <=  Mon.TXCLK5_FREQ;               --
        when 20 => --0x14
          localRdData(31 downto  0)  <=  Mon.TXCLK6_FREQ;               --
        when 21 => --0x15
          localRdData(31 downto  0)  <=  Mon.TXCLK7_FREQ;               --
        when 22 => --0x16
          localRdData(31 downto  0)  <=  Mon.TXCLK8_FREQ;               --
        when 23 => --0x17
          localRdData(31 downto  0)  <=  Mon.TXCLK9_FREQ;               --
        when 24 => --0x18
          localRdData(31 downto  0)  <=  Mon.RXCLK0_FREQ;               --
        when 25 => --0x19
          localRdData(31 downto  0)  <=  Mon.RXCLK1_FREQ;               --
        when 26 => --0x1a
          localRdData(31 downto  0)  <=  Mon.RXCLK2_FREQ;               --
        when 27 => --0x1b
          localRdData(31 downto  0)  <=  Mon.RXCLK3_FREQ;               --
        when 28 => --0x1c
          localRdData(31 downto  0)  <=  Mon.RXCLK4_FREQ;               --
        when 29 => --0x1d
          localRdData(31 downto  0)  <=  Mon.RXCLK5_FREQ;               --
        when 30 => --0x1e
          localRdData(31 downto  0)  <=  Mon.RXCLK6_FREQ;               --
        when 31 => --0x1f
          localRdData(31 downto  0)  <=  Mon.RXCLK7_FREQ;               --
        when 32 => --0x20
          localRdData(31 downto  0)  <=  Mon.RXCLK8_FREQ;               --
        when 33 => --0x21
          localRdData(31 downto  0)  <=  Mon.RXCLK9_FREQ;               --

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;



end architecture behavioral;