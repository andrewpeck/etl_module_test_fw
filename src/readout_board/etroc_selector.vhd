----------------------------------------------------------------------------------
-- CMS Endcap Timing Layer
-- ETROC Readout Firmware
-- A. Peck, D. Spitzbart
-- Boston University
--
-- ETROC Selector
--
----------------------------------------------------------------------------------
-- Description:

-- The etroc selector is a dumb daq module that will control N fifo interfaces and
-- round-robin search through and drain them
--
-- It makes no effort to make event numbers match, and will not work well at
-- high data rates but it is a simple effort to allow readout of all ETROCs
-- through a single interface
--
-- TODO: Without much effort the round-robin search can be modified to a priority
-- encoded search
--
-- TODO: need a timeout

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity etroc_selector is
  generic(
    g_NUM_INPUTS : positive := 24;
    g_WIDTH      : positive := 42
    );
  port(

    clock   : in std_logic;
    reset_i : in std_logic;

    -- data input
    data_i : in std_logic_vector (g_WIDTH-1 downto 0);

    data_sel : out natural range 0 to g_NUM_INPUTS-1;

    -- input fifo controls
    sof_i   : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    eof_i   : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    ch_en_i : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    empty_i : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    valid_i : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    rd_en_o : out std_logic_vector (g_NUM_INPUTS - 1 downto 0);

    -- output fifo controls
    data_o  : out std_logic_vector (g_WIDTH-1 downto 0);
    wr_en_o : out std_logic

    );
end etroc_selector;

architecture behavioral of etroc_selector is

  type state_t is (IDLE_state, READING_state, SWITCH_state);

  signal state : state_t := IDLE_state;

  signal valid : std_logic;
  signal empty : std_logic;

  signal sof : std_logic := '0';
  signal eof : std_logic := '0';

  function next_sel (sel       : natural;
                     en        : std_logic_vector;
                     empty_arr : std_logic_vector)
    return natural is
    variable enabled_and_has_data : std_logic_vector(g_NUM_INPUTS-1 downto 0);
  begin
    enabled_and_has_data := en and not empty_arr;
    for I in 0 to g_NUM_INPUTS-1 loop
      if (I > sel and enabled_and_has_data(I) = '1') then
        return I;
      end if;
    end loop;
    return 0;
  end;

  signal next_channel : natural range 0 to g_NUM_INPUTS-1;

begin

  empty <= empty_i(data_sel);
  valid <= valid_i(data_sel);
  sof   <= sof_i(data_sel);
  eof   <= eof_i(data_sel);

  process (data_sel, ch_en_i, empty_i) is
  begin

    next_channel <= next_sel(data_sel, ch_en_i, empty_i);

    -- if (data_sel = g_NUM_INPUTS-1) then
    --   next_channel <= 0;
    -- else
    --   next_channel <= data_sel + 1;
    -- end if;

  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      rd_en_o <= (others => '0');
      data_o  <= (others => '0');
      wr_en_o <= '0';

      case state is

        when IDLE_state =>

          if (empty = '0' and ch_en_i(data_sel) = '1') then
            -- selected FIFO has data in its buffer;
            -- start reading
            rd_en_o(data_sel) <= '1';
            state             <= READING_state;
          else
            -- nothing in this ETROC, look at the next one
            data_sel <= next_channel;
          end if;

        when READING_state =>

          if (valid = '1') then
            data_o            <= data_i;
            wr_en_o           <= valid;
          end if;

          if (eof = '1') then
            -- when we reach the end of frame,
            -- switch to the next chip
            state    <= IDLE_state;
            data_sel <= next_channel;
          else
            -- FIXME: add a timeout here
            -- keep reading & copy data to the output
            rd_en_o(data_sel) <= '1';
          end if;

        when others =>

      end case;

    end if;
  end process;

end behavioral;
