--This file was auto-generated.
--Modifications might be lost.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.FW_INFO_Ctrl.all;
entity FW_INFO_wb_interface is
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
end entity FW_INFO_wb_interface;
architecture behavioral of FW_INFO_wb_interface is
  signal strobe_r : std_logic := '0';
  signal strobe_pulse : std_logic := '0';
  type slv32_array_t  is array (integer range <>) of std_logic_vector( 31 downto 0);
  signal localRdData : std_logic_vector (31 downto 0) := (others => '0');
  signal localWrData : std_logic_vector (31 downto 0) := (others => '0');
  signal reg_data :  slv32_array_t(integer range 0 to 6);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 6) := (others => x"00000000");
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
        case to_integer(unsigned(wb_addr(2 downto 0))) is
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

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;



end architecture behavioral;