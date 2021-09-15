library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
library ipbus;
use ipbus.ipbus.all;

entity wishbone_fifo_reader is
  port(
    clk   : in std_logic;
    reset : in std_logic;

    -- set to 1 when module is selected by wishbone to prevent bus contention
    --
    -- if your wishbone mux can deal with one slave keeping ack asserted then
    -- this doesn't matter, but that is not how the ipbus wishbone arbiter works
    --
    sel : in std_logic;

    -- wishbone
    ipbus_in  : in  ipb_wbus;
    ipbus_out : out ipb_rbus;

    -- fifo
    rd_en : out std_logic;
    din   : in  std_logic_vector(31 downto 0);
    valid : in  std_logic;
    empty : in  std_logic
    );

end wishbone_fifo_reader;

architecture rtl of wishbone_fifo_reader is

  signal words_todo     : integer range 0 to 255 := 0;
  signal words_todo_buf : integer range 0 to 255 := 0;

  signal strobe_r  : std_logic := '0';
  signal strobe_os : std_logic := '0';

begin

  -- some tricks to allow this to run at full-throughput,
  -- reading a FIFO word every clock tick
  --
  -- ack connects directly to the FIFO
  --
  -- Prior to the actual wishbone packet, the previous data frame is e.g.
  -- 0x20000XX2f, where
  -- 0x-----XX-- XX is the number of requests, from 0-255
  --
  -- we take this # of requests, called words_todo, and use it to know a-priori
  -- how many reads will be requested
  --
  -- note that this is not standard wishbone and will only work with ipbus
  --
  -- see transactor_sm.vhd

  process (clk) is
  begin
    if (rising_edge(clk)) then

      if (ipbus_in.ipb_wdata(31 downto 24) = x"20"
          and ipbus_in.ipb_wdata(7 downto 0) = x"2f") then
        words_todo_buf <= to_integer(unsigned(ipbus_in.ipb_wdata(15 downto 8)));
      end if;

      strobe_r <= ipbus_in.ipb_strobe;

      if (strobe_os = '1') then
        words_todo <= words_todo_buf;
      elsif (words_todo > 0) then
        words_todo <= words_todo - 1;
      end if;

    end if;
  end process;

  strobe_os <= '1' when ipbus_in.ipb_strobe = '1' and strobe_r = '0' else '0';

  rd_en <= '1' when words_todo > 0 else '0';

  ipbus_out.ipb_rdata <= din;

  -- ack on valid or empty so we don't make a bus error from an empty FIFO
  --
  -- this however keeps ack high if the FIFO is empty which creates some kind of
  -- bus contention.
  --
  -- for this reason the SEL input is provided so you can specify when
  -- this module's address range is selected
  --

  ipbus_out.ipb_ack   <= (valid or empty) when sel = '1' else '0';

  ipbus_out.ipb_err <= '0';

end rtl;
