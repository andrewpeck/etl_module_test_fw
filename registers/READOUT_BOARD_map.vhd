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
  signal reg_data :  slv32_array_t(integer range 0 to 1286);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 1286) := (others => x"00000000");
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
          localRdData( 0)            <=  Mon.LPGBT.DAQ.UPLINK.READY;                  --LPGBT Uplink Ready
          localRdData(31 downto 16)  <=  Mon.LPGBT.DAQ.UPLINK.FEC_ERR_CNT;            --Data Corrected Count
        when 2 => --0x2
          localRdData( 2 downto  0)  <=  reg_data( 2)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data( 2)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data( 2)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data( 2)(14 downto 12);                  --
          localRdData(18 downto 16)  <=  reg_data( 2)(18 downto 16);                  --
          localRdData(22 downto 20)  <=  reg_data( 2)(22 downto 20);                  --
          localRdData(26 downto 24)  <=  reg_data( 2)(26 downto 24);                  --
          localRdData(30 downto 28)  <=  reg_data( 2)(30 downto 28);                  --
        when 3 => --0x3
          localRdData( 2 downto  0)  <=  reg_data( 3)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data( 3)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data( 3)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data( 3)(14 downto 12);                  --
          localRdData(18 downto 16)  <=  reg_data( 3)(18 downto 16);                  --
          localRdData(22 downto 20)  <=  reg_data( 3)(22 downto 20);                  --
          localRdData(26 downto 24)  <=  reg_data( 3)(26 downto 24);                  --
          localRdData(30 downto 28)  <=  reg_data( 3)(30 downto 28);                  --
        when 4 => --0x4
          localRdData( 2 downto  0)  <=  reg_data( 4)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data( 4)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data( 4)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data( 4)(14 downto 12);                  --
          localRdData(18 downto 16)  <=  reg_data( 4)(18 downto 16);                  --
          localRdData(22 downto 20)  <=  reg_data( 4)(22 downto 20);                  --
          localRdData(26 downto 24)  <=  reg_data( 4)(26 downto 24);                  --
          localRdData(30 downto 28)  <=  reg_data( 4)(30 downto 28);                  --
        when 5 => --0x5
          localRdData( 2 downto  0)  <=  reg_data( 5)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data( 5)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data( 5)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data( 5)(14 downto 12);                  --
        when 17 => --0x11
          localRdData( 0)            <=  Mon.LPGBT.DAQ.DOWNLINK.READY;                --LPGBT Downlink Ready
        when 18 => --0x12
          localRdData( 2 downto  0)  <=  reg_data(18)( 2 downto  0);                  --Downlink bitslip alignment for Group 0
          localRdData( 6 downto  4)  <=  reg_data(18)( 6 downto  4);                  --Downlink bitslip alignment for Group 1
          localRdData(10 downto  8)  <=  reg_data(18)(10 downto  8);                  --Downlink bitslip alignment for Group 2
          localRdData(14 downto 12)  <=  reg_data(18)(14 downto 12);                  --Downlink bitslip alignment for Group 3
        when 19 => --0x13
          localRdData( 3 downto  0)  <=  reg_data(19)( 3 downto  0);                  --0=etroc, 1=upcnt, 2=prbs
        when 33 => --0x21
          localRdData( 0)            <=  Mon.LPGBT.TRIGGER.UPLINK.READY;              --LPGBT Uplink Ready
          localRdData(31 downto 16)  <=  Mon.LPGBT.TRIGGER.UPLINK.FEC_ERR_CNT;        --Data Corrected Count
        when 34 => --0x22
          localRdData( 2 downto  0)  <=  reg_data(34)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data(34)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data(34)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data(34)(14 downto 12);                  --
          localRdData(18 downto 16)  <=  reg_data(34)(18 downto 16);                  --
          localRdData(22 downto 20)  <=  reg_data(34)(22 downto 20);                  --
          localRdData(26 downto 24)  <=  reg_data(34)(26 downto 24);                  --
          localRdData(30 downto 28)  <=  reg_data(34)(30 downto 28);                  --
        when 35 => --0x23
          localRdData( 2 downto  0)  <=  reg_data(35)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data(35)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data(35)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data(35)(14 downto 12);                  --
          localRdData(18 downto 16)  <=  reg_data(35)(18 downto 16);                  --
          localRdData(22 downto 20)  <=  reg_data(35)(22 downto 20);                  --
          localRdData(26 downto 24)  <=  reg_data(35)(26 downto 24);                  --
          localRdData(30 downto 28)  <=  reg_data(35)(30 downto 28);                  --
        when 36 => --0x24
          localRdData( 2 downto  0)  <=  reg_data(36)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data(36)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data(36)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data(36)(14 downto 12);                  --
          localRdData(18 downto 16)  <=  reg_data(36)(18 downto 16);                  --
          localRdData(22 downto 20)  <=  reg_data(36)(22 downto 20);                  --
          localRdData(26 downto 24)  <=  reg_data(36)(26 downto 24);                  --
          localRdData(30 downto 28)  <=  reg_data(36)(30 downto 28);                  --
        when 37 => --0x25
          localRdData( 2 downto  0)  <=  reg_data(37)( 2 downto  0);                  --
          localRdData( 6 downto  4)  <=  reg_data(37)( 6 downto  4);                  --
          localRdData(10 downto  8)  <=  reg_data(37)(10 downto  8);                  --
          localRdData(14 downto 12)  <=  reg_data(37)(14 downto 12);                  --
        when 50 => --0x32
          localRdData(31 downto  0)  <=  reg_data(50)(31 downto  0);                  --Bitmask 1 to enable checking
        when 51 => --0x33
          localRdData(31 downto  0)  <=  reg_data(51)(31 downto  0);                  --Bitmask 1 to enable checking
        when 52 => --0x34
          localRdData(31 downto  0)  <=  reg_data(52)(31 downto  0);                  --Bitmask 1 to enable checking
        when 53 => --0x35
          localRdData(31 downto  0)  <=  reg_data(53)(31 downto  0);                  --Bitmask 1 to enable checking
        when 54 => --0x36
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.TIMER_LSBS;        --Timer of how long the counter has been running
        when 55 => --0x37
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.TIMER_MSBS;        --Timer of how long the counter has been running
        when 56 => --0x38
          localRdData(31 downto 16)  <=  reg_data(56)(31 downto 16);                  --Channel to select for error counting
        when 57 => --0x39
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.UPCNT_ERRORS;      --Errors on Upcnt
        when 58 => --0x3a
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.PRBS_ERRORS;       --Errors on Prbs
        when 262 => --0x106
          localRdData(31 downto  0)  <=  reg_data(262)(31 downto  0);                 --1 to zero suppress fillers out from the ETROC RX
        when 263 => --0x107
          localRdData( 0)            <=  reg_data(263)( 0);                           --1 to enable automatic bitslipping alignment
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
        when 786 => --0x312
          localRdData(15 downto  0)  <=  Mon.RX_FIFO_LOST_WORD_CNT;                   --# of words lost to a full FIFO
        when 787 => --0x313
          localRdData( 0)            <=  Mon.RX_FIFO_FULL;                            --RX FIFO is full
        when 1056 => --0x420
          localRdData( 0)            <=  reg_data(1056)( 0);                          --0=etroc data, 1=fixed pattern for ETROC data fifo
        when 1057 => --0x421
          localRdData(27 downto  0)  <=  Mon.ETROC_LOCKED;                            --ETROC Link Locked
        when 1058 => --0x422
          localRdData(27 downto  0)  <=  Mon.ETROC_LOCKED_SLAVE;                      --ETROC Link Locked
        when 1282 => --0x502
          localRdData(31 downto  0)  <=  reg_data(1282)(31 downto  0);                --Rate of generated triggers f_trig =(2^32-1) * clk_period * rate
        when 1283 => --0x503
          localRdData(31 downto  0)  <=  Mon.L1A_RATE_CNT;                            --Measured rate of generated triggers in Hz
        when 1284 => --0x504
          localRdData(31 downto  0)  <=  Mon.PACKET_RX_RATE;                          --Measured rate of generated received packets in Hz
        when 1285 => --0x505
          localRdData(15 downto  0)  <=  Mon.PACKET_CNT;                              --Count of packets received (muxed across elinks)
          localRdData(31 downto 16)  <=  Mon.ERROR_CNT;                               --Count of packet errors (muxed across elinks)

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;


  -- Register mapping to ctrl structures
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_0                <=  reg_data( 2)( 2 downto  0);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_1                <=  reg_data( 2)( 6 downto  4);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_2                <=  reg_data( 2)(10 downto  8);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_3                <=  reg_data( 2)(14 downto 12);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_4                <=  reg_data( 2)(18 downto 16);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_5                <=  reg_data( 2)(22 downto 20);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_6                <=  reg_data( 2)(26 downto 24);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_7                <=  reg_data( 2)(30 downto 28);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_8                <=  reg_data( 3)( 2 downto  0);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_9                <=  reg_data( 3)( 6 downto  4);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_10               <=  reg_data( 3)(10 downto  8);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_11               <=  reg_data( 3)(14 downto 12);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_12               <=  reg_data( 3)(18 downto 16);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_13               <=  reg_data( 3)(22 downto 20);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_14               <=  reg_data( 3)(26 downto 24);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_15               <=  reg_data( 3)(30 downto 28);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_16               <=  reg_data( 4)( 2 downto  0);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_17               <=  reg_data( 4)( 6 downto  4);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_18               <=  reg_data( 4)(10 downto  8);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_19               <=  reg_data( 4)(14 downto 12);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_20               <=  reg_data( 4)(18 downto 16);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_21               <=  reg_data( 4)(22 downto 20);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_22               <=  reg_data( 4)(26 downto 24);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_23               <=  reg_data( 4)(30 downto 28);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_24               <=  reg_data( 5)( 2 downto  0);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_25               <=  reg_data( 5)( 6 downto  4);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_26               <=  reg_data( 5)(10 downto  8);       
  Ctrl.LPGBT.DAQ.UPLINK.ALIGN_27               <=  reg_data( 5)(14 downto 12);       
  Ctrl.LPGBT.DAQ.DOWNLINK.ALIGN_0              <=  reg_data(18)( 2 downto  0);       
  Ctrl.LPGBT.DAQ.DOWNLINK.ALIGN_1              <=  reg_data(18)( 6 downto  4);       
  Ctrl.LPGBT.DAQ.DOWNLINK.ALIGN_2              <=  reg_data(18)(10 downto  8);       
  Ctrl.LPGBT.DAQ.DOWNLINK.ALIGN_3              <=  reg_data(18)(14 downto 12);       
  Ctrl.LPGBT.DAQ.DOWNLINK.DL_SRC               <=  reg_data(19)( 3 downto  0);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_0            <=  reg_data(34)( 2 downto  0);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_1            <=  reg_data(34)( 6 downto  4);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_2            <=  reg_data(34)(10 downto  8);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_3            <=  reg_data(34)(14 downto 12);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_4            <=  reg_data(34)(18 downto 16);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_5            <=  reg_data(34)(22 downto 20);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_6            <=  reg_data(34)(26 downto 24);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_7            <=  reg_data(34)(30 downto 28);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_8            <=  reg_data(35)( 2 downto  0);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_9            <=  reg_data(35)( 6 downto  4);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_10           <=  reg_data(35)(10 downto  8);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_11           <=  reg_data(35)(14 downto 12);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_12           <=  reg_data(35)(18 downto 16);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_13           <=  reg_data(35)(22 downto 20);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_14           <=  reg_data(35)(26 downto 24);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_15           <=  reg_data(35)(30 downto 28);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_16           <=  reg_data(36)( 2 downto  0);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_17           <=  reg_data(36)( 6 downto  4);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_18           <=  reg_data(36)(10 downto  8);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_19           <=  reg_data(36)(14 downto 12);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_20           <=  reg_data(36)(18 downto 16);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_21           <=  reg_data(36)(22 downto 20);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_22           <=  reg_data(36)(26 downto 24);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_23           <=  reg_data(36)(30 downto 28);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_24           <=  reg_data(37)( 2 downto  0);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_25           <=  reg_data(37)( 6 downto  4);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_26           <=  reg_data(37)(10 downto  8);       
  Ctrl.LPGBT.TRIGGER.UPLINK.ALIGN_27           <=  reg_data(37)(14 downto 12);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_0   <=  reg_data(50)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_0  <=  reg_data(51)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_1   <=  reg_data(52)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_1  <=  reg_data(53)(31 downto  0);       
  Ctrl.LPGBT.PATTERN_CHECKER.SEL               <=  reg_data(56)(31 downto 16);       
  Ctrl.ZERO_SUPRESS                            <=  reg_data(262)(31 downto  0);      
  Ctrl.BITSLIP_AUTO_EN                         <=  reg_data(263)( 0);                
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
  Ctrl.RX_FIFO_DATA_SRC                        <=  reg_data(1056)( 0);               
  Ctrl.L1A_RATE                                <=  reg_data(1282)(31 downto  0);     


  -- writes to slave
  reg_writes: process (clk) is
  begin  -- process reg_writes
    if (rising_edge(clk)) then  -- rising clock edge

      -- action resets
      Ctrl.LPGBT.DAQ.UPLINK.RESET <= '0';
      Ctrl.LPGBT.DAQ.DOWNLINK.RESET <= '0';
      Ctrl.LPGBT.FEC_ERR_RESET <= '0';
      Ctrl.LPGBT.TRIGGER.UPLINK.RESET <= '0';
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
      Ctrl.FIFO_RESET <= '0';
      Ctrl.L1A_PULSE <= '0';
      Ctrl.LINK_RESET_PULSE <= '0';
      Ctrl.PACKET_CNT_RESET <= '0';
      Ctrl.ERR_CNT_RESET <= '0';
      


      -- Write on strobe=write=1
      if strobe_pulse='1' and wb_write = '1' then
        case to_integer(unsigned(wb_addr(10 downto 0))) is
        when 0 => --0x0
          Ctrl.LPGBT.DAQ.UPLINK.RESET           <=  localWrData( 0);               
        when 2 => --0x2
          reg_data( 2)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data( 2)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data( 2)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data( 2)(14 downto 12)            <=  localWrData(14 downto 12);      --
          reg_data( 2)(18 downto 16)            <=  localWrData(18 downto 16);      --
          reg_data( 2)(22 downto 20)            <=  localWrData(22 downto 20);      --
          reg_data( 2)(26 downto 24)            <=  localWrData(26 downto 24);      --
          reg_data( 2)(30 downto 28)            <=  localWrData(30 downto 28);      --
        when 3 => --0x3
          reg_data( 3)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data( 3)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data( 3)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data( 3)(14 downto 12)            <=  localWrData(14 downto 12);      --
          reg_data( 3)(18 downto 16)            <=  localWrData(18 downto 16);      --
          reg_data( 3)(22 downto 20)            <=  localWrData(22 downto 20);      --
          reg_data( 3)(26 downto 24)            <=  localWrData(26 downto 24);      --
          reg_data( 3)(30 downto 28)            <=  localWrData(30 downto 28);      --
        when 4 => --0x4
          reg_data( 4)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data( 4)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data( 4)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data( 4)(14 downto 12)            <=  localWrData(14 downto 12);      --
          reg_data( 4)(18 downto 16)            <=  localWrData(18 downto 16);      --
          reg_data( 4)(22 downto 20)            <=  localWrData(22 downto 20);      --
          reg_data( 4)(26 downto 24)            <=  localWrData(26 downto 24);      --
          reg_data( 4)(30 downto 28)            <=  localWrData(30 downto 28);      --
        when 5 => --0x5
          reg_data( 5)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data( 5)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data( 5)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data( 5)(14 downto 12)            <=  localWrData(14 downto 12);      --
        when 16 => --0x10
          Ctrl.LPGBT.DAQ.DOWNLINK.RESET         <=  localWrData( 0);               
        when 18 => --0x12
          reg_data(18)( 2 downto  0)            <=  localWrData( 2 downto  0);      --Downlink bitslip alignment for Group 0
          reg_data(18)( 6 downto  4)            <=  localWrData( 6 downto  4);      --Downlink bitslip alignment for Group 1
          reg_data(18)(10 downto  8)            <=  localWrData(10 downto  8);      --Downlink bitslip alignment for Group 2
          reg_data(18)(14 downto 12)            <=  localWrData(14 downto 12);      --Downlink bitslip alignment for Group 3
        when 19 => --0x13
          reg_data(19)( 3 downto  0)            <=  localWrData( 3 downto  0);      --0=etroc, 1=upcnt, 2=prbs
        when 31 => --0x1f
          Ctrl.LPGBT.FEC_ERR_RESET              <=  localWrData( 0);               
        when 32 => --0x20
          Ctrl.LPGBT.TRIGGER.UPLINK.RESET       <=  localWrData( 0);               
        when 34 => --0x22
          reg_data(34)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data(34)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data(34)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data(34)(14 downto 12)            <=  localWrData(14 downto 12);      --
          reg_data(34)(18 downto 16)            <=  localWrData(18 downto 16);      --
          reg_data(34)(22 downto 20)            <=  localWrData(22 downto 20);      --
          reg_data(34)(26 downto 24)            <=  localWrData(26 downto 24);      --
          reg_data(34)(30 downto 28)            <=  localWrData(30 downto 28);      --
        when 35 => --0x23
          reg_data(35)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data(35)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data(35)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data(35)(14 downto 12)            <=  localWrData(14 downto 12);      --
          reg_data(35)(18 downto 16)            <=  localWrData(18 downto 16);      --
          reg_data(35)(22 downto 20)            <=  localWrData(22 downto 20);      --
          reg_data(35)(26 downto 24)            <=  localWrData(26 downto 24);      --
          reg_data(35)(30 downto 28)            <=  localWrData(30 downto 28);      --
        when 36 => --0x24
          reg_data(36)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data(36)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data(36)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data(36)(14 downto 12)            <=  localWrData(14 downto 12);      --
          reg_data(36)(18 downto 16)            <=  localWrData(18 downto 16);      --
          reg_data(36)(22 downto 20)            <=  localWrData(22 downto 20);      --
          reg_data(36)(26 downto 24)            <=  localWrData(26 downto 24);      --
          reg_data(36)(30 downto 28)            <=  localWrData(30 downto 28);      --
        when 37 => --0x25
          reg_data(37)( 2 downto  0)            <=  localWrData( 2 downto  0);      --
          reg_data(37)( 6 downto  4)            <=  localWrData( 6 downto  4);      --
          reg_data(37)(10 downto  8)            <=  localWrData(10 downto  8);      --
          reg_data(37)(14 downto 12)            <=  localWrData(14 downto 12);      --
        when 48 => --0x30
          Ctrl.LPGBT.PATTERN_CHECKER.RESET      <=  localWrData( 0);               
        when 49 => --0x31
          Ctrl.LPGBT.PATTERN_CHECKER.CNT_RESET  <=  localWrData( 0);               
        when 50 => --0x32
          reg_data(50)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 51 => --0x33
          reg_data(51)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 52 => --0x34
          reg_data(52)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 53 => --0x35
          reg_data(53)(31 downto  0)            <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 56 => --0x38
          reg_data(56)(31 downto 16)            <=  localWrData(31 downto 16);      --Channel to select for error counting
        when 260 => --0x104
          Ctrl.ETROC_BITSLIP                    <=  localWrData(31 downto  0);     
        when 261 => --0x105
          Ctrl.RESET_ETROC_RX                   <=  localWrData(31 downto  0);     
        when 262 => --0x106
          reg_data(262)(31 downto  0)           <=  localWrData(31 downto  0);      --1 to zero suppress fillers out from the ETROC RX
        when 263 => --0x107
          reg_data(263)( 0)                     <=  localWrData( 0);                --1 to enable automatic bitslipping alignment
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
        when 785 => --0x311
          Ctrl.FIFO_RESET                       <=  localWrData( 0);               
        when 1056 => --0x420
          reg_data(1056)( 0)                    <=  localWrData( 0);                --0=etroc data, 1=fixed pattern for ETROC data fifo
        when 1280 => --0x500
          Ctrl.L1A_PULSE                        <=  localWrData( 0);               
        when 1281 => --0x501
          Ctrl.LINK_RESET_PULSE                 <=  localWrData( 0);               
        when 1282 => --0x502
          reg_data(1282)(31 downto  0)          <=  localWrData(31 downto  0);      --Rate of generated triggers f_trig =(2^32-1) * clk_period * rate
        when 1286 => --0x506
          Ctrl.PACKET_CNT_RESET                 <=  localWrData( 0);               
          Ctrl.ERR_CNT_RESET                    <=  localWrData( 1);               

        when others => null;

        end case;
      end if; -- write

      -- synchronous reset (active high)
      if reset = '1' then
      reg_data( 0)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.RESET;
      reg_data( 2)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_0;
      reg_data( 2)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_1;
      reg_data( 2)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_2;
      reg_data( 2)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_3;
      reg_data( 2)(18 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_4;
      reg_data( 2)(22 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_5;
      reg_data( 2)(26 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_6;
      reg_data( 2)(30 downto 28)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_7;
      reg_data( 3)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_8;
      reg_data( 3)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_9;
      reg_data( 3)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_10;
      reg_data( 3)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_11;
      reg_data( 3)(18 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_12;
      reg_data( 3)(22 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_13;
      reg_data( 3)(26 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_14;
      reg_data( 3)(30 downto 28)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_15;
      reg_data( 4)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_16;
      reg_data( 4)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_17;
      reg_data( 4)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_18;
      reg_data( 4)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_19;
      reg_data( 4)(18 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_20;
      reg_data( 4)(22 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_21;
      reg_data( 4)(26 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_22;
      reg_data( 4)(30 downto 28)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_23;
      reg_data( 5)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_24;
      reg_data( 5)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_25;
      reg_data( 5)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_26;
      reg_data( 5)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.UPLINK.ALIGN_27;
      reg_data(16)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.DOWNLINK.RESET;
      reg_data(18)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.DOWNLINK.ALIGN_0;
      reg_data(18)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.DOWNLINK.ALIGN_1;
      reg_data(18)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.DOWNLINK.ALIGN_2;
      reg_data(18)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.DOWNLINK.ALIGN_3;
      reg_data(19)( 3 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.DAQ.DOWNLINK.DL_SRC;
      reg_data(31)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.FEC_ERR_RESET;
      reg_data(32)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.RESET;
      reg_data(34)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_0;
      reg_data(34)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_1;
      reg_data(34)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_2;
      reg_data(34)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_3;
      reg_data(34)(18 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_4;
      reg_data(34)(22 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_5;
      reg_data(34)(26 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_6;
      reg_data(34)(30 downto 28)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_7;
      reg_data(35)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_8;
      reg_data(35)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_9;
      reg_data(35)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_10;
      reg_data(35)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_11;
      reg_data(35)(18 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_12;
      reg_data(35)(22 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_13;
      reg_data(35)(26 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_14;
      reg_data(35)(30 downto 28)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_15;
      reg_data(36)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_16;
      reg_data(36)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_17;
      reg_data(36)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_18;
      reg_data(36)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_19;
      reg_data(36)(18 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_20;
      reg_data(36)(22 downto 20)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_21;
      reg_data(36)(26 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_22;
      reg_data(36)(30 downto 28)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_23;
      reg_data(37)( 2 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_24;
      reg_data(37)( 6 downto  4)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_25;
      reg_data(37)(10 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_26;
      reg_data(37)(14 downto 12)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.TRIGGER.UPLINK.ALIGN_27;
      reg_data(48)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.RESET;
      reg_data(49)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CNT_RESET;
      reg_data(50)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_0;
      reg_data(51)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_0;
      reg_data(52)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_1;
      reg_data(53)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_1;
      reg_data(56)(31 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.SEL;
      reg_data(260)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ETROC_BITSLIP;
      reg_data(261)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.RESET_ETROC_RX;
      reg_data(262)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.ZERO_SUPRESS;
      reg_data(263)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.BITSLIP_AUTO_EN;
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
      reg_data(785)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.FIFO_RESET;
      reg_data(1056)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.RX_FIFO_DATA_SRC;
      reg_data(1280)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.L1A_PULSE;
      reg_data(1281)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LINK_RESET_PULSE;
      reg_data(1282)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.L1A_RATE;
      reg_data(1286)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.PACKET_CNT_RESET;
      reg_data(1286)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.ERR_CNT_RESET;

      end if; -- reset
    end if; -- clk
  end process reg_writes;


end architecture behavioral;