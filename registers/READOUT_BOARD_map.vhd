--This file was auto-generated.
--Modifications might be lost.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.READOUT_BOARD_Ctrl.all;
entity READOUT_BOARD_wb_map is
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
    mon         : in  READOUT_BOARD_Mon_t;
    ctrl        : out READOUT_BOARD_Ctrl_t
    );
end entity READOUT_BOARD_wb_map;
architecture behavioral of READOUT_BOARD_wb_map is
  signal strobe_r : std_logic := '0';
  signal strobe_pulse : std_logic := '0';
  type slv32_array_t  is array (integer range <>) of std_logic_vector( 31 downto 0);
  signal localRdData : std_logic_vector (31 downto 0) := (others => '0');
  signal localWrData : std_logic_vector (31 downto 0) := (others => '0');
  signal reg_data :  slv32_array_t(integer range 0 to 1303);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 1303) := (others => x"00000000");
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
          when 1 => --0x1
          localRdData( 0)            <=  Mon.LPGBT.UPLINK(0).READY;                   --LPGBT Uplink Ready
          localRdData( 1)            <=  reg_data( 1)( 1);                            --1 = FEC12 | 0 = FEC5
          localRdData(31 downto 16)  <=  Mon.LPGBT.UPLINK(0).FEC_ERR_CNT;             --Data Corrected Count
        when 17 => --0x11
          localRdData( 0)            <=  Mon.LPGBT.UPLINK(1).READY;                   --LPGBT Uplink Ready
          localRdData( 1)            <=  reg_data(17)( 1);                            --1 = FEC12 | 0 = FEC5
          localRdData(31 downto 16)  <=  Mon.LPGBT.UPLINK(1).FEC_ERR_CNT;             --Data Corrected Count
        when 33 => --0x21
          localRdData( 0)            <=  Mon.LPGBT.DOWNLINK.READY;                    --LPGBT Downlink Ready
        when 35 => --0x23
          localRdData( 3 downto  0)  <=  reg_data(35)( 3 downto  0);                  --0=etroc, 1=upcnt, 2=prbs, 3=txfifo
        when 67 => --0x43
          localRdData(31 downto  0)  <=  reg_data(67)(31 downto  0);                  --Bitmask 1 to enable checking
        when 68 => --0x44
          localRdData(31 downto  0)  <=  reg_data(68)(31 downto  0);                  --Bitmask 1 to enable checking
        when 69 => --0x45
          localRdData(31 downto  0)  <=  reg_data(69)(31 downto  0);                  --Bitmask 1 to enable checking
        when 70 => --0x46
          localRdData(31 downto  0)  <=  reg_data(70)(31 downto  0);                  --Bitmask 1 to enable checking
        when 71 => --0x47
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.TIMER_LSBS;        --Timer of how long the counter has been running
        when 72 => --0x48
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.TIMER_MSBS;        --Timer of how long the counter has been running
        when 73 => --0x49
          localRdData(31 downto 16)  <=  reg_data(73)(31 downto 16);                  --Channel to select for error counting
        when 74 => --0x4a
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.UPCNT_ERRORS;      --Errors on Upcnt
        when 75 => --0x4b
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.PRBS_ERRORS;       --Errors on Prbs
        when 262 => --0x106
          localRdData(31 downto  0)  <=  reg_data(262)(31 downto  0);                 --1 to zero suppress fillers out from the ETROC RX
        when 263 => --0x107
          localRdData( 0)            <=  reg_data(263)( 0);                           --1 to enable automatic bitslipping alignment
          localRdData( 3 downto  1)  <=  reg_data(263)( 3 downto  1);                 --2 = 320 Mbps, 3 = 640 Mbps, 4 = 1280 Mbps
        when 264 => --0x108
          localRdData(31 downto  0)  <=  reg_data(264)(31 downto  0);                 --1 to read all data from ETROC, regardless of content
        when 267 => --0x10b
          localRdData(31 downto  0)  <=  reg_data(267)(31 downto  0);                 --1 to zero suppress fillers out from the ETROC RX
        when 268 => --0x10c
          localRdData(31 downto  0)  <=  reg_data(268)(31 downto  0);                 --1 to read all data from ETROC, regardless of content
        when 516 => --0x204
          localRdData(15 downto  8)  <=  reg_data(516)(15 downto  8);                 --I2C address of the GBTx
        when 517 => --0x205
          localRdData(15 downto  0)  <=  reg_data(517)(15 downto  0);                 --Address of the first register to be accessed
        when 518 => --0x206
          localRdData(15 downto  0)  <=  reg_data(518)(15 downto  0);                 --Number of words/bytes to be read (only for read transactions)
          localRdData(28)            <=  reg_data(518)(28);                           --IC Frame format: 0 = lpGBT v0; 1 = lpGBT v1
        when 519 => --0x207
          localRdData( 7 downto  0)  <=  reg_data(519)( 7 downto  0);                 --Data to be written into the internal FIFO
        when 520 => --0x208
          localRdData( 7 downto  0)  <=  Mon.SC.RX_DATA_FROM_GBTX;                    --Data from the LPGBT
          localRdData(23 downto  8)  <=  Mon.SC.RX_ADR_FROM_GBTX;                     --Adr from the LPGBT
          localRdData(31)            <=  Mon.SC.RX_DATA_VALID;                        --Data from the LPGBT is valid
        when 523 => --0x20b
          localRdData( 0)            <=  Mon.SC.TX_READY;                             --IC core ready for a transaction
        when 524 => --0x20c
          localRdData( 1)            <=  Mon.SC.RX_EMPTY;                             --Rx FIFO is empty (no reply from GBTx)
        when 525 => --0x20d
          localRdData( 7 downto  0)  <=  reg_data(525)( 7 downto  0);                 --Command: The Command field is present in the frames received by the SCA and indicates the operation to be performed. Meaning is specific to the channel.
        when 526 => --0x20e
          localRdData(15 downto  8)  <=  reg_data(526)(15 downto  8);                 --Command: It represents the packet destination address. The address is one-byte long. By default, the GBT-SCA use address 0x00.
        when 527 => --0x20f
          localRdData(23 downto 16)  <=  reg_data(527)(23 downto 16);                 --Command: Specifies the message identification number. The reply messages generated by the SCA have the same transaction identifier of the request message allowing to associate the transmitted commands with the corresponding replies, permitting the concurrent use of all the SCA channels.  It is not required that ID values are ordered. ID values 0x00 and 0xff are reserved for interrupt packets generated spontaneously by the SCA and should not be used in requests.
        when 528 => --0x210
          localRdData(31 downto 24)  <=  reg_data(528)(31 downto 24);                 --Command: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 529 => --0x211
          localRdData(31 downto  0)  <=  reg_data(529)(31 downto  0);                 --Command: data field (According to the SCA manual)
        when 530 => --0x212
          localRdData( 7 downto  0)  <=  Mon.SC.RX.RX_LEN;                            --Reply: The length qualifier field specifies the number of bytes contained in the DATA field.
          localRdData(15 downto  8)  <=  Mon.SC.RX.RX_ADDRESS;                        --Reply: It represents the packet destination address. The address is one-bytelong. By default, the GBT-SCA use address 0x00.
          localRdData(23 downto 16)  <=  Mon.SC.RX.RX_CONTROL;                        --Reply: The control field is 1 byte in length and contains frame sequence numbers of the currently transmitted frame and the last correctly received frame. The control field is also used to convey three supervisory level commands: Connect, Reset, and Test.
          localRdData(31 downto 24)  <=  Mon.SC.RX.RX_TRANSID;                        --Reply: transaction ID field (According to the SCA manual)
        when 531 => --0x213
          localRdData( 7 downto  0)  <=  Mon.SC.RX.RX_ERR;                            --Reply: The Error Flag field is present in the channel reply frames to indicate error conditions encountered in the execution of a command. If no errors are found, its value is 0x00.
          localRdData( 8)            <=  Mon.SC.RX.RX_RECEIVED;                       --Reply received flag (pulse)
          localRdData(19 downto 12)  <=  Mon.SC.RX.RX_CHANNEL;                        --Reply: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 532 => --0x214
          localRdData(31 downto  0)  <=  Mon.SC.RX.RX_DATA;                           --Reply: The Data field is command dependent field whose length is defined by the length qualifier field. For example, in the case of a read/write operation on a GBT-SCA internal register, it contains the value written/read from the register.
        when 540 => --0x21c
          localRdData( 0)            <=  reg_data(540)( 0);                           --Enable flag to select SCAs
        when 768 => --0x300
          localRdData( 4 downto  0)  <=  reg_data(768)( 4 downto  0);                 --Choose which e-link the readout fifo connects to (0-27)
          localRdData( 8)            <=  reg_data(768)( 8);                           --Choose which lpgbt the readout fifo connects to (0-1)
        when 783 => --0x30f
          localRdData( 1)            <=  reg_data(783)( 1);                           --TX Fifo Read enable
        when 784 => --0x310
          localRdData(31 downto  0)  <=  reg_data(784)(31 downto  0);                 --TX Fifo Data
        when 786 => --0x312
          localRdData(31 downto  0)  <=  Mon.RX_FIFO_LOST_WORD_CNT;                   --# of words lost to a full FIFO
        when 787 => --0x313
          localRdData( 0)            <=  Mon.RX_FIFO_FULL;                            --RX FIFO is full
        when 788 => --0x314
          localRdData(31 downto  0)  <=  Mon.RX_FIFO_OCCUPANCY;                       --RX FIFO occupancy
        when 1056 => --0x420
          localRdData( 0)            <=  reg_data(1056)( 0);                          --0=etroc data, 1=fixed pattern for ETROC data fifo
        when 1057 => --0x421
          localRdData(27 downto  0)  <=  Mon.ETROC_LOCKED;                            --ETROC Link Locked
        when 1058 => --0x422
          localRdData(27 downto  0)  <=  Mon.ETROC_LOCKED_SLAVE;                      --ETROC Link Locked
        when 1059 => --0x423
          localRdData(27 downto  0)  <=  reg_data(1059)(27 downto  0);                --Write a 1 to disable this ETROC from readout
        when 1060 => --0x424
          localRdData(27 downto  0)  <=  reg_data(1060)(27 downto  0);                --Write a 1 to disable this ETROC from readout
        when 1282 => --0x502
          localRdData(15 downto  0)  <=  reg_data(1282)(15 downto  0);                --Number of clock cycles (40MHz) after which the L1A should be generated for a QINJ+L1A
        when 1284 => --0x504
          localRdData(31 downto  0)  <=  Mon.PACKET_RX_RATE;                          --Measured rate of generated received packets in Hz
        when 1285 => --0x505
          localRdData(15 downto  0)  <=  Mon.PACKET_CNT;                              --Count of packets received (muxed across elinks)
          localRdData(31 downto 16)  <=  Mon.ERROR_CNT;                               --Count of packet errors (muxed across elinks)
        when 1286 => --0x506
          localRdData(31 downto 16)  <=  Mon.DATA_CNT;                                --Count of packet data frames (muxed across elinks)
        when 1287 => --0x507
          localRdData(23 downto  0)  <=  Mon.FILLER_RATE;                             --Rate of packet filler frames (muxed across elinks)
        when 1288 => --0x508
          localRdData(31 downto  0)  <=  reg_data(1288)(31 downto  0);                --Bitmask to enable bits in the trigger link. Bits 31 downto 0.
        when 1289 => --0x509
          localRdData(31 downto  0)  <=  reg_data(1289)(31 downto  0);                --Bitmask to enable bits in the trigger link. Bits 63 downto 32.
        when 1290 => --0x50a
          localRdData(31 downto  0)  <=  reg_data(1290)(31 downto  0);                --Bitmask to enable bits in the trigger link. Bits 95 downto 64.
        when 1291 => --0x50b
          localRdData(31 downto  0)  <=  reg_data(1291)(31 downto  0);                --Bitmask to enable bits in the trigger link. Bits 127 downto 96.
        when 1292 => --0x50c
          localRdData(31 downto  0)  <=  reg_data(1292)(31 downto  0);                --Bitmask to enable bits in the trigger link. Bits 159 downto 128.
        when 1293 => --0x50d
          localRdData(31 downto  0)  <=  reg_data(1293)(31 downto  0);                --Bitmask to enable bits in the trigger link. Bits 191 downto 160.
        when 1294 => --0x50e
          localRdData(31 downto  0)  <=  reg_data(1294)(31 downto  0);                --Bitmask to enable bits in the trigger link. Bits 223 downto 192.
        when 1295 => --0x50f
          localRdData(28)            <=  reg_data(1295)(28);                          --Set to 1 to enable ETROC self trigger.
        when 1296 => --0x510
          localRdData( 4 downto  0)  <=  reg_data(1296)( 4 downto  0);                --Bitslip for ETROC0
          localRdData( 9 downto  5)  <=  reg_data(1296)( 9 downto  5);                --Bitslip for ETROC1
          localRdData(14 downto 10)  <=  reg_data(1296)(14 downto 10);                --Bitslip for ETROC2
          localRdData(19 downto 15)  <=  reg_data(1296)(19 downto 15);                --Bitslip for ETROC3
          localRdData(24 downto 20)  <=  reg_data(1296)(24 downto 20);                --Bitslip for ETROC4
          localRdData(29 downto 25)  <=  reg_data(1296)(29 downto 25);                --Bitslip for ETROC5
        when 1297 => --0x511
          localRdData( 4 downto  0)  <=  reg_data(1297)( 4 downto  0);                --Bitslip for ETROC6
          localRdData( 9 downto  5)  <=  reg_data(1297)( 9 downto  5);                --Bitslip for ETROC7
          localRdData(14 downto 10)  <=  reg_data(1297)(14 downto 10);                --Bitslip for ETROC8
          localRdData(19 downto 15)  <=  reg_data(1297)(19 downto 15);                --Bitslip for ETROC9
          localRdData(24 downto 20)  <=  reg_data(1297)(24 downto 20);                --Bitslip for ETROC10
          localRdData(29 downto 25)  <=  reg_data(1297)(29 downto 25);                --Bitslip for ETROC11
        when 1298 => --0x512
          localRdData( 4 downto  0)  <=  reg_data(1298)( 4 downto  0);                --Bitslip for ETROC12
          localRdData( 9 downto  5)  <=  reg_data(1298)( 9 downto  5);                --Bitslip for ETROC13
          localRdData(14 downto 10)  <=  reg_data(1298)(14 downto 10);                --Bitslip for ETROC14
          localRdData(19 downto 15)  <=  reg_data(1298)(19 downto 15);                --Bitslip for ETROC15
          localRdData(24 downto 20)  <=  reg_data(1298)(24 downto 20);                --Bitslip for ETROC16
          localRdData(29 downto 25)  <=  reg_data(1298)(29 downto 25);                --Bitslip for ETROC17
        when 1299 => --0x513
          localRdData( 4 downto  0)  <=  reg_data(1299)( 4 downto  0);                --Bitslip for ETROC18
          localRdData( 9 downto  5)  <=  reg_data(1299)( 9 downto  5);                --Bitslip for ETROC19
          localRdData(14 downto 10)  <=  reg_data(1299)(14 downto 10);                --Bitslip for ETROC20
          localRdData(19 downto 15)  <=  reg_data(1299)(19 downto 15);                --Bitslip for ETROC21
          localRdData(24 downto 20)  <=  reg_data(1299)(24 downto 20);                --Bitslip for ETROC22
          localRdData(29 downto 25)  <=  reg_data(1299)(29 downto 25);                --Bitslip for ETROC23
        when 1300 => --0x514
          localRdData( 4 downto  0)  <=  reg_data(1300)( 4 downto  0);                --Bitslip for ETROC24
          localRdData( 9 downto  5)  <=  reg_data(1300)( 9 downto  5);                --Bitslip for ETROC25
          localRdData(14 downto 10)  <=  reg_data(1300)(14 downto 10);                --Bitslip for ETROC26
          localRdData(19 downto 15)  <=  reg_data(1300)(19 downto 15);                --Bitslip for ETROC27
          localRdData(24 downto 20)  <=  reg_data(1300)(24 downto 20);                --Select Delay in terms of clock cycles
        when 1301 => --0x515
          localRdData( 4 downto  0)  <=  Mon.TRIGGER_RATES;                           --Trigger rate cnt of selected ETROC (muxed accross elinks)
        when 1303 => --0x517
          localRdData(31 downto  0)  <=  Mon.EVENT_CNT;                               --Read counts on event counter

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;


  -- Register mapping to ctrl structures
  Ctrl.LPGBT.UPLINK(0).FEC_MODE                <=  reg_data( 1)( 1);                 
  Ctrl.LPGBT.UPLINK(1).FEC_MODE                <=  reg_data(17)( 1);                 
  Ctrl.LPGBT.DOWNLINK.DL_SRC                   <=  reg_data(35)( 3 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_0   <=  reg_data(67)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_0  <=  reg_data(68)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_1   <=  reg_data(69)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_1  <=  reg_data(70)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.SEL               <=  reg_data(73)(31 downto 16);       
  Ctrl.ZERO_SUPRESS                            <=  reg_data(262)(31 downto  0);      
  Ctrl.BITSLIP_AUTO_EN                         <=  reg_data(263)( 0);                
  Ctrl.ELINK_WIDTH                             <=  reg_data(263)( 3 downto  1);      
  Ctrl.RAW_DATA_MODE                           <=  reg_data(264)(31 downto  0);      
  Ctrl.ZERO_SUPRESS_SLAVE                      <=  reg_data(267)(31 downto  0);      
  Ctrl.RAW_DATA_MODE_SLAVE                     <=  reg_data(268)(31 downto  0);      
  Ctrl.SC.TX_GBTX_ADDR                         <=  reg_data(516)(15 downto  8);      
  Ctrl.SC.TX_REGISTER_ADDR                     <=  reg_data(517)(15 downto  0);      
  Ctrl.SC.TX_NUM_BYTES_TO_READ                 <=  reg_data(518)(15 downto  0);      
  Ctrl.SC.FRAME_FORMAT                         <=  reg_data(518)(28);                
  Ctrl.SC.TX_DATA_TO_GBTX                      <=  reg_data(519)( 7 downto  0);      
  Ctrl.SC.TX_CMD                               <=  reg_data(525)( 7 downto  0);      
  Ctrl.SC.TX_ADDRESS                           <=  reg_data(526)(15 downto  8);      
  Ctrl.SC.TX_TRANSID                           <=  reg_data(527)(23 downto 16);      
  Ctrl.SC.TX_CHANNEL                           <=  reg_data(528)(31 downto 24);      
  Ctrl.SC.TX_DATA                              <=  reg_data(529)(31 downto  0);      
  Ctrl.SC.SCA_ENABLE                           <=  reg_data(540)( 0);                
  Ctrl.FIFO_ELINK_SEL0                         <=  reg_data(768)( 4 downto  0);      
  Ctrl.FIFO_LPGBT_SEL0                         <=  reg_data(768)( 8);                
  Ctrl.TX_FIFO_RD_EN                           <=  reg_data(783)( 1);                
  Ctrl.TX_FIFO_DATA                            <=  reg_data(784)(31 downto  0);      
  Ctrl.RX_FIFO_DATA_SRC                        <=  reg_data(1056)( 0);               
  Ctrl.ETROC_DISABLE                           <=  reg_data(1059)(27 downto  0);     
  Ctrl.ETROC_DISABLE_SLAVE                     <=  reg_data(1060)(27 downto  0);     
  Ctrl.L1A_INJ_DLY                             <=  reg_data(1282)(15 downto  0);     
  Ctrl.TRIG_ENABLE_MASK_0                      <=  reg_data(1288)(31 downto  0);     
  Ctrl.TRIG_ENABLE_MASK_1                      <=  reg_data(1289)(31 downto  0);     
  Ctrl.TRIG_ENABLE_MASK_2                      <=  reg_data(1290)(31 downto  0);     
  Ctrl.TRIG_ENABLE_MASK_3                      <=  reg_data(1291)(31 downto  0);     
  Ctrl.TRIG_ENABLE_MASK_4                      <=  reg_data(1292)(31 downto  0);     
  Ctrl.TRIG_ENABLE_MASK_5                      <=  reg_data(1293)(31 downto  0);     
  Ctrl.TRIG_ENABLE_MASK_6                      <=  reg_data(1294)(31 downto  0);     
  Ctrl.TRIG_ENABLE                             <=  reg_data(1295)(28);               
  Ctrl.TRIG_BITSLIP_0                          <=  reg_data(1296)( 4 downto  0);     
  Ctrl.TRIG_BITSLIP_1                          <=  reg_data(1296)( 9 downto  5);     
  Ctrl.TRIG_BITSLIP_2                          <=  reg_data(1296)(14 downto 10);     
  Ctrl.TRIG_BITSLIP_3                          <=  reg_data(1296)(19 downto 15);     
  Ctrl.TRIG_BITSLIP_4                          <=  reg_data(1296)(24 downto 20);     
  Ctrl.TRIG_BITSLIP_5                          <=  reg_data(1296)(29 downto 25);     
  Ctrl.TRIG_BITSLIP_6                          <=  reg_data(1297)( 4 downto  0);     
  Ctrl.TRIG_BITSLIP_7                          <=  reg_data(1297)( 9 downto  5);     
  Ctrl.TRIG_BITSLIP_8                          <=  reg_data(1297)(14 downto 10);     
  Ctrl.TRIG_BITSLIP_9                          <=  reg_data(1297)(19 downto 15);     
  Ctrl.TRIG_BITSLIP_10                         <=  reg_data(1297)(24 downto 20);     
  Ctrl.TRIG_BITSLIP_11                         <=  reg_data(1297)(29 downto 25);     
  Ctrl.TRIG_BITSLIP_12                         <=  reg_data(1298)( 4 downto  0);     
  Ctrl.TRIG_BITSLIP_13                         <=  reg_data(1298)( 9 downto  5);     
  Ctrl.TRIG_BITSLIP_14                         <=  reg_data(1298)(14 downto 10);     
  Ctrl.TRIG_BITSLIP_15                         <=  reg_data(1298)(19 downto 15);     
  Ctrl.TRIG_BITSLIP_16                         <=  reg_data(1298)(24 downto 20);     
  Ctrl.TRIG_BITSLIP_17                         <=  reg_data(1298)(29 downto 25);     
  Ctrl.TRIG_BITSLIP_18                         <=  reg_data(1299)( 4 downto  0);     
  Ctrl.TRIG_BITSLIP_19                         <=  reg_data(1299)( 9 downto  5);     
  Ctrl.TRIG_BITSLIP_20                         <=  reg_data(1299)(14 downto 10);     
  Ctrl.TRIG_BITSLIP_21                         <=  reg_data(1299)(19 downto 15);     
  Ctrl.TRIG_BITSLIP_22                         <=  reg_data(1299)(24 downto 20);     
  Ctrl.TRIG_BITSLIP_23                         <=  reg_data(1299)(29 downto 25);     
  Ctrl.TRIG_BITSLIP_24                         <=  reg_data(1300)( 4 downto  0);     
  Ctrl.TRIG_BITSLIP_25                         <=  reg_data(1300)( 9 downto  5);     
  Ctrl.TRIG_BITSLIP_26                         <=  reg_data(1300)(14 downto 10);     
  Ctrl.TRIG_BITSLIP_27                         <=  reg_data(1300)(19 downto 15);     
  Ctrl.TRIG_DLY_SEL                            <=  reg_data(1300)(24 downto 20);     


  -- writes to slave
  reg_writes: process (clk) is
  begin  -- process reg_writes
    if (rising_edge(clk)) then  -- rising clock edge

      -- action resets
      Ctrl.LPGBT.UPLINK(0).RESET <= '0';
      Ctrl.LPGBT.UPLINK(1).RESET <= '0';
      Ctrl.LPGBT.FEC_ERR_RESET <= '0';
      Ctrl.LPGBT.DOWNLINK.RESET <= '0';
      Ctrl.LPGBT.PATTERN_CHECKER.RESET <= '0';
      Ctrl.LPGBT.PATTERN_CHECKER.CNT_RESET <= '0';
      Ctrl.ETROC_BITSLIP <= (others => '0');
      Ctrl.RESET_ETROC_RX <= (others => '0');
      Ctrl.ETROC_BITSLIP_SLAVE <= (others => '0');
      Ctrl.RESET_ETROC_RX_SLAVE <= (others => '0');
      Ctrl.SC.TX_RESET <= '0';
      Ctrl.SC.RX_RESET <= '0';
      Ctrl.SC.TX_START_WRITE <= '0';
      Ctrl.SC.TX_START_READ <= '0';
      Ctrl.SC.TX_WR <= '0';
      Ctrl.SC.START_RESET <= '0';
      Ctrl.SC.START_CONNECT <= '0';
      Ctrl.SC.START_COMMAND <= '0';
      Ctrl.SC.INJ_CRC_ERR <= '0';
      Ctrl.TX_FIFO_RESET <= '0';
      Ctrl.TX_FIFO_WR_EN <= '0';
      Ctrl.FIFO_RESET <= '0';
      Ctrl.LINK_RESET_PULSE <= '0';
      Ctrl.WS_STOP_PULSE <= '0';
      Ctrl.WS_START_PULSE <= '0';
      Ctrl.QINJ_PULSE <= '0';
      Ctrl.STP_PULSE <= '0';
      Ctrl.ECR_PULSE <= '0';
      Ctrl.BC0_PULSE <= '0';
      Ctrl.L1A_PULSE <= '0';
      Ctrl.L1A_QINJ_PULSE <= '0';
      Ctrl.PACKET_CNT_RESET <= '0';
      Ctrl.ERR_CNT_RESET <= '0';
      Ctrl.DATA_CNT_RESET <= '0';
      Ctrl.EVENT_CNT_RESET <= '0';
      


      -- Write on strobe=write=1
      if strobe_pulse='1' and wb_write = '1' then
        case to_integer(unsigned(wb_addr(10 downto 0))) is
        when 0 => --0x0
          Ctrl.LPGBT.UPLINK(0).RESET            <=  localWrData( 0);               
        when 1 => --0x1
          reg_data( 1)( 1)                      <=  localWrData( 1);                --1 = FEC12 | 0 = FEC5
        when 16 => --0x10
          Ctrl.LPGBT.UPLINK(1).RESET            <=  localWrData( 0);               
        when 17 => --0x11
          reg_data(17)( 1)                      <=  localWrData( 1);                --1 = FEC12 | 0 = FEC5
        when 31 => --0x1f
          Ctrl.LPGBT.FEC_ERR_RESET              <=  localWrData( 6);               
        when 32 => --0x20
          Ctrl.LPGBT.DOWNLINK.RESET             <=  localWrData( 0);               
        when 35 => --0x23
          reg_data(35)( 3 downto  0)            <=  localWrData( 3 downto  0);      --0=etroc, 1=upcnt, 2=prbs, 3=txfifo
        when 65 => --0x41
          Ctrl.LPGBT.PATTERN_CHECKER.RESET      <=  localWrData( 0);               
        when 66 => --0x42
          Ctrl.LPGBT.PATTERN_CHECKER.CNT_RESET  <=  localWrData( 0);               
        when 67 => --0x43
          reg_data(67)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 68 => --0x44
          reg_data(68)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 69 => --0x45
          reg_data(69)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 70 => --0x46
          reg_data(70)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 73 => --0x49
          reg_data(73)(31 downto 16)            <=  localWrData(31 downto 16);      --Channel to select for error counting
        when 260 => --0x104
          Ctrl.ETROC_BITSLIP                    <=  localWrData(31 downto  0);     
        when 261 => --0x105
          Ctrl.RESET_ETROC_RX                   <=  localWrData(31 downto  0);     
        when 262 => --0x106
          reg_data(262)(31 downto  0)           <=  localWrData(31 downto  0);      --1 to zero suppress fillers out from the ETROC RX
        when 263 => --0x107
          reg_data(263)( 0)                     <=  localWrData( 0);                --1 to enable automatic bitslipping alignment
          reg_data(263)( 3 downto  1)           <=  localWrData( 3 downto  1);      --2 = 320 Mbps, 3 = 640 Mbps, 4 = 1280 Mbps
        when 264 => --0x108
          reg_data(264)(31 downto  0)           <=  localWrData(31 downto  0);      --1 to read all data from ETROC, regardless of content
        when 265 => --0x109
          Ctrl.ETROC_BITSLIP_SLAVE              <=  localWrData(31 downto  0);     
        when 266 => --0x10a
          Ctrl.RESET_ETROC_RX_SLAVE             <=  localWrData(31 downto  0);     
        when 267 => --0x10b
          reg_data(267)(31 downto  0)           <=  localWrData(31 downto  0);      --1 to zero suppress fillers out from the ETROC RX
        when 268 => --0x10c
          reg_data(268)(31 downto  0)           <=  localWrData(31 downto  0);      --1 to read all data from ETROC, regardless of content
        when 512 => --0x200
          Ctrl.SC.TX_RESET                      <=  localWrData( 0);               
        when 513 => --0x201
          Ctrl.SC.RX_RESET                      <=  localWrData( 1);               
        when 514 => --0x202
          Ctrl.SC.TX_START_WRITE                <=  localWrData( 0);               
        when 515 => --0x203
          Ctrl.SC.TX_START_READ                 <=  localWrData( 0);               
        when 516 => --0x204
          reg_data(516)(15 downto  8)           <=  localWrData(15 downto  8);      --I2C address of the GBTx
        when 517 => --0x205
          reg_data(517)(15 downto  0)           <=  localWrData(15 downto  0);      --Address of the first register to be accessed
        when 518 => --0x206
          reg_data(518)(15 downto  0)           <=  localWrData(15 downto  0);      --Number of words/bytes to be read (only for read transactions)
          reg_data(518)(28)                     <=  localWrData(28);                --IC Frame format: 0 = lpGBT v0; 1 = lpGBT v1
        when 519 => --0x207
          reg_data(519)( 7 downto  0)           <=  localWrData( 7 downto  0);      --Data to be written into the internal FIFO
        when 521 => --0x209
          Ctrl.SC.TX_WR                         <=  localWrData( 0);               
        when 525 => --0x20d
          reg_data(525)( 7 downto  0)           <=  localWrData( 7 downto  0);      --Command: The Command field is present in the frames received by the SCA and indicates the operation to be performed. Meaning is specific to the channel.
        when 526 => --0x20e
          reg_data(526)(15 downto  8)           <=  localWrData(15 downto  8);      --Command: It represents the packet destination address. The address is one-byte long. By default, the GBT-SCA use address 0x00.
        when 527 => --0x20f
          reg_data(527)(23 downto 16)           <=  localWrData(23 downto 16);      --Command: Specifies the message identification number. The reply messages generated by the SCA have the same transaction identifier of the request message allowing to associate the transmitted commands with the corresponding replies, permitting the concurrent use of all the SCA channels.  It is not required that ID values are ordered. ID values 0x00 and 0xff are reserved for interrupt packets generated spontaneously by the SCA and should not be used in requests.
        when 528 => --0x210
          reg_data(528)(31 downto 24)           <=  localWrData(31 downto 24);      --Command: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 529 => --0x211
          reg_data(529)(31 downto  0)           <=  localWrData(31 downto  0);      --Command: data field (According to the SCA manual)
        when 540 => --0x21c
          reg_data(540)( 0)                     <=  localWrData( 0);                --Enable flag to select SCAs
        when 541 => --0x21d
          Ctrl.SC.START_RESET                   <=  localWrData( 0);               
        when 543 => --0x21f
          Ctrl.SC.START_CONNECT                 <=  localWrData( 0);               
        when 544 => --0x220
          Ctrl.SC.START_COMMAND                 <=  localWrData( 0);               
        when 545 => --0x221
          Ctrl.SC.INJ_CRC_ERR                   <=  localWrData( 0);               
        when 768 => --0x300
          reg_data(768)( 4 downto  0)           <=  localWrData( 4 downto  0);      --Choose which e-link the readout fifo connects to (0-27)
          reg_data(768)( 8)                     <=  localWrData( 8);                --Choose which lpgbt the readout fifo connects to (0-1)
        when 782 => --0x30e
          Ctrl.TX_FIFO_RESET                    <=  localWrData( 0);               
          Ctrl.TX_FIFO_WR_EN                    <=  localWrData( 1);               
        when 783 => --0x30f
          reg_data(783)( 1)                     <=  localWrData( 1);                --TX Fifo Read enable
        when 784 => --0x310
          reg_data(784)(31 downto  0)           <=  localWrData(31 downto  0);      --TX Fifo Data
        when 785 => --0x311
          Ctrl.FIFO_RESET                       <=  localWrData( 0);               
        when 1056 => --0x420
          reg_data(1056)( 0)                    <=  localWrData( 0);                --0=etroc data, 1=fixed pattern for ETROC data fifo
        when 1059 => --0x423
          reg_data(1059)(27 downto  0)          <=  localWrData(27 downto  0);      --Write a 1 to disable this ETROC from readout
        when 1060 => --0x424
          reg_data(1060)(27 downto  0)          <=  localWrData(27 downto  0);      --Write a 1 to disable this ETROC from readout
        when 1281 => --0x501
          Ctrl.LINK_RESET_PULSE                 <=  localWrData( 0);               
          Ctrl.WS_STOP_PULSE                    <=  localWrData( 1);               
          Ctrl.WS_START_PULSE                   <=  localWrData( 2);               
          Ctrl.QINJ_PULSE                       <=  localWrData( 3);               
          Ctrl.STP_PULSE                        <=  localWrData( 4);               
          Ctrl.ECR_PULSE                        <=  localWrData( 5);               
          Ctrl.BC0_PULSE                        <=  localWrData( 6);               
          Ctrl.L1A_PULSE                        <=  localWrData( 7);               
          Ctrl.L1A_QINJ_PULSE                   <=  localWrData( 8);               
        when 1282 => --0x502
          reg_data(1282)(15 downto  0)          <=  localWrData(15 downto  0);      --Number of clock cycles (40MHz) after which the L1A should be generated for a QINJ+L1A
        when 1286 => --0x506
          Ctrl.PACKET_CNT_RESET                 <=  localWrData( 0);               
          Ctrl.ERR_CNT_RESET                    <=  localWrData( 1);               
          Ctrl.DATA_CNT_RESET                   <=  localWrData( 2);               
        when 1288 => --0x508
          reg_data(1288)(31 downto  0)          <=  localWrData(31 downto  0);      --Bitmask to enable bits in the trigger link. Bits 31 downto 0.
        when 1289 => --0x509
          reg_data(1289)(31 downto  0)          <=  localWrData(31 downto  0);      --Bitmask to enable bits in the trigger link. Bits 63 downto 32.
        when 1290 => --0x50a
          reg_data(1290)(31 downto  0)          <=  localWrData(31 downto  0);      --Bitmask to enable bits in the trigger link. Bits 95 downto 64.
        when 1291 => --0x50b
          reg_data(1291)(31 downto  0)          <=  localWrData(31 downto  0);      --Bitmask to enable bits in the trigger link. Bits 127 downto 96.
        when 1292 => --0x50c
          reg_data(1292)(31 downto  0)          <=  localWrData(31 downto  0);      --Bitmask to enable bits in the trigger link. Bits 159 downto 128.
        when 1293 => --0x50d
          reg_data(1293)(31 downto  0)          <=  localWrData(31 downto  0);      --Bitmask to enable bits in the trigger link. Bits 191 downto 160.
        when 1294 => --0x50e
          reg_data(1294)(31 downto  0)          <=  localWrData(31 downto  0);      --Bitmask to enable bits in the trigger link. Bits 223 downto 192.
        when 1295 => --0x50f
          reg_data(1295)(28)                    <=  localWrData(28);                --Set to 1 to enable ETROC self trigger.
        when 1296 => --0x510
          reg_data(1296)( 4 downto  0)          <=  localWrData( 4 downto  0);      --Bitslip for ETROC0
          reg_data(1296)( 9 downto  5)          <=  localWrData( 9 downto  5);      --Bitslip for ETROC1
          reg_data(1296)(14 downto 10)          <=  localWrData(14 downto 10);      --Bitslip for ETROC2
          reg_data(1296)(19 downto 15)          <=  localWrData(19 downto 15);      --Bitslip for ETROC3
          reg_data(1296)(24 downto 20)          <=  localWrData(24 downto 20);      --Bitslip for ETROC4
          reg_data(1296)(29 downto 25)          <=  localWrData(29 downto 25);      --Bitslip for ETROC5
        when 1297 => --0x511
          reg_data(1297)( 4 downto  0)          <=  localWrData( 4 downto  0);      --Bitslip for ETROC6
          reg_data(1297)( 9 downto  5)          <=  localWrData( 9 downto  5);      --Bitslip for ETROC7
          reg_data(1297)(14 downto 10)          <=  localWrData(14 downto 10);      --Bitslip for ETROC8
          reg_data(1297)(19 downto 15)          <=  localWrData(19 downto 15);      --Bitslip for ETROC9
          reg_data(1297)(24 downto 20)          <=  localWrData(24 downto 20);      --Bitslip for ETROC10
          reg_data(1297)(29 downto 25)          <=  localWrData(29 downto 25);      --Bitslip for ETROC11
        when 1298 => --0x512
          reg_data(1298)( 4 downto  0)          <=  localWrData( 4 downto  0);      --Bitslip for ETROC12
          reg_data(1298)( 9 downto  5)          <=  localWrData( 9 downto  5);      --Bitslip for ETROC13
          reg_data(1298)(14 downto 10)          <=  localWrData(14 downto 10);      --Bitslip for ETROC14
          reg_data(1298)(19 downto 15)          <=  localWrData(19 downto 15);      --Bitslip for ETROC15
          reg_data(1298)(24 downto 20)          <=  localWrData(24 downto 20);      --Bitslip for ETROC16
          reg_data(1298)(29 downto 25)          <=  localWrData(29 downto 25);      --Bitslip for ETROC17
        when 1299 => --0x513
          reg_data(1299)( 4 downto  0)          <=  localWrData( 4 downto  0);      --Bitslip for ETROC18
          reg_data(1299)( 9 downto  5)          <=  localWrData( 9 downto  5);      --Bitslip for ETROC19
          reg_data(1299)(14 downto 10)          <=  localWrData(14 downto 10);      --Bitslip for ETROC20
          reg_data(1299)(19 downto 15)          <=  localWrData(19 downto 15);      --Bitslip for ETROC21
          reg_data(1299)(24 downto 20)          <=  localWrData(24 downto 20);      --Bitslip for ETROC22
          reg_data(1299)(29 downto 25)          <=  localWrData(29 downto 25);      --Bitslip for ETROC23
        when 1300 => --0x514
          reg_data(1300)( 4 downto  0)          <=  localWrData( 4 downto  0);      --Bitslip for ETROC24
          reg_data(1300)( 9 downto  5)          <=  localWrData( 9 downto  5);      --Bitslip for ETROC25
          reg_data(1300)(14 downto 10)          <=  localWrData(14 downto 10);      --Bitslip for ETROC26
          reg_data(1300)(19 downto 15)          <=  localWrData(19 downto 15);      --Bitslip for ETROC27
          reg_data(1300)(24 downto 20)          <=  localWrData(24 downto 20);      --Select Delay in terms of clock cycles
        when 1302 => --0x516
          Ctrl.EVENT_CNT_RESET                  <=  localWrData( 0);               

        when others => null;

        end case;
      end if; -- write

      -- synchronous reset (active high)
      if reset = '1' then
      reg_data( 0)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.UPLINK(0).RESET;
      reg_data( 1)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.UPLINK(0).FEC_MODE;
      reg_data(16)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.UPLINK(1).RESET;
      reg_data(17)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.UPLINK(1).FEC_MODE;
      reg_data(31)( 6)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.FEC_ERR_RESET;
      reg_data(32)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DOWNLINK.RESET;
      reg_data(35)( 3 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DOWNLINK.DL_SRC;
      reg_data(65)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.RESET;
      reg_data(66)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CNT_RESET;
      reg_data(67)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_0;
      reg_data(68)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_0;
      reg_data(69)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_1;
      reg_data(70)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_1;
      reg_data(73)(31 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.SEL;
      reg_data(260)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ETROC_BITSLIP;
      reg_data(261)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.RESET_ETROC_RX;
      reg_data(262)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ZERO_SUPRESS;
      reg_data(263)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.BITSLIP_AUTO_EN;
      reg_data(263)( 3 downto  1)  <= DEFAULT_READOUT_BOARD_CTRL_t.ELINK_WIDTH;
      reg_data(264)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.RAW_DATA_MODE;
      reg_data(265)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ETROC_BITSLIP_SLAVE;
      reg_data(266)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.RESET_ETROC_RX_SLAVE;
      reg_data(267)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ZERO_SUPRESS_SLAVE;
      reg_data(268)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.RAW_DATA_MODE_SLAVE;
      reg_data(512)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_RESET;
      reg_data(513)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.RX_RESET;
      reg_data(514)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_START_WRITE;
      reg_data(515)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_START_READ;
      reg_data(516)(15 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_GBTX_ADDR;
      reg_data(517)(15 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_REGISTER_ADDR;
      reg_data(518)(15 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_NUM_BYTES_TO_READ;
      reg_data(518)(28)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.FRAME_FORMAT;
      reg_data(519)( 7 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_DATA_TO_GBTX;
      reg_data(521)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_WR;
      reg_data(525)( 7 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_CMD;
      reg_data(526)(15 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_ADDRESS;
      reg_data(527)(23 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_TRANSID;
      reg_data(528)(31 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_CHANNEL;
      reg_data(529)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_DATA;
      reg_data(540)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SCA_ENABLE;
      reg_data(541)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.START_RESET;
      reg_data(543)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.START_CONNECT;
      reg_data(544)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.START_COMMAND;
      reg_data(545)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.INJ_CRC_ERR;
      reg_data(768)( 4 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.FIFO_ELINK_SEL0;
      reg_data(768)( 8)  <= DEFAULT_READOUT_BOARD_CTRL_t.FIFO_LPGBT_SEL0;
      reg_data(782)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TX_FIFO_RESET;
      reg_data(782)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.TX_FIFO_WR_EN;
      reg_data(783)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.TX_FIFO_RD_EN;
      reg_data(784)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TX_FIFO_DATA;
      reg_data(785)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.FIFO_RESET;
      reg_data(1056)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.RX_FIFO_DATA_SRC;
      reg_data(1059)(27 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ETROC_DISABLE;
      reg_data(1060)(27 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ETROC_DISABLE_SLAVE;
      reg_data(1281)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LINK_RESET_PULSE;
      reg_data(1281)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.WS_STOP_PULSE;
      reg_data(1281)( 2)  <= DEFAULT_READOUT_BOARD_CTRL_t.WS_START_PULSE;
      reg_data(1281)( 3)  <= DEFAULT_READOUT_BOARD_CTRL_t.QINJ_PULSE;
      reg_data(1281)( 4)  <= DEFAULT_READOUT_BOARD_CTRL_t.STP_PULSE;
      reg_data(1281)( 5)  <= DEFAULT_READOUT_BOARD_CTRL_t.ECR_PULSE;
      reg_data(1281)( 6)  <= DEFAULT_READOUT_BOARD_CTRL_t.BC0_PULSE;
      reg_data(1281)( 7)  <= DEFAULT_READOUT_BOARD_CTRL_t.L1A_PULSE;
      reg_data(1281)( 8)  <= DEFAULT_READOUT_BOARD_CTRL_t.L1A_QINJ_PULSE;
      reg_data(1282)(15 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.L1A_INJ_DLY;
      reg_data(1286)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.PACKET_CNT_RESET;
      reg_data(1286)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.ERR_CNT_RESET;
      reg_data(1286)( 2)  <= DEFAULT_READOUT_BOARD_CTRL_t.DATA_CNT_RESET;
      reg_data(1288)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE_MASK_0;
      reg_data(1289)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE_MASK_1;
      reg_data(1290)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE_MASK_2;
      reg_data(1291)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE_MASK_3;
      reg_data(1292)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE_MASK_4;
      reg_data(1293)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE_MASK_5;
      reg_data(1294)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE_MASK_6;
      reg_data(1295)(28)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_ENABLE;
      reg_data(1296)( 4 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_0;
      reg_data(1296)( 9 downto  5)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_1;
      reg_data(1296)(14 downto 10)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_2;
      reg_data(1296)(19 downto 15)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_3;
      reg_data(1296)(24 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_4;
      reg_data(1296)(29 downto 25)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_5;
      reg_data(1297)( 4 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_6;
      reg_data(1297)( 9 downto  5)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_7;
      reg_data(1297)(14 downto 10)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_8;
      reg_data(1297)(19 downto 15)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_9;
      reg_data(1297)(24 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_10;
      reg_data(1297)(29 downto 25)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_11;
      reg_data(1298)( 4 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_12;
      reg_data(1298)( 9 downto  5)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_13;
      reg_data(1298)(14 downto 10)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_14;
      reg_data(1298)(19 downto 15)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_15;
      reg_data(1298)(24 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_16;
      reg_data(1298)(29 downto 25)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_17;
      reg_data(1299)( 4 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_18;
      reg_data(1299)( 9 downto  5)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_19;
      reg_data(1299)(14 downto 10)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_20;
      reg_data(1299)(19 downto 15)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_21;
      reg_data(1299)(24 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_22;
      reg_data(1299)(29 downto 25)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_23;
      reg_data(1300)( 4 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_24;
      reg_data(1300)( 9 downto  5)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_25;
      reg_data(1300)(14 downto 10)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_26;
      reg_data(1300)(19 downto 15)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_BITSLIP_27;
      reg_data(1300)(24 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.TRIG_DLY_SEL;
      reg_data(1302)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.EVENT_CNT_RESET;

      end if; -- reset
    end if; -- clk
  end process reg_writes;


end architecture behavioral;