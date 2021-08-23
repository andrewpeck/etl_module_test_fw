library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity gbt_ic_rx is
  port(
    clock_i : in std_logic;             -- 40MHz clock
    reset_i : in std_logic;             -- state machine reset

    frame_i : in std_logic_vector (7 downto 0);  -- 8 bit frame from gbt-sc
    valid_i : in std_logic;                      -- set high for valid data frames

    -- Control
    chip_adr_o           : out std_logic_vector (6 downto 0) := (others => '0');  -- lpgbt chip address
    data_o               : out std_logic_vector(31 downto 0) := (others => '0');
    length_o             : out std_logic_vector(15 downto 0) := (others => '0');
    reg_adr_o            : out std_logic_vector(15 downto 0) := (others => '0');
    uplink_parity_ok_o   : out std_logic                     := '0';
    downlink_parity_ok_o : out std_logic                     := '0';
    err_o                : out std_logic                     := '0';
    valid_o              : out std_logic                     := '0'
    );
end gbt_ic_rx;

architecture Behavioral of gbt_ic_rx is

  type rx_state_t is (IDLE, RSVRD, CMD, LENGTH0, LENGTH1, REG_ADR0, REG_ADR1,
                      DATA, PARITY, TRAILER, OUTPUT, ERR);

  signal rx_state : rx_state_t;

  signal rsvrd_int              : std_logic_vector (7 downto 0);
  signal chip_adr_int           : std_logic_vector (6 downto 0);
  signal downlink_parity_ok_int : std_logic;
  signal length_int             : std_logic_vector (15 downto 0);
  signal reg_adr_int            : std_logic_vector (15 downto 0);
  signal parity_int             : std_logic_vector (7 downto 0);
  signal parity_rx_int          : std_logic_vector (7 downto 0);
  signal rw_bit_int             : std_logic;
  signal data_int               : std_logic_vector (31 downto 0);

  constant watchdog_cnt_max : integer                             := 127;
  signal watchdog_cnt       : integer range 0 to watchdog_cnt_max := 0;
  signal watchdog_reset     : std_logic                           := '0';

  signal data_frame_cnt : integer range 0 to 2**16-1;

  component ila_ic

    port (
      clk : in std_logic;

      probe0  : in std_logic_vector(3 downto 0);
      probe1  : in std_logic_vector(0 downto 0);
      probe2  : in std_logic_vector(7 downto 0);
      probe3  : in std_logic_vector(6 downto 0);
      probe4  : in std_logic_vector(31 downto 0);
      probe5  : in std_logic_vector(15 downto 0);
      probe6  : in std_logic_vector(15 downto 0);
      probe7  : in std_logic_vector(0 downto 0);
      probe8  : in std_logic_vector(0 downto 0);
      probe9  : in std_logic_vector(0 downto 0);
      probe10 : in std_logic_vector(0 downto 0)
      );
  end component;

