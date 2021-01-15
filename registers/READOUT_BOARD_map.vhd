--This file was auto-generated.
--Modifications might be lost.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.READOUT_BOARD_Ctrl.all;
entity READOUT_BOARD_wb_interface is
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
end entity READOUT_BOARD_wb_interface;
architecture behavioral of READOUT_BOARD_wb_interface is
  type slv32_array_t  is array (integer range <>) of std_logic_vector( 31 downto 0);
  signal localRdData : std_logic_vector (31 downto 0) := (others => '0');
  signal localWrData : std_logic_vector (31 downto 0) := (others => '0');
  signal reg_data :  slv32_array_t(integer range 0 to 537);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 537) := (others => x"00000000");
begin  -- architecture behavioral

  wb_rdata <= localRdData;
  localWrData <= wb_wdata;

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
        case to_integer(unsigned(wb_addr(9 downto 0))) is
          when 1 => --0x1
          localRdData( 0)            <=  Mon.LPGBT.DAQ.UPLINK.READY;                  --LPGBT Uplink Ready
          localRdData(31 downto 16)  <=  Mon.LPGBT.DAQ.UPLINK.FEC_ERR_CNT;            --Data Corrected Count
        when 17 => --0x11
          localRdData( 0)            <=  Mon.LPGBT.DAQ.DOWNLINK.READY;                --LPGBT Downlink Ready
        when 33 => --0x21
          localRdData( 0)            <=  Mon.LPGBT.TRIGGER.UPLINK.READY;              --LPGBT Uplink Ready
          localRdData(31 downto 16)  <=  Mon.LPGBT.TRIGGER.UPLINK.FEC_ERR_CNT;        --Data Corrected Count
        when 48 => --0x30
          localRdData( 0)            <=  reg_data(48)( 0);                            --1 to Reset Pattern Checker
        when 53 => --0x35
          localRdData(31 downto 16)  <=  reg_data(53)(31 downto 16);                  --Channel to select for error counting
        when 49 => --0x31
          localRdData(31 downto  0)  <=  reg_data(49)(31 downto  0);                  --Bitmask 1 to enable checking
        when 50 => --0x32
          localRdData(31 downto  0)  <=  reg_data(50)(31 downto  0);                  --Bitmask 1 to enable checking
        when 51 => --0x33
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.TIMER_LSBS;        --Timer of how long the counter has been running
        when 52 => --0x34
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.TIMER_MSBS;        --Timer of how long the counter has been running
        when 54 => --0x36
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.UPCNT_ERRORS;      --Errors on Upcnt
        when 55 => --0x37
          localRdData(31 downto  0)  <=  Mon.LPGBT.PATTERN_CHECKER.PRBS_ERRORS;       --Errors on Prbs
        when 514 => --0x202
          localRdData( 0)            <=  reg_data(514)( 0);                           --Request a write config to the GBTx (IC)
          localRdData( 1)            <=  reg_data(514)( 1);                           --Request a read config to the GBTx (IC)
          localRdData(15 downto  8)  <=  reg_data(514)(15 downto  8);                 --I2C address of the GBTx
        when 520 => --0x208
          localRdData( 0)            <=  Mon.SC.TX_READY;                             --IC core ready for a transaction
          localRdData( 1)            <=  Mon.SC.RX_EMPTY;                             --Rx FIFO is empty (no reply from GBTx)
        when 533 => --0x215
          localRdData( 0)            <=  reg_data(533)( 0);                           --Enable flag to select SCAs
        when 517 => --0x205
          localRdData( 7 downto  0)  <=  reg_data(517)( 7 downto  0);                 --Data to be written into the internal FIFO
          localRdData(15 downto  8)  <=  Mon.SC.RX_DATA_FROM_GBTX;                    --Data from the FIFO
        when 521 => --0x209
          localRdData( 7 downto  0)  <=  reg_data(521)( 7 downto  0);                 --Command: The Command field is present in the frames received by the SCA and indicates the operation to be performed. Meaning is specific to the channel.
          localRdData(15 downto  8)  <=  reg_data(521)(15 downto  8);                 --Command: It represents the packet destination address. The address is one-byte long. By default, the GBT-SCA use address 0x00.
          localRdData(23 downto 16)  <=  reg_data(521)(23 downto 16);                 --Command: Specifies the message identification number. The reply messages generated by the SCA have the same transaction identifier of the request message allowing to associate the transmitted commands with the corresponding replies, permitting the concurrent use of all the SCA channels.  It is not required that ID values are ordered. ID values 0x00 and 0xff are reserved for interrupt packets generated spontaneously by the SCA and should not be used in requests.
          localRdData(31 downto 24)  <=  reg_data(521)(31 downto 24);                 --Command: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 515 => --0x203
          localRdData(15 downto  0)  <=  reg_data(515)(15 downto  0);                 --Address of the first register to be accessed
        when 516 => --0x204
          localRdData(15 downto  0)  <=  reg_data(516)(15 downto  0);                 --Number of words/bytes to be read (only for read transactions)
        when 522 => --0x20a
          localRdData(31 downto  0)  <=  reg_data(522)(31 downto  0);                 --Command: data field (According to the SCA manual)
        when 523 => --0x20b
          localRdData( 7 downto  0)  <=  Mon.SC.RX.RX_LEN;                            --Reply: The length qualifier field specifies the number of bytes contained in the DATA field.
          localRdData(15 downto  8)  <=  Mon.SC.RX.RX_ADDRESS;                        --Reply: It represents the packet destination address. The address is one-bytelong. By default, the GBT-SCA use address 0x00.
          localRdData(23 downto 16)  <=  Mon.SC.RX.RX_CONTROL;                        --Reply: The control field is 1 byte in length and contains frame sequence numbers of the currently transmitted frame and the last correctly received frame. The control field is also used to convey three supervisory level commands: Connect, Reset, and Test.
          localRdData(31 downto 24)  <=  Mon.SC.RX.RX_TRANSID;                        --Reply: transaction ID field (According to the SCA manual)
        when 524 => --0x20c
          localRdData( 7 downto  0)  <=  Mon.SC.RX.RX_ERR;                            --Reply: The Error Flag field is present in the channel reply frames to indicate error conditions encountered in the execution of a command. If no errors are found, its value is 0x00.
          localRdData( 8)            <=  Mon.SC.RX.RX_RECEIVED;                       --Reply received flag (pulse)
          localRdData(19 downto 12)  <=  Mon.SC.RX.RX_CHANNEL;                        --Reply: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 525 => --0x20d
          localRdData(31 downto  0)  <=  Mon.SC.RX.RX_DATA;                           --Reply: The Data field is command dependent field whose length is defined by the length qualifier field. For example, in the case of a read/write operation on a GBT-SCA internal register, it contains the value written/read from the register.

        when others =>
          localRdData <= x"DEADDEAD";
          --wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;


  -- Register mapping to ctrl structures
  Ctrl.LPGBT.PATTERN_CHECKER.RESET           <=  reg_data(48)( 0);                
  Ctrl.LPGBT.PATTERN_CHECKER.SEL             <=  reg_data(53)(31 downto 16);      
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN   <=  reg_data(49)(31 downto  0);      
  Ctrl.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN  <=  reg_data(50)(31 downto  0);      
  Ctrl.SC.TX_START_WRITE                     <=  reg_data(514)( 0);               
  Ctrl.SC.TX_START_READ                      <=  reg_data(514)( 1);               
  Ctrl.SC.SCA_ENABLE                         <=  reg_data(533)( 0);               
  Ctrl.SC.TX_DATA_TO_GBTX                    <=  reg_data(517)( 7 downto  0);     
  Ctrl.SC.TX_CMD                             <=  reg_data(521)( 7 downto  0);     
  Ctrl.SC.TX_GBTX_ADDR                       <=  reg_data(514)(15 downto  8);     
  Ctrl.SC.TX_ADDRESS                         <=  reg_data(521)(15 downto  8);     
  Ctrl.SC.TX_REGISTER_ADDR                   <=  reg_data(515)(15 downto  0);     
  Ctrl.SC.TX_NUM_BYTES_TO_READ               <=  reg_data(516)(15 downto  0);     
  Ctrl.SC.TX_TRANSID                         <=  reg_data(521)(23 downto 16);     
  Ctrl.SC.TX_CHANNEL                         <=  reg_data(521)(31 downto 24);     
  Ctrl.SC.TX_DATA                            <=  reg_data(522)(31 downto  0);     


  -- writes to slave
  reg_writes: process (clk) is
  begin  -- process reg_writes
    if (rising_edge(clk)) then  -- rising clock edge

      Ctrl.LPGBT.DAQ.UPLINK.RESET <= '0';
      Ctrl.LPGBT.DAQ.DOWNLINK.RESET <= '0';
      Ctrl.LPGBT.TRIGGER.UPLINK.RESET <= '0';
      Ctrl.SC.TX_RESET <= '0';
      Ctrl.SC.RX_RESET <= '0';
      Ctrl.SC.TX_WR <= '0';
      Ctrl.SC.RX_RD <= '0';
      Ctrl.SC.START_RESET <= '0';
      Ctrl.SC.START_CONNECT <= '0';
      Ctrl.SC.START_COMMAND <= '0';
      Ctrl.SC.INJ_CRC_ERR <= '0';
      


      -- Write on strobe=write=1
      if wb_strobe='1' and wb_write = '1' then
        case to_integer(unsigned(wb_addr(9 downto 0))) is
        when 0 => --0x0
          Ctrl.LPGBT.DAQ.UPLINK.RESET      <=  localWrData( 0);               
        when 16 => --0x10
          Ctrl.LPGBT.DAQ.DOWNLINK.RESET    <=  localWrData( 0);               
        when 32 => --0x20
          Ctrl.LPGBT.TRIGGER.UPLINK.RESET  <=  localWrData( 0);               
        when 48 => --0x30
          reg_data(48)( 0)                 <=  localWrData( 0);                --1 to Reset Pattern Checker
        when 53 => --0x35
          reg_data(53)(31 downto 16)       <=  localWrData(31 downto 16);      --Channel to select for error counting
        when 49 => --0x31
          reg_data(49)(31 downto  0)       <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 50 => --0x32
          reg_data(50)(31 downto  0)       <=  localWrData(31 downto  0);      --Bitmask 1 to enable checking
        when 512 => --0x200
          Ctrl.SC.TX_RESET                 <=  localWrData( 0);               
        when 513 => --0x201
          Ctrl.SC.RX_RESET                 <=  localWrData( 1);               
        when 514 => --0x202
          reg_data(514)( 0)                <=  localWrData( 0);                --Request a write config to the GBTx (IC)
          reg_data(514)( 1)                <=  localWrData( 1);                --Request a read config to the GBTx (IC)
          reg_data(514)(15 downto  8)      <=  localWrData(15 downto  8);      --I2C address of the GBTx
        when 518 => --0x206
          Ctrl.SC.TX_WR                    <=  localWrData( 0);               
        when 519 => --0x207
          Ctrl.SC.RX_RD                    <=  localWrData( 0);               
        when 533 => --0x215
          reg_data(533)( 0)                <=  localWrData( 0);                --Enable flag to select SCAs
        when 534 => --0x216
          Ctrl.SC.START_RESET              <=  localWrData( 0);               
        when 535 => --0x217
          Ctrl.SC.START_CONNECT            <=  localWrData( 0);               
        when 536 => --0x218
          Ctrl.SC.START_COMMAND            <=  localWrData( 0);               
        when 537 => --0x219
          Ctrl.SC.INJ_CRC_ERR              <=  localWrData( 0);               
        when 517 => --0x205
          reg_data(517)( 7 downto  0)      <=  localWrData( 7 downto  0);      --Data to be written into the internal FIFO
        when 521 => --0x209
          reg_data(521)( 7 downto  0)      <=  localWrData( 7 downto  0);      --Command: The Command field is present in the frames received by the SCA and indicates the operation to be performed. Meaning is specific to the channel.
          reg_data(521)(15 downto  8)      <=  localWrData(15 downto  8);      --Command: It represents the packet destination address. The address is one-byte long. By default, the GBT-SCA use address 0x00.
          reg_data(521)(23 downto 16)      <=  localWrData(23 downto 16);      --Command: Specifies the message identification number. The reply messages generated by the SCA have the same transaction identifier of the request message allowing to associate the transmitted commands with the corresponding replies, permitting the concurrent use of all the SCA channels.  It is not required that ID values are ordered. ID values 0x00 and 0xff are reserved for interrupt packets generated spontaneously by the SCA and should not be used in requests.
          reg_data(521)(31 downto 24)      <=  localWrData(31 downto 24);      --Command: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 515 => --0x203
          reg_data(515)(15 downto  0)      <=  localWrData(15 downto  0);      --Address of the first register to be accessed
        when 516 => --0x204
          reg_data(516)(15 downto  0)      <=  localWrData(15 downto  0);      --Number of words/bytes to be read (only for read transactions)
        when 522 => --0x20a
          reg_data(522)(31 downto  0)      <=  localWrData(31 downto  0);      --Command: data field (According to the SCA manual)

        when others => null;

        end case;
      end if; -- write

      -- synchronous reset (active high)
      if reset = '1' then
      reg_data(48)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.RESET;
      reg_data(53)(31 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.SEL;
      reg_data(49)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN;
      reg_data(50)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN;
      reg_data(514)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_START_WRITE;
      reg_data(514)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_START_READ;
      reg_data(533)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SCA_ENABLE;
      reg_data(517)( 7 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_DATA_TO_GBTX;
      reg_data(521)( 7 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_CMD;
      reg_data(514)(15 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_GBTX_ADDR;
      reg_data(521)(15 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_ADDRESS;
      reg_data(515)(15 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_REGISTER_ADDR;
      reg_data(516)(15 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_NUM_BYTES_TO_READ;
      reg_data(521)(23 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_TRANSID;
      reg_data(521)(31 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_CHANNEL;
      reg_data(522)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.TX_DATA;

      end if; -- reset
    end if; -- clk
  end process reg_writes;


end architecture behavioral;