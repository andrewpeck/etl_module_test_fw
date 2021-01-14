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
  signal reg_data :  slv32_array_t(integer range 0 to 56);
  constant DEFAULT_REG_DATA : slv32_array_t(integer range 0 to 56) := (others => x"00000000");
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
        case to_integer(unsigned(wb_addr(5 downto 0))) is
          when 1 => --0x1
          localRdData( 0)            <=  Mon.LPGBT.UPLINK.UPLINK(0).READY;            --LPGBT Uplink Ready
          localRdData(31 downto 16)  <=  Mon.LPGBT.UPLINK.UPLINK(0).FEC_ERR_CNT;      --Data Corrected Count
        when 6 => --0x6
          localRdData( 0)            <=  Mon.LPGBT.UPLINK.UPLINK(1).READY;            --LPGBT Uplink Ready
          localRdData(31 downto 16)  <=  Mon.LPGBT.UPLINK.UPLINK(1).FEC_ERR_CNT;      --Data Corrected Count
        when 12 => --0xc
          localRdData( 0)            <=  Mon.LPGBT.DOWNLINK.READY;                    --LPGBT Downlink Ready
        when 18 => --0x12
          localRdData( 0)            <=  reg_data(18)( 0);                            --Request a write config to the GBTx (IC)
          localRdData( 1)            <=  reg_data(18)( 1);                            --Request a read config to the GBTx (IC)
          localRdData(15 downto  8)  <=  reg_data(18)(15 downto  8);                  --I2C address of the GBTx
        when 24 => --0x18
          localRdData( 0)            <=  Mon.SC.MASTER.TX_READY;                      --IC core ready for a transaction
          localRdData( 1)            <=  Mon.SC.MASTER.RX_EMPTY;                      --Rx FIFO is empty (no reply from GBTx)
        when 37 => --0x25
          localRdData( 0)            <=  reg_data(37)( 0);                            --Enable flag to select SCAs
        when 21 => --0x15
          localRdData( 7 downto  0)  <=  reg_data(21)( 7 downto  0);                  --Data to be written into the internal FIFO
          localRdData(15 downto  8)  <=  Mon.SC.MASTER.RX_DATA_FROM_GBTX;             --Data from the FIFO
        when 25 => --0x19
          localRdData( 7 downto  0)  <=  reg_data(25)( 7 downto  0);                  --Command: The Command field is present in the frames received by the SCA and indicates the operation to be performed. Meaning is specific to the channel.
          localRdData(15 downto  8)  <=  reg_data(25)(15 downto  8);                  --Command: It represents the packet destination address. The address is one-byte long. By default, the GBT-SCA use address 0x00.
          localRdData(23 downto 16)  <=  reg_data(25)(23 downto 16);                  --Command: Specifies the message identification number. The reply messages generated by the SCA have the same transaction identifier of the request message allowing to associate the transmitted commands with the corresponding replies, permitting the concurrent use of all the SCA channels.  It is not required that ID values are ordered. ID values 0x00 and 0xff are reserved for interrupt packets generated spontaneously by the SCA and should not be used in requests.
          localRdData(31 downto 24)  <=  reg_data(25)(31 downto 24);                  --Command: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 19 => --0x13
          localRdData(31 downto 16)  <=  reg_data(19)(31 downto 16);                  --Address of the first register to be accessed
        when 20 => --0x14
          localRdData(31 downto 16)  <=  reg_data(20)(31 downto 16);                  --Number of words/bytes to be read (only for read transactions)
        when 26 => --0x1a
          localRdData(31 downto  0)  <=  reg_data(26)(31 downto  0);                  --Command: data field (According to the SCA manual)
        when 27 => --0x1b
          localRdData( 7 downto  0)  <=  Mon.SC.MASTER.RX.RX(0).RX_LEN;               --Reply: The length qualifier field specifies the number of bytes contained in the DATA field.
          localRdData(15 downto  8)  <=  Mon.SC.MASTER.RX.RX(0).RX_ADDRESS;           --Reply: It represents the packet destination address. The address is one-bytelong. By default, the GBT-SCA use address 0x00.
          localRdData(23 downto 16)  <=  Mon.SC.MASTER.RX.RX(0).RX_CONTROL;           --Reply: The control field is 1 byte in length and contains frame sequence numbers of the currently transmitted frame and the last correctly received frame. The control field is also used to convey three supervisory level commands: Connect, Reset, and Test.
          localRdData(31 downto 24)  <=  Mon.SC.MASTER.RX.RX(0).RX_TRANSID;           --Reply: transaction ID field (According to the SCA manual)
        when 28 => --0x1c
          localRdData( 7 downto  0)  <=  Mon.SC.MASTER.RX.RX(0).RX_ERR;               --Reply: The Error Flag field is present in the channel reply frames to indicate error conditions encountered in the execution of a command. If no errors are found, its value is 0x00.
          localRdData( 8)            <=  Mon.SC.MASTER.RX.RX(0).RX_RECEIVED;          --Reply received flag (pulse)
          localRdData(19 downto 12)  <=  Mon.SC.MASTER.RX.RX(0).RX_CHANNEL;           --Reply: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 29 => --0x1d
          localRdData(31 downto  0)  <=  Mon.SC.MASTER.RX.RX(0).RX_DATA;              --Reply: The Data field is command dependent field whose length is defined by the length qualifier field. For example, in the case of a read/write operation on a GBT-SCA internal register, it contains the value written/read from the register.
        when 50 => --0x32
          localRdData( 0)            <=  reg_data(50)( 0);                            --Request a write config to the GBTx (IC)
          localRdData( 1)            <=  reg_data(50)( 1);                            --Request a read config to the GBTx (IC)
          localRdData(15 downto  8)  <=  reg_data(50)(15 downto  8);                  --I2C address of the GBTx
        when 56 => --0x38
          localRdData( 0)            <=  Mon.SC.SLAVE.TX_READY;                       --IC core ready for a transaction
          localRdData( 1)            <=  Mon.SC.SLAVE.RX_EMPTY;                       --Rx FIFO is empty (no reply from GBTx)
        when 53 => --0x35
          localRdData( 7 downto  0)  <=  reg_data(53)( 7 downto  0);                  --Data to be written into the internal FIFO
          localRdData(15 downto  8)  <=  Mon.SC.SLAVE.RX_DATA_FROM_GBTX;              --Data from the FIFO
        when 51 => --0x33
          localRdData(31 downto 16)  <=  reg_data(51)(31 downto 16);                  --Address of the first register to be accessed
        when 52 => --0x34
          localRdData(31 downto 16)  <=  reg_data(52)(31 downto 16);                  --Number of words/bytes to be read (only for read transactions)

        when others =>
          localRdData <= x"DEADDEAD";
          wb_err <= '1';
        end case;
      end if;
    end if;
  end process reads;


  -- Register mapping to ctrl structures
  Ctrl.SC.MASTER.TX_START_WRITE        <=  reg_data(18)( 0);               
  Ctrl.SC.MASTER.TX_START_READ         <=  reg_data(18)( 1);               
  Ctrl.SC.MASTER.SCA_ENABLE            <=  reg_data(37)( 0);               
  Ctrl.SC.MASTER.TX_DATA_TO_GBTX       <=  reg_data(21)( 7 downto  0);     
  Ctrl.SC.MASTER.TX_CMD                <=  reg_data(25)( 7 downto  0);     
  Ctrl.SC.MASTER.TX_GBTX_ADDR          <=  reg_data(18)(15 downto  8);     
  Ctrl.SC.MASTER.TX_ADDRESS            <=  reg_data(25)(15 downto  8);     
  Ctrl.SC.MASTER.TX_TRANSID            <=  reg_data(25)(23 downto 16);     
  Ctrl.SC.MASTER.TX_CHANNEL            <=  reg_data(25)(31 downto 24);     
  Ctrl.SC.MASTER.TX_REGISTER_ADDR      <=  reg_data(19)(31 downto 16);     
  Ctrl.SC.MASTER.TX_NUM_BYTES_TO_READ  <=  reg_data(20)(31 downto 16);     
  Ctrl.SC.MASTER.TX_DATA               <=  reg_data(26)(31 downto  0);     
  Ctrl.SC.SLAVE.TX_START_WRITE         <=  reg_data(50)( 0);               
  Ctrl.SC.SLAVE.TX_START_READ          <=  reg_data(50)( 1);               
  Ctrl.SC.SLAVE.TX_DATA_TO_GBTX        <=  reg_data(53)( 7 downto  0);     
  Ctrl.SC.SLAVE.TX_GBTX_ADDR           <=  reg_data(50)(15 downto  8);     
  Ctrl.SC.SLAVE.TX_REGISTER_ADDR       <=  reg_data(51)(31 downto 16);     
  Ctrl.SC.SLAVE.TX_NUM_BYTES_TO_READ   <=  reg_data(52)(31 downto 16);     


  -- writes to slave
  reg_writes: process (clk) is
  begin  -- process reg_writes
    if (rising_edge(clk)) then  -- rising clock edge

      -- Write on strobe=write=1
      if wb_strobe='1' and wb_write = '1' then
        case to_integer(unsigned(wb_addr(5 downto 0))) is
        when 0 => --0x0
          Ctrl.LPGBT.UPLINK.UPLINK(0).RESET  <=  localWrData( 0);               
        when 5 => --0x5
          Ctrl.LPGBT.UPLINK.UPLINK(1).RESET  <=  localWrData( 0);               
        when 11 => --0xb
          Ctrl.LPGBT.DOWNLINK.RESET          <=  localWrData( 0);               
        when 16 => --0x10
          Ctrl.SC.MASTER.TX_RESET            <=  localWrData( 0);               
        when 17 => --0x11
          Ctrl.SC.MASTER.RX_RESET            <=  localWrData( 1);               
        when 18 => --0x12
          reg_data(18)( 0)                   <=  localWrData( 0);                --Request a write config to the GBTx (IC)
          reg_data(18)( 1)                   <=  localWrData( 1);                --Request a read config to the GBTx (IC)
          reg_data(18)(15 downto  8)         <=  localWrData(15 downto  8);      --I2C address of the GBTx
        when 22 => --0x16
          Ctrl.SC.MASTER.TX_WR               <=  localWrData( 0);               
        when 23 => --0x17
          Ctrl.SC.MASTER.RX_RD               <=  localWrData( 0);               
        when 37 => --0x25
          reg_data(37)( 0)                   <=  localWrData( 0);                --Enable flag to select SCAs
        when 38 => --0x26
          Ctrl.SC.MASTER.START_RESET         <=  localWrData( 0);               
        when 39 => --0x27
          Ctrl.SC.MASTER.START_CONNECT       <=  localWrData( 0);               
        when 40 => --0x28
          Ctrl.SC.MASTER.START_COMMAND       <=  localWrData( 0);               
        when 41 => --0x29
          Ctrl.SC.MASTER.INJ_CRC_ERR         <=  localWrData( 0);               
        when 21 => --0x15
          reg_data(21)( 7 downto  0)         <=  localWrData( 7 downto  0);      --Data to be written into the internal FIFO
        when 25 => --0x19
          reg_data(25)( 7 downto  0)         <=  localWrData( 7 downto  0);      --Command: The Command field is present in the frames received by the SCA and indicates the operation to be performed. Meaning is specific to the channel.
          reg_data(25)(15 downto  8)         <=  localWrData(15 downto  8);      --Command: It represents the packet destination address. The address is one-byte long. By default, the GBT-SCA use address 0x00.
          reg_data(25)(23 downto 16)         <=  localWrData(23 downto 16);      --Command: Specifies the message identification number. The reply messages generated by the SCA have the same transaction identifier of the request message allowing to associate the transmitted commands with the corresponding replies, permitting the concurrent use of all the SCA channels.  It is not required that ID values are ordered. ID values 0x00 and 0xff are reserved for interrupt packets generated spontaneously by the SCA and should not be used in requests.
          reg_data(25)(31 downto 24)         <=  localWrData(31 downto 24);      --Command: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
        when 19 => --0x13
          reg_data(19)(31 downto 16)         <=  localWrData(31 downto 16);      --Address of the first register to be accessed
        when 20 => --0x14
          reg_data(20)(31 downto 16)         <=  localWrData(31 downto 16);      --Number of words/bytes to be read (only for read transactions)
        when 26 => --0x1a
          reg_data(26)(31 downto  0)         <=  localWrData(31 downto  0);      --Command: data field (According to the SCA manual)
        when 48 => --0x30
          Ctrl.SC.SLAVE.TX_RESET             <=  localWrData( 0);               
        when 49 => --0x31
          Ctrl.SC.SLAVE.RX_RESET             <=  localWrData( 1);               
        when 50 => --0x32
          reg_data(50)( 0)                   <=  localWrData( 0);                --Request a write config to the GBTx (IC)
          reg_data(50)( 1)                   <=  localWrData( 1);                --Request a read config to the GBTx (IC)
          reg_data(50)(15 downto  8)         <=  localWrData(15 downto  8);      --I2C address of the GBTx
        when 54 => --0x36
          Ctrl.SC.SLAVE.TX_WR                <=  localWrData( 0);               
        when 55 => --0x37
          Ctrl.SC.SLAVE.RX_RD                <=  localWrData( 0);               
        when 53 => --0x35
          reg_data(53)( 7 downto  0)         <=  localWrData( 7 downto  0);      --Data to be written into the internal FIFO
        when 51 => --0x33
          reg_data(51)(31 downto 16)         <=  localWrData(31 downto 16);      --Address of the first register to be accessed
        when 52 => --0x34
          reg_data(52)(31 downto 16)         <=  localWrData(31 downto 16);      --Number of words/bytes to be read (only for read transactions)

        when others => null;

        end case;
      end if; -- write

      -- synchronous reset (active high)
      if reset = '1' then
      reg_data(18)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_START_WRITE;
      reg_data(18)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_START_READ;
      reg_data(37)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.SCA_ENABLE;
      reg_data(21)( 7 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_DATA_TO_GBTX;
      reg_data(25)( 7 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_CMD;
      reg_data(18)(15 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_GBTX_ADDR;
      reg_data(25)(15 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_ADDRESS;
      reg_data(25)(23 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_TRANSID;
      reg_data(25)(31 downto 24)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_CHANNEL;
      reg_data(19)(31 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_REGISTER_ADDR;
      reg_data(20)(31 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_NUM_BYTES_TO_READ;
      reg_data(26)(31 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.MASTER.TX_DATA;
      reg_data(50)( 0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SLAVE.TX_START_WRITE;
      reg_data(50)( 1)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SLAVE.TX_START_READ;
      reg_data(53)( 7 downto  0)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SLAVE.TX_DATA_TO_GBTX;
      reg_data(50)(15 downto  8)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SLAVE.TX_GBTX_ADDR;
      reg_data(51)(31 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SLAVE.TX_REGISTER_ADDR;
      reg_data(52)(31 downto 16)  <= DEFAULT_READOUT_BOARD_CTRL_t.SC.SLAVE.TX_NUM_BYTES_TO_READ;

      Ctrl.LPGBT.UPLINK.UPLINK(0).RESET <= '0';
      Ctrl.LPGBT.UPLINK.UPLINK(1).RESET <= '0';
      Ctrl.LPGBT.DOWNLINK.RESET <= '0';
      Ctrl.SC.MASTER.TX_RESET <= '0';
      Ctrl.SC.MASTER.RX_RESET <= '0';
      Ctrl.SC.MASTER.TX_WR <= '0';
      Ctrl.SC.MASTER.RX_RD <= '0';
      Ctrl.SC.MASTER.START_RESET <= '0';
      Ctrl.SC.MASTER.START_CONNECT <= '0';
      Ctrl.SC.MASTER.START_COMMAND <= '0';
      Ctrl.SC.MASTER.INJ_CRC_ERR <= '0';
      Ctrl.SC.SLAVE.TX_RESET <= '0';
      Ctrl.SC.SLAVE.RX_RESET <= '0';
      Ctrl.SC.SLAVE.TX_WR <= '0';
      Ctrl.SC.SLAVE.RX_RD <= '0';
      

      Ctrl.LPGBT.UPLINK.UPLINK(0).RESET <= '0';
      Ctrl.LPGBT.UPLINK.UPLINK(1).RESET <= '0';
      Ctrl.LPGBT.DOWNLINK.RESET <= '0';
      Ctrl.SC.MASTER.TX_RESET <= '0';
      Ctrl.SC.MASTER.RX_RESET <= '0';
      Ctrl.SC.MASTER.TX_WR <= '0';
      Ctrl.SC.MASTER.RX_RD <= '0';
      Ctrl.SC.MASTER.START_RESET <= '0';
      Ctrl.SC.MASTER.START_CONNECT <= '0';
      Ctrl.SC.MASTER.START_COMMAND <= '0';
      Ctrl.SC.MASTER.INJ_CRC_ERR <= '0';
      Ctrl.SC.SLAVE.TX_RESET <= '0';
      Ctrl.SC.SLAVE.RX_RESET <= '0';
      Ctrl.SC.SLAVE.TX_WR <= '0';
      Ctrl.SC.SLAVE.RX_RD <= '0';
      

      end if; -- reset
    end if; -- clk
  end process reg_writes;


end architecture behavioral;