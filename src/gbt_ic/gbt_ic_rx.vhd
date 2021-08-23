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

  type rx_state_t is (IDLE, RESERVED, RSVRD, GBT_ADDR, CMD, LENGTH0, LENGTH1,
                      REG_ADR0, REG_ADR1, DATA, PARITY, TRAILER, OUTPUT, ERR);

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

  signal data_frame_cnt : integer range 0 to 2**16-1;

begin


  process (clock_i)
  begin
    if (rising_edge(clock_i)) then

      case rx_state is

        when IDLE =>

          if (valid_i = '1' and frame_i = "01111110") then
            rx_state <= RESERVED;
          end if;

        when RESERVED =>

          data_frame_cnt <= 0;

          if (valid_i = '1') then
            rx_state <= GBT_ADDR;
          end if;

        when GBT_ADDR =>

          if (valid_i = '1') then
            rx_state     <= CMD;
            chip_adr_int <= frame_i(7 downto 1);
            rw_bit_int   <= frame_i(0);
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
              rx_state <= PARITY;
            else
              data_frame_cnt <= data_frame_cnt + 1;
            end if;
          end if;

        when PARITY =>

          if (valid_i = '1') then
            rx_state      <= TRAILER;
            parity_int    <= parity_int;
            parity_rx_int <= frame_i;
          end if;

        when TRAILER =>

          if (frame_i = "01111110") then
            rx_state <= OUTPUT;
          else
            rx_state <= ERR;
          end if;

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

      if (rx_state = IDLE or reset_i = '1') then

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
