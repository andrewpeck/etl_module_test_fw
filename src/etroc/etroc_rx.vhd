--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.dataformat_pkg.all;

package constants_pkg is

  constant CRCB    : positive := 1 + CRC_RANGE'high - CRC_RANGE'low;
  constant CHIPIDB : positive := 1 + CHIPID_RANGE'high - CHIPID_RANGE'low;
  constant HITCNTB : positive := 1 + HITS_RANGE'high - HITS_RANGE'low;
  constant STATB   : positive := 1 + STATUS_RANGE'high - STATUS_RANGE'low;

  constant CALB : positive := 1 + CAL_RANGE'high - CAL_RANGE'low;
  constant TOTB : positive := 1 + TOT_RANGE'high - TOT_RANGE'low;
  constant TOAB : positive := 1 + TOA_RANGE'high - TOA_RANGE'low;
  constant ROWB : positive := 1 + ROW_ID_RANGE'high - ROW_ID_RANGE'low;
  constant COLB : positive := 1 + COL_ID_RANGE'high - COL_ID_RANGE'low;
  constant EAB  : positive := 1 + EA_RANGE'high - EA_RANGE'low;

  constant BXB       : positive := 1 + BCID_RANGE'high - BCID_RANGE'low;
  constant TYPEB     : positive := 1 + TYPE_RANGE'high - TYPE_RANGE'low;
  constant EVENTCNTB : positive := 1 + L1COUNTER_RANGE'high - L1COUNTER_RANGE'low;

  -- Zero shift:
  --
  -- Takes a std_logic_vector (x downto y) and converts it to a
  -- std_logic_vector (x-y downto 0)
  --
  function zsh (a : std_logic_vector)
    return std_logic_vector is
    variable result : std_logic_vector(a'high - a'low downto 0);
  begin
    for i in 0 to result'length-1 loop
      result(i) := a(i+a'low);
    end loop;
    return result;
  end;

  function reverse_vector (a : std_logic_vector)
    return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'reverse_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_vector

end package constants_pkg;

--------------------------------------------------------------------------------
-- ETROC Receiver
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.dataformat_pkg.all;
use work.constants_pkg.all;

entity etroc_rx is
  generic(
    MAX_ELINK_WIDTH : positive := 32;
    FRAME_WIDTH     : positive := 40;
    AUTO_INVERT     : boolean  := true
    );
  port(

    -- 40MHz clock + reset
    clock : in std_logic;
    reset : in std_logic;

    -- elink data (32 bits wide.. zero pad for 16 or 32 bit inputs)
    data_i : in std_logic_vector (MAX_ELINK_WIDTH-1 downto 0);

    -- elink width configuration
    -- runtime configuration: 0:2, 1:4, 2:8, 3:16, 4:32
    -- 0 = 80 Mbps
    -- 1 = 160 Mbps
    -- 2 = 320 Mbps
    -- 3 = 640 Mbps
    -- 4 = 1280 Mbps
    elinkwidth_i : in std_logic_vector(2 downto 0) := "010";

    -- set to 1 and this module will output filler words
    -- in addition to the header/payload/trailer
    zero_suppress_i : in std_logic;

    -- set to 1 to just output semi-raw data.. this outputs decoded frames,
    -- indepdent of header/trailer/etc.. just sends out the 40 bit frames into the fifo
    raw_data_mode_i : in std_logic;

    -- assert 1 to force a bitslip
    -- this should be asserted for 1 clock cycle only
    bitslip_i : in std_logic;

    -- assert 1 to to allow automatic bitslipping
    bitslip_auto_i : in std_logic;

    -- expose the sm state for debugging
    state_mon_o : out std_logic_vector (2 downto 0);

    -- expose a raw copy of the 40 bit word for debugging
    frame_mon_o : out std_logic_vector (FRAME_WIDTH-1 downto 0);

    -- expose a fifo write port interface with fillers removed
    -- can be connected to a daq fifo
    -- 40 bits so need an asymmetric fifo (e.g. 2:1 with padding)
    fifo_data_o  : out std_logic_vector (FRAME_WIDTH-1 downto 0);
    fifo_wr_en_o : out std_logic;

    -- decoded packet outputs for monitoring
    bcid_o            : out std_logic_vector (BXB-1 downto 0);
    type_o            : out std_logic_vector (TYPEB-1 downto 0);
    event_cnt_o       : out std_logic_vector (EVENTCNTB-1 downto 0);
    start_of_packet_o : out std_logic;  -- start of packet

    -- decoded packet outputs for monitoring
    cal_o     : out std_logic_vector (CALB-1 downto 0);
    tot_o     : out std_logic_vector (TOTB-1 downto 0);
    toa_o     : out std_logic_vector (TOAB-1 downto 0);
    col_o     : out std_logic_vector (ROWB-1 downto 0);
    row_o     : out std_logic_vector (COLB-1 downto 0);
    ea_o      : out std_logic_vector (EAB-1 downto 0);
    data_en_o : out std_logic;

    stat_o          : out std_logic_vector (STATB-1 downto 0);
    hitcnt_o        : out std_logic_vector (HITCNTB-1 downto 0);
    crc_o           : out std_logic_vector (CRCB-1 downto 0);
    crc_calc_o      : out std_logic_vector (CRCB-1 downto 0);
    chip_id_o       : out std_logic_vector (CHIPIDB-1 downto 0);
    end_of_packet_o : out std_logic;    -- end of packet

    -- raw monitor of the is_filler flag that can be used as a proxy for link health
    filler_mon_o : out std_logic;
    locked_o     : out std_logic;
    err_o        : out std_logic;
    busy_o       : out std_logic;
    idle_o       : out std_logic
    );
end etroc_rx;

architecture behavioral of etroc_rx is

  -- TRUE will invert the data (1 ⟺ 0) for an inverted elink
  signal invertp : boolean := false;

  -- reversed version of the data... 01234567 ⟹ 76543210
  -- needed since the etroc data comes in reverse bit order
  signal data_inv : std_logic_vector(data_i'range);

  -- State Machine
  type state_t is (ERR_state, FILLER_state, HEADER_state, DATA_state, TRAILER_state);
  signal state           : state_t := ERR_state;
  signal state_is_active : boolean;

  -- count from 0-255 of how many data frames have been received in this packet
  signal data_frame_cnt : natural range 0 to 255 := 0;

  -- Next Frame Data
  --
  -- the next_frame* signals are lookahead versions of the frame data
  -- they get buffered by 1 40MHz cycle from next_frame ⟹ frame
  --
  -- the buffering is used for look-ahead to allow the state machine
  -- to transition early, so that e.g. in the FILLER state,
  -- the data in frame is actually the filler
  --
  -- flags are also provided for next_data_is_*
  -- which indicate the type of the next data frame

  signal next_frame_pre_reverse : std_logic_vector (FRAME_WIDTH-1 downto 0) := (others => '0');
  signal next_frame             : std_logic_vector (FRAME_WIDTH-1 downto 0) := (others => '0');
  signal next_frame_en          : std_logic;

  signal next_data_is_header  : boolean;
  signal next_data_is_filler  : boolean;
  signal next_data_is_trailer : boolean;
  signal next_data_is_data    : boolean;

  signal frame    : std_logic_vector (FRAME_WIDTH-1 downto 0) := (others => '0');
  signal frame_en : std_logic;

  --------------------------------------------------------------------------------
  -- Bitslipping
  --------------------------------------------------------------------------------

  signal bitslip      : std_logic := '0';  -- OR of the automatic and manual bitslip signals
  signal bitslip_auto : std_logic := '0';  -- Automatic bitslip assert

  -- after 40 bitslips, we try inverting the data
  signal bitslip_cnt : natural range 0 to FRAME_WIDTH;

  -- During alignment procedure, number of
  -- *non-consecutive* bad frames required to bitslip
  --
  -- Once the frame is locked, this is the number of
  -- *consecutive* bad frames required to unlock

  constant ALIGN_BAD_CNT_MAX : positive := 31;
  signal align_bad_cnt       : natural range 0 to ALIGN_BAD_CNT_MAX;
  signal bad_cnt_max         : boolean;

  -- # During alignment procedure, this is the number
  -- of *consecutive* Good Frames required to assert alignment

  constant ALIGN_GOOD_CNT_MAX : positive := 1023;
  signal align_good_cnt       : natural range 0 to ALIGN_GOOD_CNT_MAX;
  signal good_cnt_max         : boolean;

  type align_state_t is (ALIGNING_state, LOCKED_state);

  signal align_state : align_state_t := ALIGNING_state;

  --------------------------------------------------------------------------------
  -- CRC
  --------------------------------------------------------------------------------

  component CRC8
    generic (WORDWIDTH : integer := 40);
    port (
      cin  : in  std_logic_vector;      -- input CRC code 8 bits
      din  : in  std_logic_vector;      -- input data 40 bits
      dout : out std_logic_vector;      -- output crc 8 bits
      dis  : in  std_logic
      );
  end component;

  signal crc_data : std_logic_vector (39 downto 0) := (others => '0');
  signal crc_next : std_logic_vector (7 downto 0)  := (others => '0');
  signal crc      : std_logic_vector (7 downto 0)  := (others => '0');
  signal crc_dis  : std_logic                      := '0';

begin

  --------------------------------------------------------------------------------
  -- Outputs
  --------------------------------------------------------------------------------

  -- Convert state enum to std_logic_vector
  state_mon_o <= std_logic_vector(to_unsigned(state_t'pos(state), 3));

  process (clock) is
  begin
    if (rising_edge(clock)) then
      locked_o     <= '1' when align_state = LOCKED_state else '0';
      err_o        <= '1' when state = ERR_state          else '0';
      filler_mon_o <= '1' when next_data_is_filler        else '0';
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Alignment State Machine
  --------------------------------------------------------------------------------

  bad_cnt_max  <= align_bad_cnt = ALIGN_BAD_CNT_MAX;
  good_cnt_max <= align_good_cnt = ALIGN_GOOD_CNT_MAX;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      bitslip_auto <= '0';

      case align_state is

        when ALIGNING_state =>

          -- counter to bitslip after some number of errors
          if (bad_cnt_max) then
            align_bad_cnt <= 0;

            -- less than 40 bitslips, we keep trying another bitslip
            if (bitslip_cnt < bitslip_cnt'high) then
              bitslip_auto <= '1';
              if (AUTO_INVERT) then
                bitslip_cnt <= bitslip_cnt + 1;
              end if;

            -- after 40 bitslips, we invert the data and try again
            -- why 40? there are 40 bits in an ETROC frame
            else
              invertp     <= not invertp;
              bitslip_cnt <= 0;
            end if;

          -- only count once per 40 bit frame by counting on next_frame_en
          elsif (next_frame_en = '1' and state = ERR_state) then
            align_bad_cnt  <= align_bad_cnt + 1;
            align_good_cnt <= 0;
          end if;

          -- counter to switch to locked after some number of consecutive good
          -- frames
          if (good_cnt_max) then
            align_state    <= LOCKED_state;
            align_good_cnt <= 0;
          elsif (next_frame_en = '1' and state = FILLER_state) then
            align_good_cnt <= align_good_cnt + 1;
          end if;

        when LOCKED_state =>

          -- counter to switch to unlocked after some number of errors
          if (bad_cnt_max) then
            align_bad_cnt <= 0;
            align_state   <= ALIGNING_state;
          -- only count once per 40 bit frame
          elsif (next_frame_en = '1' and state = ERR_state) then
            align_bad_cnt <= align_bad_cnt + 1;
          end if;

      end case;

      if (reset = '1') then
        align_state    <= ALIGNING_state;
        align_bad_cnt  <= 0;
        align_good_cnt <= 0;
      end if;

    end if;
  end process;

  -- Or of the automatic and manual bitslips
  bitslip <= bitslip_i or (bitslip_auto_i and bitslip_auto);

  --------------------------------------------------------------------------------
  -- Optional Data Inversion
  --
  -- this gets asserted automatically by the alignment state machine
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      data_inv <= not data_i when invertp else data_i;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Decoding Gearbox
  --------------------------------------------------------------------------------

  -- TODO: use decodinggearbox ReverseInputBits instead of data_inv?
  decoding_gearbox_inst : entity work.decodinggearbox
    generic map (
      MAX_INPUT      => MAX_ELINK_WIDTH,
      MAX_OUTPUT     => 40,
      SUPPORT_INPUT  => "11100",        -- 32, 16, 8, 4, 2
      SUPPORT_OUTPUT => "01000"         -- 66, 4x10, 2x10, 10, 8
      )
    port map (
      reset            => reset,
      clk40            => clock,
      elinkdata        => data_inv,
      elinkaligned     => '1',
      elinkwidth       => elinkwidth_i,
      msbfirst         => '1',
      reverseinputbits => '0',
      dataout          => next_frame_pre_reverse,
      dataoutvalid     => next_frame_en,
      outputwidth      => "011",        -- 11 = 40
      bitslip          => bitslip
      );

  --------------------------------------------------------------------------------
  -- Next Frame Logic
  --------------------------------------------------------------------------------

  next_frame <= reverse_vector(next_frame_pre_reverse) when REVERSE else next_frame_pre_reverse;

  next_data_is_header  <= (next_frame and HEADER_IDENTIFIER_MASK) = HEADER_IDENTIFIER_FRAME;
  next_data_is_filler  <= (next_frame and FILLER_IDENTIFIER_MASK) = FILLER_IDENTIFIER_FRAME;
  next_data_is_trailer <= (next_frame and TRAILER_IDENTIFIER_MASK) = TRAILER_IDENTIFIER_FRAME;
  next_data_is_data    <= (next_frame and DATA_IDENTIFIER_MASK) = DATA_IDENTIFIER_FRAME;

  -- delay the data by 1 clock cycle
  process (clock) is
  begin
    if (rising_edge(clock)) then
      frame    <= next_frame;
      frame_en <= next_frame_en;
    end if;
  end process;

  frame_mon_o <= frame;

  --------------------------------------------------------------------------------
  -- ETROC Statemachine
  --------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then

      data_en_o         <= '0';
      end_of_packet_o   <= '0';
      start_of_packet_o <= '0';

      fifo_data_o  <= (others => '0');
      fifo_wr_en_o <= '0';

      case state is

        when ERR_state =>

          data_frame_cnt <= 0;

          -- ERR ⟹ FILLER
          if (next_data_is_filler) then
            state <= FILLER_state;
          end if;

        when FILLER_state =>

          data_frame_cnt <= 0;

          -- FILLER ⟹ FILLER, HEADER, ERR
          if (next_data_is_filler) then
            state <= FILLER_state;
          elsif (next_data_is_header) then
            state <= HEADER_state;
          else
            state <= ERR_state;
          end if;

          -- FIFO output
          if (frame_en = '1' and zero_suppress_i = '0') then
            fifo_data_o  <= frame;
            fifo_wr_en_o <= '1';
          end if;

        when HEADER_state =>

          data_frame_cnt <= 0;

          -- HEADER ⟹ DATA, TRAILER, ERR
          if (next_data_is_header) then
            -- disallow repeat headers
            -- if a repeat header is seen, go to ERR
            if (next_frame_en = '1') then
              state <= ERR_state;
            else
              state <= HEADER_state;
            end if;
          elsif (next_data_is_data) then
            state <= DATA_state;
          elsif (next_data_is_trailer) then
            state <= TRAILER_state;
          else
            state <= ERR_state;
          end if;

          -- processed outputs
          bcid_o      <= zsh(frame(BCID_RANGE));
          type_o      <= zsh(frame(TYPE_RANGE));
          event_cnt_o <= zsh(frame(L1COUNTER_RANGE));

          -- FIFO output
          if (frame_en = '1') then
            start_of_packet_o <= '1';
            fifo_data_o       <= frame;
            fifo_wr_en_o      <= '1';
            crc               <= crc_next;
          end if;

        when DATA_state =>

          -- DATA ⟹ DATA, TRAILER, ERR
          if (next_data_is_data) then
            state <= DATA_state;
            -- don't allow more than 256 pixels
            if (next_frame_en = '1' and data_frame_cnt = 255) then
              state <= ERR_state;
            end if;
          elsif (next_data_is_trailer) then
            state      <= TRAILER_state;
            crc_calc_o <= crc;
          else
            state <= ERR_state;
          end if;

          -- processed outputs
          cal_o <= zsh(frame(CAL_RANGE));
          tot_o <= zsh(frame(TOT_RANGE));
          toa_o <= zsh(frame(TOA_RANGE));
          col_o <= zsh(frame(COL_ID_RANGE));
          row_o <= zsh(frame(ROW_ID_RANGE));
          ea_o  <= zsh(frame(EA_RANGE));

          -- FIFO output
          if (frame_en = '1') then
            data_en_o      <= '1';
            fifo_data_o    <= frame;
            fifo_wr_en_o   <= '1';
            data_frame_cnt <= data_frame_cnt + 1;
            crc            <= crc_next;
          end if;

        when TRAILER_state =>

          data_frame_cnt <= 0;

          -- TRAILER ⟹ HEADER, FILLER, ERR
          if (next_data_is_header) then
            state <= HEADER_state;
          elsif (next_data_is_filler) then
            state <= FILLER_state;
          elsif (next_data_is_trailer) then
            -- disallow repeat trailers
            if (next_frame_en = '1') then
              state <= ERR_state;
            else
              state <= TRAILER_state;
            end if;
          else
            state <= ERR_state;
          end if;

          -- processed outputs
          chip_id_o <= zsh(frame(CHIPID_RANGE));
          crc_o     <= zsh(frame(CRC_RANGE));
          hitcnt_o  <= zsh(frame(HITS_RANGE));
          stat_o    <= zsh(frame(STATUS_RANGE));

          -- FIFO output
          if (frame_en = '1') then
            end_of_packet_o <= '1';
            fifo_data_o     <= frame;
            fifo_wr_en_o    <= '1';
            crc             <= (others => '0');
          end if;

        when others =>

          state <= ERR_state;

      end case;

      --------------------------------------------------------------------------------
      -- Raw Data Mode
      --
      -- raw data mode? just output every frame
      --------------------------------------------------------------------------------

      if (frame_en = '1' and raw_data_mode_i = '1') then
        fifo_data_o  <= frame;
        fifo_wr_en_o <= '1';
      end if;

      --------------------------------------------------------------------------------
      -- reset
      --------------------------------------------------------------------------------

      if (reset = '1') then
        state <= FILLER_state;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- CRC8
  --------------------------------------------------------------------------------

  state_is_active <= frame_en = '1' and (state = HEADER_state or state = DATA_state or state = TRAILER_state);
  crc_dis         <= '0'   when state_is_active else '1';
  crc_data        <= frame when state_is_active else (others => '0');

  crc_inst : crc8
    port map (
      cin  => crc,
      dis  => crc_dis,
      din  => crc_data,
      dout => crc_next);

end behavioral;
