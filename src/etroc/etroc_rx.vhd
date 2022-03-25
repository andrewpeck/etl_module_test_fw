--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.dataformat_pkg.all;

package constants_pkg is
  constant CRCB    : positive := CRC_RANGE'high - CRC_RANGE'low;
  constant CHIPIDB : positive := CHIPID_RANGE'high - CHIPID_RANGE'low;
  constant HITCNTB : positive := HITS_RANGE'high - HITS_RANGE'low;
  constant STATB   : positive := STATUS_RANGE'high - STATUS_RANGE'low;

  constant CALB : positive := CAL_RANGE'high - CAL_RANGE'low;
  constant TOTB : positive := TOT_RANGE'high - TOT_RANGE'low;
  constant TOAB : positive := TOA_RANGE'high - TOA_RANGE'low;
  constant ROWB : positive := ROW_RANGE'high - ROW_RANGE'low;
  constant COLB : positive := COL_RANGE'high - COL_RANGE'low;
  constant EAB  : positive := EA_RANGE'high - EA_RANGE'low;

  constant BXB       : positive := BCID_RANGE'high - BCID_RANGE'low;
  constant TYPEB     : positive := TYPE_RANGE'high - TYPE_RANGE'low;
  constant EVENTCNTB : positive := EVENTCNT_RANGE'high - EVENTCNT_RANGE'low;
end package constants_pkg;

--------------------------------------------------------------------------------
-- ETROC Receiver
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.dataformat_pkg.all;

entity etroc_rx is
  generic(
    MAX_ELINK_WIDTH : positive := 32;
    FRAME_WIDTH     : positive := 40
    );
  port(

    clock : in std_logic;

    reset : in std_logic;

    data_i : in std_logic_vector (MAX_ELINK_WIDTH-1 downto 0);

    bitslip_i : in std_logic;

    elinkwidth : in std_logic_vector(2 downto 0) := "010";  -- runtime configuration: 0:2, 1:4, 2:8, 3:16, 4:32

    bcid_o      : out std_logic_vector (BXB-1 downto 0);
    type_o      : out std_logic_vector (TYPEB-1 downto 0);
    event_cnt_o : out std_logic_vector (EVENTCNTB-1 downto 0);

    cal_o     : out std_logic_vector (CALB -1 downto 0);
    tot_o     : out std_logic_vector (TOTB -1 downto 0);
    toa_o     : out std_logic_vector (TOAB -1 downto 0);
    col_o     : out std_logic_vector (ROWB -1 downto 0);
    row_o     : out std_logic_vector (COLB -1 downto 0);
    ea_o      : out std_logic_vector (EAB -1 downto 0);
    data_en_o : out std_logic;

    stat_o          : out std_logic_vector (STATB -1 downto 0);
    hitcnt_o        : out std_logic_vector (HITCNTB -1 downto 0);
    crc_o           : out std_logic_vector (CRCB - 1 downto 0);
    chip_id_o       : out std_logic_vector (CHIPIDB -1 downto 0);
    end_of_packet_o : out std_logic;    -- end of packet

    err_o  : out std_logic;
    busy_o : out std_logic;
    idle_o : out std_logic
    );
end etroc_rx;

