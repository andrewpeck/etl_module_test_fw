--This file was auto-generated.
--Modifications might be lost.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MGT_Ctrl.all;
entity MGT_wb_map is
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
end entity MGT_wb_map;
architecture behavioral of MGT_wb_map is
  signal strobe_r : std_logic := '0';
  signal strobe_pulse : std_logic := '0';
  type slv32_array_t  is array (integer range <>) of std_logic_vector( 31 downto 0);
  signal localRdData : std_logic_vector (31 downto 0) := (others => '0');
  signal localWrData : std_logic_vector (31 downto 0) := (others => '0');
  signal reg_data :  slv32_array_t(integer range 0 to 64);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 64) := (others => x"00000000");
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
        case to_integer(unsigned(wb_addr(6 downto 0))) is
          when 0 => --0x0
          localRdData( 9 downto  0)  <=  reg_data( 0)( 9 downto  0);      --
          localRdData(21 downto 12)  <=  reg_data( 0)(21 downto 12);      --
        when 1 => --0x1
          localRdData( 9 downto  0)  <=  Mon.MGT_TX_READY;                --
          localRdData(21 downto 12)  <=  Mon.MGT_RX_READY;                --
        when 3 => --0x3
          localRdData( 8 downto  0)  <=  reg_data( 3)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data( 3)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(0).RD_RDY;           --DRP Enable
        when 4 => --0x4
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(0).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data( 4)(31 downto 16);      --DRP Write Data
        when 8 => --0x8
          localRdData( 8 downto  0)  <=  reg_data( 8)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data( 8)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(1).RD_RDY;           --DRP Enable
        when 9 => --0x9
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(1).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data( 9)(31 downto 16);      --DRP Write Data
        when 13 => --0xd
          localRdData( 8 downto  0)  <=  reg_data(13)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(13)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(2).RD_RDY;           --DRP Enable
        when 14 => --0xe
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(2).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(14)(31 downto 16);      --DRP Write Data
        when 18 => --0x12
          localRdData( 8 downto  0)  <=  reg_data(18)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(18)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(3).RD_RDY;           --DRP Enable
        when 19 => --0x13
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(3).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(19)(31 downto 16);      --DRP Write Data
        when 23 => --0x17
          localRdData( 8 downto  0)  <=  reg_data(23)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(23)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(4).RD_RDY;           --DRP Enable
        when 24 => --0x18
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(4).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(24)(31 downto 16);      --DRP Write Data
        when 28 => --0x1c
          localRdData( 8 downto  0)  <=  reg_data(28)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(28)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(5).RD_RDY;           --DRP Enable
        when 29 => --0x1d
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(5).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(29)(31 downto 16);      --DRP Write Data
        when 33 => --0x21
          localRdData( 8 downto  0)  <=  reg_data(33)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(33)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(6).RD_RDY;           --DRP Enable
        when 34 => --0x22
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(6).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(34)(31 downto 16);      --DRP Write Data
        when 38 => --0x26
          localRdData( 8 downto  0)  <=  reg_data(38)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(38)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(7).RD_RDY;           --DRP Enable
        when 39 => --0x27
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(7).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(39)(31 downto 16);      --DRP Write Data
        when 43 => --0x2b
          localRdData( 8 downto  0)  <=  reg_data(43)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(43)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(8).RD_RDY;           --DRP Enable
        when 44 => --0x2c
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(8).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(44)(31 downto 16);      --DRP Write Data
        when 48 => --0x30
          localRdData( 8 downto  0)  <=  reg_data(48)( 8 downto  0);      --DRP Address
          localRdData(12)            <=  reg_data(48)(12);                --DRP Enable
          localRdData(13)            <=  Mon.DRP.DRP(9).RD_RDY;           --DRP Enable
        when 49 => --0x31
          localRdData(15 downto  0)  <=  Mon.DRP.DRP(9).RD_DATA;          --DRP Read Data
          localRdData(31 downto 16)  <=  reg_data(49)(31 downto 16);      --DRP Write Data
        when 64 => --0x40
          localRdData( 0)            <=  reg_data(64)( 0);                --Controls SFP0 Disable
          localRdData( 1)            <=  reg_data(64)( 1);                --Controls SFP1 Disable

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;


  -- Register mapping to ctrl structures
  Ctrl.MGT_TX_RESET        <=  reg_data( 0)( 9 downto  0);     
  Ctrl.MGT_RX_RESET        <=  reg_data( 0)(21 downto 12);     
  Ctrl.DRP.DRP(0).WR_ADDR  <=  reg_data( 3)( 8 downto  0);     
  Ctrl.DRP.DRP(0).EN       <=  reg_data( 3)(12);               
  Ctrl.DRP.DRP(0).WR_DATA  <=  reg_data( 4)(31 downto 16);     
  Ctrl.DRP.DRP(1).WR_ADDR  <=  reg_data( 8)( 8 downto  0);     
  Ctrl.DRP.DRP(1).EN       <=  reg_data( 8)(12);               
  Ctrl.DRP.DRP(1).WR_DATA  <=  reg_data( 9)(31 downto 16);     
  Ctrl.DRP.DRP(2).WR_ADDR  <=  reg_data(13)( 8 downto  0);     
  Ctrl.DRP.DRP(2).EN       <=  reg_data(13)(12);               
  Ctrl.DRP.DRP(2).WR_DATA  <=  reg_data(14)(31 downto 16);     
  Ctrl.DRP.DRP(3).WR_ADDR  <=  reg_data(18)( 8 downto  0);     
  Ctrl.DRP.DRP(3).EN       <=  reg_data(18)(12);               
  Ctrl.DRP.DRP(3).WR_DATA  <=  reg_data(19)(31 downto 16);     
  Ctrl.DRP.DRP(4).WR_ADDR  <=  reg_data(23)( 8 downto  0);     
  Ctrl.DRP.DRP(4).EN       <=  reg_data(23)(12);               
  Ctrl.DRP.DRP(4).WR_DATA  <=  reg_data(24)(31 downto 16);     
  Ctrl.DRP.DRP(5).WR_ADDR  <=  reg_data(28)( 8 downto  0);     
  Ctrl.DRP.DRP(5).EN       <=  reg_data(28)(12);               
  Ctrl.DRP.DRP(5).WR_DATA  <=  reg_data(29)(31 downto 16);     
  Ctrl.DRP.DRP(6).WR_ADDR  <=  reg_data(33)( 8 downto  0);     
  Ctrl.DRP.DRP(6).EN       <=  reg_data(33)(12);               
  Ctrl.DRP.DRP(6).WR_DATA  <=  reg_data(34)(31 downto 16);     
  Ctrl.DRP.DRP(7).WR_ADDR  <=  reg_data(38)( 8 downto  0);     
  Ctrl.DRP.DRP(7).EN       <=  reg_data(38)(12);               
  Ctrl.DRP.DRP(7).WR_DATA  <=  reg_data(39)(31 downto 16);     
  Ctrl.DRP.DRP(8).WR_ADDR  <=  reg_data(43)( 8 downto  0);     
  Ctrl.DRP.DRP(8).EN       <=  reg_data(43)(12);               
  Ctrl.DRP.DRP(8).WR_DATA  <=  reg_data(44)(31 downto 16);     
  Ctrl.DRP.DRP(9).WR_ADDR  <=  reg_data(48)( 8 downto  0);     
  Ctrl.DRP.DRP(9).EN       <=  reg_data(48)(12);               
  Ctrl.DRP.DRP(9).WR_DATA  <=  reg_data(49)(31 downto 16);     
  Ctrl.SFP0_TX_DIS         <=  reg_data(64)( 0);               
  Ctrl.SFP1_TX_DIS         <=  reg_data(64)( 1);               


  -- writes to slave
  reg_writes: process (clk) is
  begin  -- process reg_writes
    if (rising_edge(clk)) then  -- rising clock edge

      -- action resets
      Ctrl.DRP.DRP(0).WR_EN <= '0';
      Ctrl.DRP.DRP(1).WR_EN <= '0';
      Ctrl.DRP.DRP(2).WR_EN <= '0';
      Ctrl.DRP.DRP(3).WR_EN <= '0';
      Ctrl.DRP.DRP(4).WR_EN <= '0';
      Ctrl.DRP.DRP(5).WR_EN <= '0';
      Ctrl.DRP.DRP(6).WR_EN <= '0';
      Ctrl.DRP.DRP(7).WR_EN <= '0';
      Ctrl.DRP.DRP(8).WR_EN <= '0';
      Ctrl.DRP.DRP(9).WR_EN <= '0';
      


      -- Write on strobe=write=1
      if strobe_pulse='1' and wb_write = '1' then
        case to_integer(unsigned(wb_addr(6 downto 0))) is
        when 0 => --0x0
          reg_data( 0)( 9 downto  0)  <=  localWrData( 9 downto  0);      --
          reg_data( 0)(21 downto 12)  <=  localWrData(21 downto 12);      --
        when 2 => --0x2
          Ctrl.DRP.DRP(0).WR_EN       <=  localWrData( 0);               
        when 3 => --0x3
          reg_data( 3)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data( 3)(12)            <=  localWrData(12);                --DRP Enable
        when 4 => --0x4
          reg_data( 4)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 7 => --0x7
          Ctrl.DRP.DRP(1).WR_EN       <=  localWrData( 0);               
        when 8 => --0x8
          reg_data( 8)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data( 8)(12)            <=  localWrData(12);                --DRP Enable
        when 9 => --0x9
          reg_data( 9)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 12 => --0xc
          Ctrl.DRP.DRP(2).WR_EN       <=  localWrData( 0);               
        when 13 => --0xd
          reg_data(13)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(13)(12)            <=  localWrData(12);                --DRP Enable
        when 14 => --0xe
          reg_data(14)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 17 => --0x11
          Ctrl.DRP.DRP(3).WR_EN       <=  localWrData( 0);               
        when 18 => --0x12
          reg_data(18)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(18)(12)            <=  localWrData(12);                --DRP Enable
        when 19 => --0x13
          reg_data(19)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 22 => --0x16
          Ctrl.DRP.DRP(4).WR_EN       <=  localWrData( 0);               
        when 23 => --0x17
          reg_data(23)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(23)(12)            <=  localWrData(12);                --DRP Enable
        when 24 => --0x18
          reg_data(24)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 27 => --0x1b
          Ctrl.DRP.DRP(5).WR_EN       <=  localWrData( 0);               
        when 28 => --0x1c
          reg_data(28)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(28)(12)            <=  localWrData(12);                --DRP Enable
        when 29 => --0x1d
          reg_data(29)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 32 => --0x20
          Ctrl.DRP.DRP(6).WR_EN       <=  localWrData( 0);               
        when 33 => --0x21
          reg_data(33)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(33)(12)            <=  localWrData(12);                --DRP Enable
        when 34 => --0x22
          reg_data(34)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 37 => --0x25
          Ctrl.DRP.DRP(7).WR_EN       <=  localWrData( 0);               
        when 38 => --0x26
          reg_data(38)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(38)(12)            <=  localWrData(12);                --DRP Enable
        when 39 => --0x27
          reg_data(39)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 42 => --0x2a
          Ctrl.DRP.DRP(8).WR_EN       <=  localWrData( 0);               
        when 43 => --0x2b
          reg_data(43)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(43)(12)            <=  localWrData(12);                --DRP Enable
        when 44 => --0x2c
          reg_data(44)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 47 => --0x2f
          Ctrl.DRP.DRP(9).WR_EN       <=  localWrData( 0);               
        when 48 => --0x30
          reg_data(48)( 8 downto  0)  <=  localWrData( 8 downto  0);      --DRP Address
          reg_data(48)(12)            <=  localWrData(12);                --DRP Enable
        when 49 => --0x31
          reg_data(49)(31 downto 16)  <=  localWrData(31 downto 16);      --DRP Write Data
        when 64 => --0x40
          reg_data(64)( 0)            <=  localWrData( 0);                --Controls SFP0 Disable
          reg_data(64)( 1)            <=  localWrData( 1);                --Controls SFP1 Disable

        when others => null;

        end case;
      end if; -- write

      -- synchronous reset (active high)
      if reset = '1' then
      reg_data( 0)( 9 downto  0)  <= DEFAULT_MGT_CTRL_t.MGT_TX_RESET;
      reg_data( 0)(21 downto 12)  <= DEFAULT_MGT_CTRL_t.MGT_RX_RESET;
      reg_data( 3)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(0).WR_ADDR;
      reg_data( 3)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(0).EN;
      reg_data( 4)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(0).WR_DATA;
      reg_data( 8)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(1).WR_ADDR;
      reg_data( 8)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(1).EN;
      reg_data( 9)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(1).WR_DATA;
      reg_data(13)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(2).WR_ADDR;
      reg_data(13)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(2).EN;
      reg_data(14)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(2).WR_DATA;
      reg_data(18)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(3).WR_ADDR;
      reg_data(18)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(3).EN;
      reg_data(19)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(3).WR_DATA;
      reg_data(23)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(4).WR_ADDR;
      reg_data(23)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(4).EN;
      reg_data(24)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(4).WR_DATA;
      reg_data(28)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(5).WR_ADDR;
      reg_data(28)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(5).EN;
      reg_data(29)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(5).WR_DATA;
      reg_data(33)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(6).WR_ADDR;
      reg_data(33)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(6).EN;
      reg_data(34)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(6).WR_DATA;
      reg_data(38)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(7).WR_ADDR;
      reg_data(38)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(7).EN;
      reg_data(39)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(7).WR_DATA;
      reg_data(43)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(8).WR_ADDR;
      reg_data(43)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(8).EN;
      reg_data(44)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(8).WR_DATA;
      reg_data(48)( 8 downto  0)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(9).WR_ADDR;
      reg_data(48)(12)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(9).EN;
      reg_data(49)(31 downto 16)  <= DEFAULT_MGT_CTRL_t.DRP.DRP(9).WR_DATA;
      reg_data(64)( 0)  <= DEFAULT_MGT_CTRL_t.SFP0_TX_DIS;
      reg_data(64)( 1)  <= DEFAULT_MGT_CTRL_t.SFP1_TX_DIS;

      end if; -- reset
    end if; -- clk
  end process reg_writes;


end architecture behavioral;