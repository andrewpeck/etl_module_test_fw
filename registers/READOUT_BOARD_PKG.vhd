--This file was auto-generated.
--Modifications might be lost.
library IEEE;
use IEEE.std_logic_1164.all;


package READOUT_BOARD_CTRL is
  type READOUT_BOARD_LPGBT_DAQ_UPLINK_MON_t is record
    READY                      :std_logic;     -- LPGBT Uplink Ready
    FEC_ERR_CNT                :std_logic_vector(15 downto 0);  -- Data Corrected Count
  end record READOUT_BOARD_LPGBT_DAQ_UPLINK_MON_t;


  type READOUT_BOARD_LPGBT_DAQ_UPLINK_CTRL_t is record
    RESET                      :std_logic;     -- Reset this Uplink
    ALIGN_0                    :std_logic_vector( 2 downto 0);
    ALIGN_1                    :std_logic_vector( 2 downto 0);
    ALIGN_2                    :std_logic_vector( 2 downto 0);
    ALIGN_3                    :std_logic_vector( 2 downto 0);
    ALIGN_4                    :std_logic_vector( 2 downto 0);
    ALIGN_5                    :std_logic_vector( 2 downto 0);
    ALIGN_6                    :std_logic_vector( 2 downto 0);
    ALIGN_7                    :std_logic_vector( 2 downto 0);
    ALIGN_8                    :std_logic_vector( 2 downto 0);
    ALIGN_9                    :std_logic_vector( 2 downto 0);
    ALIGN_10                   :std_logic_vector( 2 downto 0);
    ALIGN_11                   :std_logic_vector( 2 downto 0);
    ALIGN_12                   :std_logic_vector( 2 downto 0);
    ALIGN_13                   :std_logic_vector( 2 downto 0);
    ALIGN_14                   :std_logic_vector( 2 downto 0);
    ALIGN_15                   :std_logic_vector( 2 downto 0);
    ALIGN_16                   :std_logic_vector( 2 downto 0);
    ALIGN_17                   :std_logic_vector( 2 downto 0);
    ALIGN_18                   :std_logic_vector( 2 downto 0);
    ALIGN_19                   :std_logic_vector( 2 downto 0);
    ALIGN_20                   :std_logic_vector( 2 downto 0);
    ALIGN_21                   :std_logic_vector( 2 downto 0);
    ALIGN_22                   :std_logic_vector( 2 downto 0);
    ALIGN_23                   :std_logic_vector( 2 downto 0);
    ALIGN_24                   :std_logic_vector( 2 downto 0);
    ALIGN_25                   :std_logic_vector( 2 downto 0);
    ALIGN_26                   :std_logic_vector( 2 downto 0);
    ALIGN_27                   :std_logic_vector( 2 downto 0);
  end record READOUT_BOARD_LPGBT_DAQ_UPLINK_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_DAQ_UPLINK_CTRL_t : READOUT_BOARD_LPGBT_DAQ_UPLINK_CTRL_t := (
                                                                                                     RESET => '0',
                                                                                                     ALIGN_0 => (others => '0'),
                                                                                                     ALIGN_1 => (others => '0'),
                                                                                                     ALIGN_2 => (others => '0'),
                                                                                                     ALIGN_3 => (others => '0'),
                                                                                                     ALIGN_4 => (others => '0'),
                                                                                                     ALIGN_5 => (others => '0'),
                                                                                                     ALIGN_6 => (others => '0'),
                                                                                                     ALIGN_7 => (others => '0'),
                                                                                                     ALIGN_8 => (others => '0'),
                                                                                                     ALIGN_9 => (others => '0'),
                                                                                                     ALIGN_10 => (others => '0'),
                                                                                                     ALIGN_11 => (others => '0'),
                                                                                                     ALIGN_12 => (others => '0'),
                                                                                                     ALIGN_13 => (others => '0'),
                                                                                                     ALIGN_14 => (others => '0'),
                                                                                                     ALIGN_15 => (others => '0'),
                                                                                                     ALIGN_16 => (others => '0'),
                                                                                                     ALIGN_17 => (others => '0'),
                                                                                                     ALIGN_18 => (others => '0'),
                                                                                                     ALIGN_19 => (others => '0'),
                                                                                                     ALIGN_20 => (others => '0'),
                                                                                                     ALIGN_21 => (others => '0'),
                                                                                                     ALIGN_22 => (others => '0'),
                                                                                                     ALIGN_23 => (others => '0'),
                                                                                                     ALIGN_24 => (others => '0'),
                                                                                                     ALIGN_25 => (others => '0'),
                                                                                                     ALIGN_26 => (others => '0'),
                                                                                                     ALIGN_27 => (others => '0')
                                                                                                    );
  type READOUT_BOARD_LPGBT_DAQ_DOWNLINK_MON_t is record
    READY                      :std_logic;     -- LPGBT Downlink Ready
  end record READOUT_BOARD_LPGBT_DAQ_DOWNLINK_MON_t;


  type READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t is record
    RESET                      :std_logic;     -- Reset this Downlink LpGBT Encoder
    ALIGN_0                    :std_logic_vector( 2 downto 0);  -- Downlink bitslip alignment for Group 0
    ALIGN_1                    :std_logic_vector( 2 downto 0);  -- Downlink bitslip alignment for Group 1
    ALIGN_2                    :std_logic_vector( 2 downto 0);  -- Downlink bitslip alignment for Group 2
    ALIGN_3                    :std_logic_vector( 2 downto 0);  -- Downlink bitslip alignment for Group 3
    DL_SRC                     :std_logic_vector( 3 downto 0);  -- 0=etroc, 1=upcnt, 2=prbs
  end record READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t : READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t := (
                                                                                                         RESET => '0',
                                                                                                         ALIGN_0 => (others => '0'),
                                                                                                         ALIGN_1 => (others => '0'),
                                                                                                         ALIGN_2 => (others => '0'),
                                                                                                         ALIGN_3 => (others => '0'),
                                                                                                         DL_SRC => (others => '0')
                                                                                                        );
  type READOUT_BOARD_LPGBT_DAQ_MON_t is record
    UPLINK                     :READOUT_BOARD_LPGBT_DAQ_UPLINK_MON_t;
    DOWNLINK                   :READOUT_BOARD_LPGBT_DAQ_DOWNLINK_MON_t;
  end record READOUT_BOARD_LPGBT_DAQ_MON_t;


  type READOUT_BOARD_LPGBT_DAQ_CTRL_t is record
    UPLINK                     :READOUT_BOARD_LPGBT_DAQ_UPLINK_CTRL_t;
    DOWNLINK                   :READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t;
  end record READOUT_BOARD_LPGBT_DAQ_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_DAQ_CTRL_t : READOUT_BOARD_LPGBT_DAQ_CTRL_t := (
                                                                                       UPLINK => DEFAULT_READOUT_BOARD_LPGBT_DAQ_UPLINK_CTRL_t,
                                                                                       DOWNLINK => DEFAULT_READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t
                                                                                      );
  type READOUT_BOARD_LPGBT_TRIGGER_UPLINK_MON_t is record
    READY                      :std_logic;     -- LPGBT Uplink Ready
    FEC_ERR_CNT                :std_logic_vector(15 downto 0);  -- Data Corrected Count
  end record READOUT_BOARD_LPGBT_TRIGGER_UPLINK_MON_t;


  type READOUT_BOARD_LPGBT_TRIGGER_UPLINK_CTRL_t is record
    RESET                      :std_logic;     -- Reset this Uplink
    ALIGN_0                    :std_logic_vector( 2 downto 0);
    ALIGN_1                    :std_logic_vector( 2 downto 0);
    ALIGN_2                    :std_logic_vector( 2 downto 0);
    ALIGN_3                    :std_logic_vector( 2 downto 0);
    ALIGN_4                    :std_logic_vector( 2 downto 0);
    ALIGN_5                    :std_logic_vector( 2 downto 0);
    ALIGN_6                    :std_logic_vector( 2 downto 0);
    ALIGN_7                    :std_logic_vector( 2 downto 0);
    ALIGN_8                    :std_logic_vector( 2 downto 0);
    ALIGN_9                    :std_logic_vector( 2 downto 0);
    ALIGN_10                   :std_logic_vector( 2 downto 0);
    ALIGN_11                   :std_logic_vector( 2 downto 0);
    ALIGN_12                   :std_logic_vector( 2 downto 0);
    ALIGN_13                   :std_logic_vector( 2 downto 0);
    ALIGN_14                   :std_logic_vector( 2 downto 0);
    ALIGN_15                   :std_logic_vector( 2 downto 0);
    ALIGN_16                   :std_logic_vector( 2 downto 0);
    ALIGN_17                   :std_logic_vector( 2 downto 0);
    ALIGN_18                   :std_logic_vector( 2 downto 0);
    ALIGN_19                   :std_logic_vector( 2 downto 0);
    ALIGN_20                   :std_logic_vector( 2 downto 0);
    ALIGN_21                   :std_logic_vector( 2 downto 0);
    ALIGN_22                   :std_logic_vector( 2 downto 0);
    ALIGN_23                   :std_logic_vector( 2 downto 0);
    ALIGN_24                   :std_logic_vector( 2 downto 0);
    ALIGN_25                   :std_logic_vector( 2 downto 0);
    ALIGN_26                   :std_logic_vector( 2 downto 0);
    ALIGN_27                   :std_logic_vector( 2 downto 0);
  end record READOUT_BOARD_LPGBT_TRIGGER_UPLINK_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_TRIGGER_UPLINK_CTRL_t : READOUT_BOARD_LPGBT_TRIGGER_UPLINK_CTRL_t := (
                                                                                                             RESET => '0',
                                                                                                             ALIGN_0 => (others => '0'),
                                                                                                             ALIGN_1 => (others => '0'),
                                                                                                             ALIGN_2 => (others => '0'),
                                                                                                             ALIGN_3 => (others => '0'),
                                                                                                             ALIGN_4 => (others => '0'),
                                                                                                             ALIGN_5 => (others => '0'),
                                                                                                             ALIGN_6 => (others => '0'),
                                                                                                             ALIGN_7 => (others => '0'),
                                                                                                             ALIGN_8 => (others => '0'),
                                                                                                             ALIGN_9 => (others => '0'),
                                                                                                             ALIGN_10 => (others => '0'),
                                                                                                             ALIGN_11 => (others => '0'),
                                                                                                             ALIGN_12 => (others => '0'),
                                                                                                             ALIGN_13 => (others => '0'),
                                                                                                             ALIGN_14 => (others => '0'),
                                                                                                             ALIGN_15 => (others => '0'),
                                                                                                             ALIGN_16 => (others => '0'),
                                                                                                             ALIGN_17 => (others => '0'),
                                                                                                             ALIGN_18 => (others => '0'),
                                                                                                             ALIGN_19 => (others => '0'),
                                                                                                             ALIGN_20 => (others => '0'),
                                                                                                             ALIGN_21 => (others => '0'),
                                                                                                             ALIGN_22 => (others => '0'),
                                                                                                             ALIGN_23 => (others => '0'),
                                                                                                             ALIGN_24 => (others => '0'),
                                                                                                             ALIGN_25 => (others => '0'),
                                                                                                             ALIGN_26 => (others => '0'),
                                                                                                             ALIGN_27 => (others => '0')
                                                                                                            );
  type READOUT_BOARD_LPGBT_TRIGGER_MON_t is record
    UPLINK                     :READOUT_BOARD_LPGBT_TRIGGER_UPLINK_MON_t;
  end record READOUT_BOARD_LPGBT_TRIGGER_MON_t;


  type READOUT_BOARD_LPGBT_TRIGGER_CTRL_t is record
    UPLINK                     :READOUT_BOARD_LPGBT_TRIGGER_UPLINK_CTRL_t;
  end record READOUT_BOARD_LPGBT_TRIGGER_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_TRIGGER_CTRL_t : READOUT_BOARD_LPGBT_TRIGGER_CTRL_t := (
                                                                                               UPLINK => DEFAULT_READOUT_BOARD_LPGBT_TRIGGER_UPLINK_CTRL_t
                                                                                              );
  type READOUT_BOARD_LPGBT_PATTERN_CHECKER_MON_t is record
    TIMER_LSBS                 :std_logic_vector(31 downto 0);  -- Timer of how long the counter has been running
    TIMER_MSBS                 :std_logic_vector(31 downto 0);  -- Timer of how long the counter has been running
    UPCNT_ERRORS               :std_logic_vector(31 downto 0);  -- Errors on Upcnt
    PRBS_ERRORS                :std_logic_vector(31 downto 0);  -- Errors on Prbs
  end record READOUT_BOARD_LPGBT_PATTERN_CHECKER_MON_t;


  type READOUT_BOARD_LPGBT_PATTERN_CHECKER_CTRL_t is record
    RESET                      :std_logic;     -- 1 to Reset Pattern Checker
    CNT_RESET                  :std_logic;     -- 1 to Reset Pattern Checker Counters
    CHECK_PRBS_EN_0            :std_logic_vector(31 downto 0);  -- Bitmask 1 to enable checking
    CHECK_UPCNT_EN_0           :std_logic_vector(31 downto 0);  -- Bitmask 1 to enable checking
    CHECK_PRBS_EN_1            :std_logic_vector(31 downto 0);  -- Bitmask 1 to enable checking
    CHECK_UPCNT_EN_1           :std_logic_vector(31 downto 0);  -- Bitmask 1 to enable checking
    SEL                        :std_logic_vector(15 downto 0);  -- Channel to select for error counting
  end record READOUT_BOARD_LPGBT_PATTERN_CHECKER_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_PATTERN_CHECKER_CTRL_t : READOUT_BOARD_LPGBT_PATTERN_CHECKER_CTRL_t := (
                                                                                                               RESET => '0',
                                                                                                               CNT_RESET => '0',
                                                                                                               CHECK_PRBS_EN_0 => x"00000000",
                                                                                                               CHECK_UPCNT_EN_0 => x"00000000",
                                                                                                               CHECK_PRBS_EN_1 => x"00000000",
                                                                                                               CHECK_UPCNT_EN_1 => x"00000000",
                                                                                                               SEL => x"0000"
                                                                                                              );
  type READOUT_BOARD_LPGBT_MON_t is record
    DAQ                        :READOUT_BOARD_LPGBT_DAQ_MON_t;
    TRIGGER                    :READOUT_BOARD_LPGBT_TRIGGER_MON_t;
    PATTERN_CHECKER            :READOUT_BOARD_LPGBT_PATTERN_CHECKER_MON_t;
  end record READOUT_BOARD_LPGBT_MON_t;


  type READOUT_BOARD_LPGBT_CTRL_t is record
    DAQ                        :READOUT_BOARD_LPGBT_DAQ_CTRL_t;
    FEC_ERR_RESET              :std_logic;                       -- Write 1 to reset FEC error counter
    TRIGGER                    :READOUT_BOARD_LPGBT_TRIGGER_CTRL_t;
    PATTERN_CHECKER            :READOUT_BOARD_LPGBT_PATTERN_CHECKER_CTRL_t;
  end record READOUT_BOARD_LPGBT_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_CTRL_t : READOUT_BOARD_LPGBT_CTRL_t := (
                                                                               DAQ => DEFAULT_READOUT_BOARD_LPGBT_DAQ_CTRL_t,
                                                                               FEC_ERR_RESET => '0',
                                                                               TRIGGER => DEFAULT_READOUT_BOARD_LPGBT_TRIGGER_CTRL_t,
                                                                               PATTERN_CHECKER => DEFAULT_READOUT_BOARD_LPGBT_PATTERN_CHECKER_CTRL_t
                                                                              );
  type READOUT_BOARD_SC_RX_MON_t is record
    RX_LEN                     :std_logic_vector( 7 downto 0);  -- Reply: The length qualifier field specifies the number of bytes contained in the DATA field.
    RX_ADDRESS                 :std_logic_vector( 7 downto 0);  -- Reply: It represents the packet destination address. The address is one-bytelong. By default, the GBT-SCA use address 0x00.
    RX_CONTROL                 :std_logic_vector( 7 downto 0);  -- Reply: The control field is 1 byte in length and contains frame sequence numbers of the currently transmitted frame and the last correctly received frame. The control field is also used to convey three supervisory level commands: Connect, Reset, and Test.
    RX_TRANSID                 :std_logic_vector( 7 downto 0);  -- Reply: transaction ID field (According to the SCA manual)
    RX_ERR                     :std_logic_vector( 7 downto 0);  -- Reply: The Error Flag field is present in the channel reply frames to indicate error conditions encountered in the execution of a command. If no errors are found, its value is 0x00.
    RX_RECEIVED                :std_logic;                      -- Reply received flag (pulse)
    RX_CHANNEL                 :std_logic_vector( 7 downto 0);  -- Reply: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
    RX_DATA                    :std_logic_vector(31 downto 0);  -- Reply: The Data field is command dependent field whose length is defined by the length qualifier field. For example, in the case of a read/write operation on a GBT-SCA internal register, it contains the value written/read from the register.
  end record READOUT_BOARD_SC_RX_MON_t;


  type READOUT_BOARD_SC_MON_t is record
    RX_DATA_FROM_GBTX          :std_logic_vector( 7 downto 0);  -- Data from the LPGBT
    RX_ADR_FROM_GBTX           :std_logic_vector(15 downto 0);  -- Adr from the LPGBT
    RX_DATA_VALID              :std_logic;                      -- Data from the LPGBT is valid
    TX_READY                   :std_logic;                      -- IC core ready for a transaction
    RX_EMPTY                   :std_logic;                      -- Rx FIFO is empty (no reply from GBTx)
    RX                         :READOUT_BOARD_SC_RX_MON_t;    
  end record READOUT_BOARD_SC_MON_t;


  type READOUT_BOARD_SC_CTRL_t is record
    TX_RESET                   :std_logic;     -- Reset TX datapath
    RX_RESET                   :std_logic;     -- Reset RX datapath
    TX_START_WRITE             :std_logic;     -- Request a write config to the GBTx (IC)
    TX_START_READ              :std_logic;     -- Request a read config to the GBTx (IC)
    TX_GBTX_ADDR               :std_logic_vector( 7 downto 0);  -- I2C address of the GBTx
    TX_REGISTER_ADDR           :std_logic_vector(15 downto 0);  -- Address of the first register to be accessed
    TX_NUM_BYTES_TO_READ       :std_logic_vector(15 downto 0);  -- Number of words/bytes to be read (only for read transactions)
    FRAME_FORMAT               :std_logic;                      -- IC Frame format: 0 = lpGBT v0; 1 = lpGBT v1
    TX_DATA_TO_GBTX            :std_logic_vector( 7 downto 0);  -- Data to be written into the internal FIFO
    TX_WR                      :std_logic;                      -- Request a write operation into the internal FIFO (Data to GBTx)
    TX_CMD                     :std_logic_vector( 7 downto 0);  -- Command: The Command field is present in the frames received by the SCA and indicates the operation to be performed. Meaning is specific to the channel.
    TX_ADDRESS                 :std_logic_vector( 7 downto 0);  -- Command: It represents the packet destination address. The address is one-byte long. By default, the GBT-SCA use address 0x00.
    TX_TRANSID                 :std_logic_vector( 7 downto 0);  -- Command: Specifies the message identification number. The reply messages generated by the SCA have the same transaction identifier of the request message allowing to associate the transmitted commands with the corresponding replies, permitting the concurrent use of all the SCA channels.  It is not required that ID values are ordered. ID values 0x00 and 0xff are reserved for interrupt packets generated spontaneously by the SCA and should not be used in requests.
    TX_CHANNEL                 :std_logic_vector( 7 downto 0);  -- Command: The channel field specifies the destination interface of the request message (ctrl/spi/gpio/i2c/jtag/adc/dac).
    TX_DATA                    :std_logic_vector(31 downto 0);  -- Command: data field (According to the SCA manual)
    SCA_ENABLE                 :std_logic;                      -- Enable flag to select SCAs
    START_RESET                :std_logic;                      -- Send a reset command to the enabled SCAs
    START_CONNECT              :std_logic;                      -- Send a connect command to the enabled SCAs
    START_COMMAND              :std_logic;                      -- Send the command set in input to the enabled SCAs
    INJ_CRC_ERR                :std_logic;                      -- Emulate a CRC error
  end record READOUT_BOARD_SC_CTRL_t;


  constant DEFAULT_READOUT_BOARD_SC_CTRL_t : READOUT_BOARD_SC_CTRL_t := (
                                                                         TX_RESET => '0',
                                                                         RX_RESET => '0',
                                                                         TX_START_WRITE => '0',
                                                                         TX_START_READ => '0',
                                                                         TX_GBTX_ADDR => x"73",
                                                                         TX_REGISTER_ADDR => (others => '0'),
                                                                         TX_NUM_BYTES_TO_READ => x"0001",
                                                                         FRAME_FORMAT => '0',
                                                                         TX_DATA_TO_GBTX => (others => '0'),
                                                                         TX_WR => '0',
                                                                         TX_CMD => (others => '0'),
                                                                         TX_ADDRESS => (others => '0'),
                                                                         TX_TRANSID => (others => '0'),
                                                                         TX_CHANNEL => (others => '0'),
                                                                         TX_DATA => (others => '0'),
                                                                         SCA_ENABLE => '1',
                                                                         START_RESET => '0',
                                                                         START_CONNECT => '0',
                                                                         START_COMMAND => '0',
                                                                         INJ_CRC_ERR => '0'
                                                                        );
  type READOUT_BOARD_MON_t is record
    LPGBT                      :READOUT_BOARD_LPGBT_MON_t;
    SC                         :READOUT_BOARD_SC_MON_t;   
    RX_FIFO_LOST_WORD_CNT      :std_logic_vector(15 downto 0);  -- # of words lost to a full FIFO
    RX_FIFO_FULL               :std_logic;                      -- RX FIFO is full
    ETROC_LOCKED               :std_logic_vector(27 downto 0);  -- ETROC Link Locked
    ETROC_LOCKED_SLAVE         :std_logic_vector(27 downto 0);  -- ETROC Link Locked
    PACKET_RX_RATE             :std_logic_vector(31 downto 0);  -- Measured rate of generated received packets in Hz
    PACKET_CNT                 :std_logic_vector(15 downto 0);  -- Count of packets received (muxed across elinks)
    ERROR_CNT                  :std_logic_vector(15 downto 0);  -- Count of packet errors (muxed across elinks)
  end record READOUT_BOARD_MON_t;


  type READOUT_BOARD_CTRL_t is record
    LPGBT                      :READOUT_BOARD_LPGBT_CTRL_t;
    ETROC_BITSLIP              :std_logic_vector(31 downto 0);  -- 1 to bitslip an ETROC
    RESET_ETROC_RX             :std_logic_vector(31 downto 0);  -- 1 to reset the ETROC rx module
    ZERO_SUPRESS               :std_logic_vector(31 downto 0);  -- 1 to zero suppress fillers out from the ETROC RX
    BITSLIP_AUTO_EN            :std_logic;                      -- 1 to enable automatic bitslipping alignment
    RAW_DATA_MODE              :std_logic_vector(31 downto 0);  -- 1 to read all data from ETROC, regardless of content
    ETROC_BITSLIP_SLAVE        :std_logic_vector(31 downto 0);  -- 1 to bitslip an ETROC
    RESET_ETROC_RX_SLAVE       :std_logic_vector(31 downto 0);  -- 1 to reset the ETROC rx module
    ZERO_SUPRESS_SLAVE         :std_logic_vector(31 downto 0);  -- 1 to zero suppress fillers out from the ETROC RX
    RAW_DATA_MODE_SLAVE        :std_logic_vector(31 downto 0);  -- 1 to read all data from ETROC, regardless of content
    SC                         :READOUT_BOARD_SC_CTRL_t;      
    FIFO_ELINK_SEL0            :std_logic_vector( 4 downto 0);  -- Choose which e-link the readout fifo connects to (0-27)
    FIFO_LPGBT_SEL0            :std_logic;                      -- Choose which lpgbt the readout fifo connects to (0-1)
    FIFO_RESET                 :std_logic;                      -- Reset the daq FIFO
    RX_FIFO_DATA_SRC           :std_logic;                      -- 0=etroc data, 1=fixed pattern for ETROC data fifo
    LINK_RESET_PULSE           :std_logic;                      -- Write 1 to pulse Link reset
    PACKET_CNT_RESET           :std_logic;                      -- Write 1 to reset packet counters
    ERR_CNT_RESET              :std_logic;                      -- Write 1 to reset error counters
  end record READOUT_BOARD_CTRL_t;


  constant DEFAULT_READOUT_BOARD_CTRL_t : READOUT_BOARD_CTRL_t := (
                                                                   LPGBT => DEFAULT_READOUT_BOARD_LPGBT_CTRL_t,
                                                                   ETROC_BITSLIP => (others => '0'),
                                                                   RESET_ETROC_RX => (others => '0'),
                                                                   ZERO_SUPRESS => x"0fffffff",
                                                                   BITSLIP_AUTO_EN => '1',
                                                                   RAW_DATA_MODE => (others => '0'),
                                                                   ETROC_BITSLIP_SLAVE => (others => '0'),
                                                                   RESET_ETROC_RX_SLAVE => (others => '0'),
                                                                   ZERO_SUPRESS_SLAVE => x"0fffffff",
                                                                   RAW_DATA_MODE_SLAVE => (others => '0'),
                                                                   SC => DEFAULT_READOUT_BOARD_SC_CTRL_t,
                                                                   FIFO_ELINK_SEL0 => (others => '0'),
                                                                   FIFO_LPGBT_SEL0 => '0',
                                                                   FIFO_RESET => '0',
                                                                   RX_FIFO_DATA_SRC => '0',
                                                                   LINK_RESET_PULSE => '0',
                                                                   PACKET_CNT_RESET => '0',
                                                                   ERR_CNT_RESET => '0'
                                                                  );


end package READOUT_BOARD_CTRL;