architecture behavioral of etroc_rx is

  signal bitslip : std_logic := '0';

  -- receive data at:
  --
  --    8 bits / bx @ 320  MHz
  --   16 bits / bx @ 640  MHz
  --   32 bits / bx @ 1280 MHz
  --

  type state_t is (ERR_state, IDLE_state, HEADER_state, DATA_state, TRAILER_state);

  signal state : state_t := ERR_state;

  signal next_frame_raw : std_logic_vector (FRAME_WIDTH-1 downto 0) := (others => '0');
  signal next_frame     : std_logic_vector (FRAME_WIDTH-1 downto 0) := (others => '0');
  signal next_frame_en  : std_logic;

  signal frame    : std_logic_vector (FRAME_WIDTH-1 downto 0) := (others => '0');
  signal frame_en : std_logic;

  signal next_data_is_header : boolean;
  signal next_data_is_filler : boolean;
  signal special_bit         : std_logic := '0';

  function zsh (a: std_logic_vector)
    return std_logic_vector is
    variable result: std_logic_vector(a'RANGE);
    alias aa: std_logic_vector(a'high - a'low downto 0) is a;
  begin
    for i in aa'RANGE loop
      result(i) := aa(i+a'low);
    end loop;
    return result;
  end; -- function reverse_vector

  function reverse_vector (a: std_logic_vector)
    return std_logic_vector is
    variable result: std_logic_vector(a'RANGE);
    alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
  begin
    for i in aa'RANGE loop
      result(i) := aa(i);
    end loop;
    return result;
  end; -- function reverse_vector

begin

  -- take bitslip from the outside, but also have an internal signal so we can
  -- develop a firmware statemachine to do alignment
  bitslip <= bitslip_i;

  err_o <= '1' when state = ERR_state else '0';

  next_frame <= reverse_vector(next_frame_raw) when REVERSE else next_frame_raw;

  special_bit <= next_frame(SPECIAL_BIT_INDEX);

  next_data_is_header <= next_frame(HEADER_OR_FILLER_RANGE) = HEADER_MAGIC
                         and next_frame(MAGIC_RANGE) = MAGIC_WORD;

  next_data_is_filler <= next_frame(HEADER_OR_FILLER_RANGE) = FILLER_MAGIC
                         and next_frame(MAGIC_RANGE) = MAGIC_WORD;

  decoding_gearbox_inst : entity work.decodinggearbox
    generic map (
      MAX_INPUT      => MAX_ELINK_WIDTH,
      MAX_OUTPUT     => 40,
      SUPPORT_INPUT  => "11100",
      SUPPORT_OUTPUT => "01000" -- 66, 4x10, 2x10, 10, 8
      )
    port map (
      reset            => reset,
      clk40            => clock,
      elinkdata        => data_i,
      elinkaligned     => '1',
      elinkwidth       => elinkwidth,
      msbfirst         => '1',
      reverseinputbits => '0',
      dataout          => next_frame_raw,
      dataoutvalid     => next_frame_en,
      outputwidth      => "011",         -- 11 = 40
      bitslip          => bitslip
      );

  -- delay the data by 1 clock cycle
  process (clock) is
  begin
    if (rising_edge(clock)) then
      frame    <= next_frame;
      frame_en <= next_frame_en;
    end if;
  end process;

  --
  process (clock)
  begin
    if (rising_edge(clock)) then

      data_en_o       <= '0';
      end_of_packet_o <= '0';

      case state is

        when ERR_state =>

          if (next_data_is_filler) then
            state <= IDLE_state;
          end if;

        when IDLE_state =>

          if (next_data_is_header) then
            state <= HEADER_state;
          elsif (next_frame_en = '1' and not next_data_is_filler) then
            state <= ERR_state;
          end if;

        when HEADER_state =>

          state <= data_state;

          bcid_o      <= zsh(frame(BCID_RANGE));
          type_o      <= zsh(frame(TYPE_RANGE));
          event_cnt_o <= zsh(frame(EVENTCNT_RANGE));

        when DATA_state =>

          if (frame_en = '1') then

            cal_o <= zsh(frame(CAL_RANGE));
            tot_o <= zsh(frame(TOT_RANGE));
            toa_o <= zsh(frame(TOA_RANGE));
            col_o <= zsh(frame(COL_RANGE));
            row_o <= zsh(frame(ROW_RANGE));
            ea_o  <= zsh(frame(EA_RANGE));

            data_en_o <= '1';

            if (special_bit = TRAILER_SPECIAL_BIT_VALUE) then
              state <= TRAILER_state;
            end if;

          end if;

        when TRAILER_state =>

          end_of_packet_o <= '1';

          chip_id_o <= zsh(frame(CHIPID_RANGE));
          crc_o     <= zsh(frame(CRC_RANGE));
          hitcnt_o  <= zsh(frame(HITS_RANGE));
          stat_o    <= zsh(frame(STATUS_RANGE));

          state <= IDLE_state;

        when others =>

          state <= ERR_state;

      end case;

      if (reset = '1') then
        state <= IDLE_state;
      end if;

    end if;
  end process;


  --------------------------------------------------------------------------------
  -- Bitslipping
  --------------------------------------------------------------------------------

end behavioral;
