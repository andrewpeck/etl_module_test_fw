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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity etroc_selector is
  generic(
    g_NUM_INPUTS : positive := 24;
    g_WIDTH : positive := 40
    );
  port(

    clock : in std_logic;
    reset_i : in std_logic;

    -- data input
    data_i : in  std_logic_vector (g_WIDTH-1 downto 0);
    data_sel : out natural range 0 to g_NUM_INPUTS-1;

    -- input fifo controls
    busy_i : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    empty_i : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    valid_i : in  std_logic_vector (g_NUM_INPUTS - 1 downto 0);
    rd_en_o : out std_logic_vector (g_NUM_INPUTS - 1 downto 0);

    -- output fifo controls
    data_o : out  std_logic_vector (g_WIDTH-1 downto 0);
    wr_en_o : out std_logic

    );
end etroc_selector;

architecture behavioral of etroc_selector is

  type state_t is (IDLE_state, READING_state, SWITCH_state);

  signal state : state_t := IDLE_state;

  signal sel : natural range 0 to g_NUM_INPUTS-1 := 0;

  signal data : std_logic_vector (g_WIDTH-1 downto 0);
  signal busy : std_logic;
  signal valid : std_logic;
  signal empty : std_logic;

begin

  busy  <= busy_i(sel);
  empty <= empty_i(sel);
  valid <= valid_i(sel);
  data  <= data_i;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      rd_en_o <= (others => '0');

      case state is

        when IDLE_state =>

          -- selected FIFO has data in its buffer; start reading
          if (empty='0') then
            rd_en_o(sel) <= '1';
            state <= READING_state;

          -- nothing in this ETROC, look at the next one
          --
          -- TODO: this can be priority encoded, instead of just (incr sel)
          else
            if (sel=g_NUM_INPUTS-1) then
              sel <= 0;
            else
              sel <= sel + 1;
            end if;
          end if;

        when READING_state =>

          -- if the data buffer is empty, but we're not in the middle of a
          -- packet, we can switch to the next chip
          if (empty='1' and busy='0') then
            state <= IDLE_state;
          else
            -- keep reading
            rd_en_o(sel) <= '1';

            -- copy data to the output
            data_o <= data;
            wr_en_o <= valid;
          end if;

        when others =>

      end case;

    end if;
  end process;



end behavioral;
