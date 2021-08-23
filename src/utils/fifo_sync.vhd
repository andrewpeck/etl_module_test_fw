library xpm;
use xpm.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity fifo_sync is
  generic (

    FIFO_TYPE        : string := "SYNC";
    FIFO_MEMORY_TYPE : string := "block";
    READ_MODE        : string := "std";
    ECC_MODE         : string := "no_ecc";

    DEPTH    : integer := 512; -- 16 to 4194304
    WR_WIDTH : integer := 64;
    RD_WIDTH : integer := 64;

    FULL_RESET_VALUE  : integer := 0;
    FIFO_READ_LATENCY : integer := 2;

    RD_DATA_COUNT_WIDTH : integer := 2;
    WR_DATA_COUNT_WIDTH : integer := 2;

    -- set to a positive value to enable
    PROG_FULL_THRESH  : integer := 3;
    PROG_EMPTY_THRESH : integer := 3;

    -- set to 1 to enable
    USE_PROG_EMPTY    : integer range 0 to 1 := 0;
    USE_PROG_FULL     : integer range 0 to 1 := 0;
    USE_WR_ACK        : integer range 0 to 1 := 0;
    USE_DATA_VALID    : integer range 0 to 1 := 1;
    USE_UNDERFLOW     : integer range 0 to 1 := 0;
    USE_RD_DATA_COUNT : integer range 0 to 1 := 0;
    USE_WR_DATA_COUNT : integer range 0 to 1 := 0;
    USE_ALMOST_EMPTY  : integer range 0 to 1 := 0;
    USE_ALMOST_FULL   : integer range 0 to 1 := 0
    );
  port (
    rst : in std_logic;
    clk : in std_logic;

    wr_en : in std_logic;
    rd_en : in std_logic;

    din  : in  std_logic_vector(WR_WIDTH-1 downto 0);
    dout : out std_logic_vector(RD_WIDTH-1 downto 0);

    valid : out std_logic;

    rd_data_count : out std_logic_vector (RD_DATA_COUNT_WIDTH-1 downto 0);
    wr_data_count : out std_logic_vector (WR_DATA_COUNT_WIDTH-1 downto 0);

    full         : out std_logic;
    prog_full    : out std_logic;
    almost_full  : out std_logic;
    almost_empty : out std_logic;

    empty      : out std_logic;
    prog_empty : out std_logic;

    overflow  : out std_logic;
    underflow : out std_logic;

    sbiterr : out std_logic;
    dbiterr : out std_logic
    );
end fifo_sync;

architecture behavioral of fifo_sync is

  function if_then_else (bool : boolean; a : std_logic; b : std_logic) return std_logic is
  begin
    if (bool) then
      return a;
    else
      return b;
    end if;
  end if_then_else;

  function to_std_logic(i : in integer) return std_logic is
  begin
    if i = 0 then
      return '0';
    end if;
    return '1';
  end function;

  constant USE_ADV_FEATURES : std_logic_vector (15 downto 0) := (
    0      => '0',                              -- 1 = enable overflow
    1      => to_std_logic(USE_PROG_FULL),      -- 1 = enable prog_full
    2      => to_std_logic(USE_WR_DATA_COUNT),  -- 1 = enable wr_data_count
    3      => to_std_logic(USE_ALMOST_FULL),    -- 1 = enable almost_full
    4      => to_std_logic(USE_WR_ACK),         -- 1 = enable wr_ack
    8      => to_std_logic(USE_UNDERFLOW),      -- 1 = enable underflow
    9      => to_std_logic(USE_PROG_EMPTY),     -- 1 = enable prog_empty
    10     => to_std_logic(USE_RD_DATA_COUNT),  -- 1 = enable rd_data_count
    11     => to_std_logic(USE_ALMOST_EMPTY),   -- 1 = enable almost_empty
    12     => to_std_logic(USE_DATA_VALID),     -- 1 = enable data_valid
    others => '0'
    );

  constant USE_ADV_FEATURES_STR : string (1 to 4) := to_hstring (USE_ADV_FEATURES);

begin

  sync : if (FIFO_TYPE = "SYNC") generate

    xpm_fifo_sync_inst : xpm_fifo_sync
      generic map (
        DOUT_RESET_VALUE    => "0",
        ECC_MODE            => ECC_MODE,
        FIFO_MEMORY_TYPE    => FIFO_MEMORY_TYPE,
        FIFO_READ_LATENCY   => FIFO_READ_LATENCY,
        FULL_RESET_VALUE    => FULL_RESET_VALUE,
        PROG_EMPTY_THRESH   => PROG_EMPTY_THRESH,
        PROG_FULL_THRESH    => PROG_FULL_THRESH,
        READ_MODE           => READ_MODE, -- READ_MODE means something (file related) in VHDL so it gets handled stupidly with syntax highlighting etc...
        USE_ADV_FEATURES    => USE_ADV_FEATURES_STR,
        WAKEUP_TIME         => 0,
        FIFO_WRITE_DEPTH    => DEPTH,
        READ_DATA_WIDTH     => RD_WIDTH,
        WRITE_DATA_WIDTH    => WR_WIDTH,
        RD_DATA_COUNT_WIDTH => RD_DATA_COUNT_WIDTH,
        WR_DATA_COUNT_WIDTH => WR_DATA_COUNT_WIDTH
        )
      port map (
        almost_empty  => almost_empty,  -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
        almost_full   => almost_full,   -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
        data_valid    => valid,         -- 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
        dbiterr       => dbiterr,       -- 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.
        dout          => dout,          -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven when reading the FIFO.
        empty         => empty,         -- 1-bit output: Empty Flag: When asserted, this signal indicates that the FIFO is empty. Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.
        full          => full,          -- 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full. Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
        overflow      => overflow,      -- 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.
        prog_empty    => prog_empty,    -- 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
        prog_full     => prog_full,     -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.
        rd_data_count => rd_data_count, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
        rd_rst_busy   => open,          -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
        sbiterr       => sbiterr,       -- 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
        underflow     => underflow,     -- 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.
        wr_ack        => open,          -- 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.
        wr_data_count => wr_data_count, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written into the FIFO.
        wr_rst_busy   => open,          -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.
        din           => din,           -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when writing the FIFO.
        injectdbiterr => '0',           -- 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        injectsbiterr => '0',           -- 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        rd_en         => rd_en,         -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO. Must be held active-low when rd_rst_busy is active high. .
        rst           => rst,           -- 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
        sleep         => '0',           -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo block is in power saving mode.
        wr_clk        => clk,           -- 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
        wr_en         => wr_en          -- 1-bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high
        );

  end generate;

end Behavioral;
