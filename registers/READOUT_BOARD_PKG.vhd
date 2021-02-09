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
                                                                                                     ALIGN_8 => (others => '0'),
                                                                                                     ALIGN_16 => (others => '0'),
                                                                                                     ALIGN_24 => (others => '0'),
                                                                                                     ALIGN_1 => (others => '0'),
                                                                                                     ALIGN_9 => (others => '0'),
                                                                                                     ALIGN_17 => (others => '0'),
                                                                                                     ALIGN_25 => (others => '0'),
                                                                                                     ALIGN_2 => (others => '0'),
                                                                                                     ALIGN_10 => (others => '0'),
                                                                                                     ALIGN_18 => (others => '0'),
                                                                                                     ALIGN_26 => (others => '0'),
                                                                                                     ALIGN_3 => (others => '0'),
                                                                                                     ALIGN_11 => (others => '0'),
                                                                                                     ALIGN_19 => (others => '0'),
                                                                                                     ALIGN_27 => (others => '0'),
                                                                                                     ALIGN_4 => (others => '0'),
                                                                                                     ALIGN_12 => (others => '0'),
                                                                                                     ALIGN_20 => (others => '0'),
                                                                                                     ALIGN_5 => (others => '0'),
                                                                                                     ALIGN_13 => (others => '0'),
                                                                                                     ALIGN_21 => (others => '0'),
                                                                                                     ALIGN_6 => (others => '0'),
                                                                                                     ALIGN_14 => (others => '0'),
                                                                                                     ALIGN_22 => (others => '0'),
                                                                                                     ALIGN_7 => (others => '0'),
                                                                                                     ALIGN_15 => (others => '0'),
                                                                                                     ALIGN_23 => (others => '0')
                                                                                                    );
  type READOUT_BOARD_LPGBT_DAQ_DOWNLINK_MON_t is record
    READY                      :std_logic;     -- LPGBT Downlink Ready
  end record READOUT_BOARD_LPGBT_DAQ_DOWNLINK_MON_t;


  type READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t is record
    RESET                      :std_logic;     -- Reset this Downlink
    ALIGN_0                    :std_logic_vector( 2 downto 0);
    ALIGN_1                    :std_logic_vector( 2 downto 0);
    ALIGN_2                    :std_logic_vector( 2 downto 0);
    ALIGN_3                    :std_logic_vector( 2 downto 0);
    DL_SRC                     :std_logic_vector( 2 downto 0);  -- 0=etroc, 1=upcnt, 2=prbs
  end record READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t : READOUT_BOARD_LPGBT_DAQ_DOWNLINK_CTRL_t := (
                                                                                                         RESET => '0',
                                                                                                         ALIGN_0 => (others => '0'),
                                                                                                         DL_SRC => (others => '0'),
                                                                                                         ALIGN_1 => (others => '0'),
                                                                                                         ALIGN_2 => (others => '0'),
                                                                                                         ALIGN_3 => (others => '0')
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
                                                                                                             ALIGN_8 => (others => '0'),
                                                                                                             ALIGN_16 => (others => '0'),
                                                                                                             ALIGN_24 => (others => '0'),
                                                                                                             ALIGN_1 => (others => '0'),
                                                                                                             ALIGN_9 => (others => '0'),
                                                                                                             ALIGN_17 => (others => '0'),
                                                                                                             ALIGN_25 => (others => '0'),
                                                                                                             ALIGN_2 => (others => '0'),
                                                                                                             ALIGN_10 => (others => '0'),
                                                                                                             ALIGN_18 => (others => '0'),
                                                                                                             ALIGN_26 => (others => '0'),
                                                                                                             ALIGN_3 => (others => '0'),
                                                                                                             ALIGN_11 => (others => '0'),
                                                                                                             ALIGN_19 => (others => '0'),
                                                                                                             ALIGN_27 => (others => '0'),
                                                                                                             ALIGN_4 => (others => '0'),
                                                                                                             ALIGN_12 => (others => '0'),
                                                                                                             ALIGN_20 => (others => '0'),
                                                                                                             ALIGN_5 => (others => '0'),
                                                                                                             ALIGN_13 => (others => '0'),
                                                                                                             ALIGN_21 => (others => '0'),
                                                                                                             ALIGN_6 => (others => '0'),
                                                                                                             ALIGN_14 => (others => '0'),
                                                                                                             ALIGN_22 => (others => '0'),
                                                                                                             ALIGN_7 => (others => '0'),
                                                                                                             ALIGN_15 => (others => '0'),
                                                                                                             ALIGN_23 => (others => '0')
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
                                                                                                               SEL => x"0000",
                                                                                                               CHECK_PRBS_EN_0 => x"00000000",
                                                                                                               CHECK_UPCNT_EN_0 => x"00000000",
                                                                                                               CHECK_PRBS_EN_1 => x"00000000",
                                                                                                               CHECK_UPCNT_EN_1 => x"00000000"
                                                                                                              );
  type READOUT_BOARD_LPGBT_MON_t is record
    DAQ                        :READOUT_BOARD_LPGBT_DAQ_MON_t;
    TRIGGER                    :READOUT_BOARD_LPGBT_TRIGGER_MON_t;
    PATTERN_CHECKER            :READOUT_BOARD_LPGBT_PATTERN_CHECKER_MON_t;
  end record READOUT_BOARD_LPGBT_MON_t;


  type READOUT_BOARD_LPGBT_CTRL_t is record
    DAQ                        :READOUT_BOARD_LPGBT_DAQ_CTRL_t;
    TRIGGER                    :READOUT_BOARD_LPGBT_TRIGGER_CTRL_t;
    PATTERN_CHECKER            :READOUT_BOARD_LPGBT_PATTERN_CHECKER_CTRL_t;
  end record READOUT_BOARD_LPGBT_CTRL_t;


  constant DEFAULT_READOUT_BOARD_LPGBT_CTRL_t : READOUT_BOARD_LPGBT_CTRL_t := (
                                                                               DAQ => DEFAULT_READOUT_BOARD_LPGBT_DAQ_CTRL_t,
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
    RX_DATA_FROM_GBTX          :std_logic_vector( 7 downto 0);  -- Data from the FIFO
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
    TX_DATA_TO_GBTX            :std_logic_vector( 7 downto 0);  -- Data to be written into the internal FIFO
    TX_WR                      :std_logic;                      -- Request a write operation into the internal FIFO (Data to GBTx)
    RX_RD                      :std_logic;                      -- Request a read operation of the internal FIFO (GBTx reply)
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
                                                                         TX_WR => '0',
                                                                         RX_RD => '0',
                                                                         SCA_ENABLE => '1',
                                                                         START_RESET => '0',
                                                                         START_CONNECT => '0',
                                                                         START_COMMAND => '0',
                                                                         INJ_CRC_ERR => '0',
                                                                         TX_DATA_TO_GBTX => (others => '0'),
                                                                         TX_CMD => (others => '0'),
                                                                         TX_GBTX_ADDR => x"73",
                                                                         TX_ADDRESS => (others => '0'),
                                                                         TX_REGISTER_ADDR => (others => '0'),
                                                                         TX_NUM_BYTES_TO_READ => x"0001",
                                                                         TX_TRANSID => (others => '0'),
                                                                         TX_CHANNEL => (others => '0'),
                                                                         TX_DATA => (others => '0')
                                                                        );
  type READOUT_BOARD_MON_t is record
    LPGBT                      :READOUT_BOARD_LPGBT_MON_t;
    SC                         :READOUT_BOARD_SC_MON_t;   
  end record READOUT_BOARD_MON_t;


  type READOUT_BOARD_CTRL_t is record
    LPGBT                      :READOUT_BOARD_LPGBT_CTRL_t;
    SC                         :READOUT_BOARD_SC_CTRL_t;   
  end record READOUT_BOARD_CTRL_t;


  constant DEFAULT_READOUT_BOARD_CTRL_t : READOUT_BOARD_CTRL_t := (
                                                                   LPGBT => DEFAULT_READOUT_BOARD_LPGBT_CTRL_t,
                                                                   SC => DEFAULT_READOUT_BOARD_SC_CTRL_t
                                                                  );


end package READOUT_BOARD_CTRL;