begin

  ila_ic_inst : ila_ic

    port map (
      clk                 => clock_i,
      probe0(3 downto 0)  => std_logic_vector(to_unsigned(rx_state_t'pos(rx_state), 4)),
      probe1(0)           => valid_i,
      probe2(7 downto 0)  => frame_i,
      probe3(6 downto 0)  => chip_adr_o,
      probe4(31 downto 0) => data_o,
      probe5(15 downto 0) => length_o,
      probe6(15 downto 0) => reg_adr_o,
      probe7(0)           => uplink_parity_ok_o,
      probe8(0)           => downlink_parity_ok_o,
      probe9(0)           => err_o,
      probe10(0)          => valid_o
      );

  --------------------------------------------------------------------------------
  -- watchdog to keep the state machine from getting stuck (e.g. because the
  --  headder is stripped off, it seems like sometimes it spuriously gets in the
  --  wrong state)
  --
  -- This just waits a reasonably long time then takes the state machine back to
  -- IDLE
  --------------------------------------------------------------------------------

  watchdog_reset <= '1' when watchdog_cnt = watchdog_cnt_max else '0';

  process (clock_i) is
  begin
    if (rising_edge(clock_i)) then
      if (rx_state = IDLE) then
        watchdog_cnt <= 0;
      else
        if (watchdog_cnt < watchdog_cnt_max) then
          watchdog_cnt <= watchdog_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- state machine
  --------------------------------------------------------------------------------

  process (clock_i)
  begin
    if (rising_edge(clock_i)) then

      case rx_state is

        when IDLE =>

          -- note that the GBT-SC core strips off the header and trailer, so
          -- what we see from the lpgbt is:
          --
          -- i=0, data=0xe7 or 0xe6  -- adr + rw
          -- i=1, data=0x00          -- rsvrd
          -- i=2, data=0x01          -- cmd
          -- i=3, data=0x01          -- nwords [7:0]
          -- i=4, data=0x00          -- nwords [15:8]
          -- i=5, data=0xc5          -- adr[7:0]
          -- i=6, data=0x01          -- adr[15:8]
          -- i=7, data=0xa5          -- data
          -- i=8, data=0x61          -- parity
          --

          if (valid_i = '1') then
            rx_state     <= RSVRD;
            chip_adr_int <= frame_i(7 downto 1);
            rw_bit_int   <= frame_i(0);
          end if;

        when RSVRD =>

          if (valid_i = '1') then
            rx_state <= CMD;
          end if;

        when CMD =>

          if (valid_i = '1') then
            rx_state               <= LENGTH0;
            downlink_parity_ok_int <= frame_i(0);
            parity_int             <= frame_i;
          end if;

        when LENGTH0 =>

          if (valid_i = '1') then
            rx_state               <= LENGTH1;
            length_int(7 downto 0) <= frame_i;
            parity_int             <= parity_int xor frame_i;
          end if;

        when LENGTH1 =>

          if (valid_i = '1') then
            rx_state                <= REG_ADR0;
            length_int(15 downto 8) <= frame_i;
            parity_int              <= parity_int xor frame_i;
          end if;

        when REG_ADR0 =>

          if (valid_i = '1') then
            rx_state                <= REG_ADR1;
            reg_adr_int(7 downto 0) <= frame_i;
            parity_int              <= parity_int xor frame_i;
          end if;

        when REG_ADR1 =>

          if (valid_i = '1') then
            reg_adr_int(15 downto 8) <= frame_i;
            parity_int               <= parity_int xor frame_i;
            rx_state                 <= DATA;
          end if;

        when DATA =>

          if (valid_i = '1') then
            parity_int <= parity_int xor frame_i;
            case data_frame_cnt mod 4 is
              when 0      => data_int (7 downto 0)   <= frame_i;
              when 1      => data_int (15 downto 8)  <= frame_i;
              when 2      => data_int (23 downto 16) <= frame_i;
              when 3      => data_int (31 downto 24) <= frame_i;
              when others => data_int                <= data_int;
            end case;

            if (std_logic_vector(to_unsigned(data_frame_cnt+1, length_int'length)) = length_int) then
              rx_state <= TRAILER;
            else
              data_frame_cnt <= data_frame_cnt + 1;
            end if;
          end if;

        when PARITY =>

          if (valid_i = '1') then
            rx_state      <= OUTPUT;
            parity_int    <= parity_int;
            parity_rx_int <= frame_i;
          end if;

          -- when TRAILER =>

          --   -- why x"61"? see note above
          --   if (frame_i = x"61") then
          --     rx_state <= OUTPUT;
          --   else
          --     rx_state <= ERR;
          --   end if;

        when OUTPUT =>

          if (parity_int = parity_rx_int) then
            uplink_parity_ok_o <= '1';
          else
            uplink_parity_ok_o <= '0';
          end if;

          chip_adr_o           <= chip_adr_int;
          downlink_parity_ok_o <= downlink_parity_ok_int;
          length_o             <= length_int;
          reg_adr_o            <= reg_adr_int;
          data_o               <= data_int;
          valid_o              <= '1';

          rx_state <= IDLE;

        when ERR =>

          err_o    <= '1';
          rx_state <= IDLE;

        when others =>
          rx_state <= IDLE;

      end case;

      --------------------------------------------------------------------------------
      -- Reset
      --------------------------------------------------------------------------------

      if (rx_state = IDLE or reset_i = '1' or watchdog_reset = '1') then

        if (reset_i = '1') then
          rx_state <= IDLE;
        end if;

        rsvrd_int              <= (others => '0');
        chip_adr_int           <= (others => '0');
        downlink_parity_ok_int <= '0';
        length_int             <= (others => '0');
        reg_adr_int            <= (others => '0');
        parity_int             <= (others => '0');
        parity_rx_int          <= (others => '0');
        data_int               <= (others => '0');
        rw_bit_int             <= '0';
        err_o                  <= '0';

      end if;

    end if;
  end process;

end Behavioral;
