----------------------------------------------------------------------------------
-- CMS Endcap Timing Layer
-- ETROC Readout Firmware
-- A. Peck, D. Spitzbart
-- Boston University
--
----------------------------------------------------------------------------------
--
-- This module generates a filler pattern than mimics the ETROC filler.
--
-- It produces 8 bits per 40MHz clock cycle.
--
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity tx_filler_generator is
  port(
    clock : in  std_logic;
    rst   : in  std_logic;
    l1a   : in  std_logic;
    bc0   : in  std_logic;
    tlast : out std_logic;
    tnext : out std_logic;
    dout  : out std_logic_vector (7 downto 0)
    );
end tx_filler_generator;

architecture behavioral of tx_filler_generator is

  type state_t is (D0, D1, D2, D3, D4);

  signal state : state_t := D0;

  signal data : std_logic_vector (39 downto 0)
    := (others => '0');

  signal data_byte : std_logic_vector (7 downto 0) := (others => '0');

  signal header : std_logic_vector (15 downto 0) := x"3C5C";

  signal bcid    : integer range 0 to 3563 := 0;
  signal l1a_cnt : integer range 0 to 255  := 0;

  function reverse_vector (a : std_logic_vector)
    return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'REverse_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_vector

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then

      if (bc0 = '1') then
        bcid <= 0;
      elsif (bcid = 3563) then
        bcid <= 0;
      else
        bcid <= bcid + 1;
      end if;

      if (l1a = '1') then
        if (l1a_cnt = 255) then
          l1a_cnt <= 0;
        else
          l1a_cnt <= l1a_cnt + 1;
        end if;
      end if;

    end if;
  end process;


  process (clock)
  begin
    if (rising_edge(clock)) then

      tlast <= '0';
      tnext <= '0';

      case state is

        when D0 =>
          state     <= D1;
          data_byte <= data(7 downto 0);
          tlast     <= '1';
          data      <= header & "10" &
                  std_logic_vector(to_unsigned(l1a_cnt, 8)) & "00" &
                  std_logic_vector(to_unsigned(bcid, 12));
        when D1 =>
          state     <= D2;
          data_byte <= data(15 downto 8);
        when D2 =>
          state     <= D3;
          data_byte <= data(23 downto 16);
        when D3 =>
          state     <= D4;
          data_byte <= data(31 downto 24);
          tnext     <= '1';
        when D4 =>
          data_byte <= data(39 downto 32);
          state     <= D0;
      end case;

      if rst = '1' then
        state <= D0;
      end if;

      dout <= reverse_vector(data_byte);

    end if;
  end process;


end behavioral;
