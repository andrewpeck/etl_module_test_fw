library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lpgbt_fpga;
use lpgbt_fpga.lpgbtfpga_package.all;

library work;
use work.types.all;
use work.lpgbt_pkg.all;

entity lpgbt_link_wrapper is
  generic (
    -- lpgbt controls
    g_LPGBT_BYPASS_INTERLEAVER          : std_logic := '0';
    g_LPGBT_BYPASS_FEC                  : std_logic := '0';
    g_LPGBT_BYPASS_SCRAMBLER            : std_logic := '0';
    g_DOWNLINK_WORD_WIDTH               : integer   := 32;  -- IC + EC + User Data + FEC
    g_DOWNLINK_MULTICYCLE_DELAY         : integer   := 4;  -- Multicycle delay: USEd to relax the timing constraints
    g_DOWNLINK_CLOCK_RATIO              : integer   := 8;  -- Clock ratio is clock_out / 40 (shall be an integer - E.g.: 320/40 = 8)
    g_UPLINK_DATARATE                   : integer   := DATARATE_10G24;
    g_UPLINK_MULTICYCLE_DELAY           : integer   := 4;  -- --! Multicycle delay: Used to relax the timing constraints
    g_UPLINK_CLOCK_RATIO                : integer   := 8;  -- Clock ratio is clock_out / 40 (shall be an integer - E.g.: 320/40 = 8)
    g_UPLINK_WORD_WIDTH                 : integer   := 32;
    g_UPLINK_ALLOWED_FALSE_HEADER       : integer   := 5;
    g_UPLINK_ALLOWED_FALSE_HEADER_OVERN : integer   := 64;
    g_UPLINK_REQUIRED_TRUE_HEADER       : integer   := 30;
    g_UPLINK_BITSLIP_MINDLY             : integer   := 1;
    g_UPLINK_BITSLIP_WAITDLY            : integer   := 40;

    -- quantities
    g_NUM_DOWNLINKS : integer := 1;
    g_NUM_UPLINKS   : integer := 2;

    -- pipeline registers
    g_PIPELINE_BITSLIP : boolean := true;
    g_PIPELINE_LPGBT   : boolean := true;
    g_PIPELINE_MGT     : boolean := true
    );
  port(

    reset : in std_logic;

    --------------------------------------------------------------------------------
    -- Downlink
    --------------------------------------------------------------------------------

    -- 320 Mhz Downlink Fabric Clock
    downlink_clk : in std_logic;

    -- 1 bit valid (strobe at 40MHz)
    -- 32 bits / bx from fabric
    -- 2 bits ic
    -- 2 bits ec
    downlink_data_i : in lpgbt_downlink_data_rt_array (g_NUM_DOWNLINKS-1 downto 0);

    -- reset
    downlink_reset_i : in std_logic_vector (g_NUM_DOWNLINKS-1 downto 0);

    -- ready
    downlink_ready_o : out std_logic_vector (g_NUM_DOWNLINKS-1 downto 0);

    -- 32 bits / bx to mgt
    downlink_mgt_word_array_o : out std32_array_t (g_NUM_DOWNLINKS-1 downto 0);

    --------------------------------------------------------------------------------
    -- Uplink
    --------------------------------------------------------------------------------

    -- 320 MHz Uplink Fabric Clock
    uplink_clk : in std_logic;          -- 320 MHz

    -- 1 bit valid output (strobes at 40MHz)
    -- 224 bits / bx to fabric
    -- 2 bits ic
    -- 2 bits ec
    uplink_data_o : out lpgbt_uplink_data_rt_array (g_NUM_UPLINKS-1 downto 0);

    -- 256 bits / bx from mgt
    uplink_mgt_word_array_i : in std32_array_t (g_NUM_UPLINKS-1 downto 0);

    -- reset
    uplink_reset_i : in std_logic_vector (g_NUM_UPLINKS-1 downto 0);

    -- ready
    uplink_ready_o : out std_logic_vector (g_NUM_UPLINKS-1 downto 0);

    -- fec mode
    fec_mode_i : in std_logic_vector (g_NUM_UPLINKS-1 downto 0) := (others => '0');

    -- bitslip flag to connect to mgt rxslide for alignment
    uplink_bitslip_o : out std_logic_vector (g_NUM_UPLINKS-1 downto 0);

    uplink_fec_err_o : out std_logic_vector (g_NUM_UPLINKS-1 downto 0)

    );
end lpgbt_link_wrapper;


architecture Behavioral of lpgbt_link_wrapper is

  constant COUNTER_WIDTH : integer := 16;
  type counter_array_t is array (integer range <>) of std_logic_vector(COUNTER_WIDTH-1 downto 0);
  -- counters
  signal fec_err_cnt     : counter_array_t(g_NUM_UPLINKS-1 downto 0);

begin

  --------------------------------------------------------------------------------
  -- Downlink
  --------------------------------------------------------------------------------

  downlink_gen : for I in 0 to g_NUM_DOWNLINKS-1 generate

    signal downlink_data    : lpgbt_downlink_data_rt;
    signal mgt_data         : std_logic_vector(31 downto 0);
    signal downlink_reset_n : std_logic := '1';
    signal downlink_ready   : std_logic_vector (g_NUM_DOWNLINKS-1 downto 0);

  begin

    downlink_reset_fanout : process (downlink_clk) is
    begin  -- process reset_fanout
      if rising_edge(downlink_clk) then  -- rising clock edge
        downlink_reset_n <= not (reset or downlink_reset_i(I));
      end if;
    end process;

    downlink_inst : entity lpgbt_fpga.lpgbtfpga_downlink

      generic map (
        c_multicyleDelay => g_DOWNLINK_MULTICYCLE_DELAY,
        c_clockRatio     => g_DOWNLINK_CLOCK_RATIO,
        c_outputWidth    => g_DOWNLINK_WORD_WIDTH
        )
      port map (
        clk_i               => downlink_clk,
        rst_n_i             => downlink_reset_n,
        clken_i             => downlink_data.valid,
        userdata_i          => downlink_data.data,
        ecdata_i            => downlink_data.ec,
        icdata_i            => downlink_data.ic,
        mgt_word_o          => mgt_data,
        interleaverbypass_i => g_LPGBT_BYPASS_INTERLEAVER,
        encoderbypass_i     => g_LPGBT_BYPASS_FEC,
        scramblerbypass_i   => g_LPGBT_BYPASS_SCRAMBLER,
        rdy_o               => downlink_ready(I)
        );

    --------------------------------------------------------------------------------
    -- optionally pipeline some of the downlink registers
    -- (fixed some timing issues)
    --------------------------------------------------------------------------------

    process (downlink_clk) is
    begin
      if (rising_edge(downlink_clk)) then
        downlink_ready_o(I) <= downlink_ready(I);
      end if;
    end process;

    downlink_data_pipe : process (downlink_clk, downlink_data_i) is
    begin
      if rising_edge(downlink_clk) or (not g_PIPELINE_LPGBT) then
        downlink_data <= downlink_data_i(I);
      end if;
    end process;

    downlink_mgt_pipe : process (downlink_clk, mgt_data) is
    begin
      if rising_edge(downlink_clk) or (not g_PIPELINE_MGT) then
        downlink_mgt_word_array_o(I) <= mgt_data;
      end if;
    end process;

  end generate;

--------------------------------------------------------------------------------
-- Uplink
--------------------------------------------------------------------------------

  uplink_gen : for I in 0 to g_NUM_UPLINKS-1 generate

    signal uplink_data : lpgbt_uplink_data_rt;
    signal mgt_data    : std_logic_vector(31 downto 0);
    signal bitslip     : std_logic;
    signal unused_bits : std_logic_vector(5 downto 0);

    signal fec_err         : std_logic := '0';
    signal datacorrected   : std_logic_vector (229 downto 0);
    signal datacorrected_r : std_logic_vector (229 downto 0);
    signal reduce_pipe_s0  : std_logic_vector (32*7+1-1 downto 0) := (others => '0');
    signal iccorrected     : std_logic_vector (1 downto 0);
    signal eccorrected     : std_logic_vector (1 downto 0);

    signal uplink_reset_n : std_logic := '1';

    signal uplink_ready : std_logic;

    ----------------------
    -- FEC signals 
    ----------------------
    signal fec_sel           : integer range 0 to 1;
    signal fec_uplink_data   : lpgbt_uplink_data_rt_array(1 downto 0);
    signal fec_unused_bits   : std_logic_vector(11 downto 0);
    signal fec_bitslip       : std_logic_vector(1 downto 0);
    signal fec_datacorrected : std_logic_vector (459 downto 0);
    signal fec_iccorrected   : std_logic_vector (3 downto 0);
    signal fec_eccorrected   : std_logic_vector (3 downto 0);
    signal fec_uplink_ready  : std_logic_vector (1 downto 0);
    

  begin

    uplink_reset_fanout : process (uplink_clk) is
    begin  -- process reset_fanout
      if rising_edge(uplink_clk) then   -- rising clock edge
        uplink_reset_n <= not (reset or uplink_reset_i(I));  -- active LOW
      end if;
    end process;

    fec_mode_uplink_gen : for J in 0 to 1 generate
    begin
      uplink_inst : entity lpgbt_fpga.lpgbtfpga_uplink

        generic map (
          datarate                  => g_UPLINK_DATARATE,
          fec                       => J + 1,  -- FEC5 = 1 FEC12 = 2
          c_multicyledelay          => g_UPLINK_MULTICYCLE_DELAY,
          c_clockratio              => g_UPLINK_CLOCK_RATIO,
          c_mgtwordwidth            => g_UPLINK_WORD_WIDTH,
          c_allowedfalseheader      => g_UPLINK_ALLOWED_FALSE_HEADER,
          c_allowedfalseheaderovern => g_UPLINK_ALLOWED_FALSE_HEADER_OVERN,
          c_requiredtrueheader      => g_UPLINK_REQUIRED_TRUE_HEADER,
          c_bitslip_mindly          => g_UPLINK_BITSLIP_MINDLY,
          c_bitslip_waitdly         => g_UPLINK_BITSLIP_WAITDLY
          )

        port map (
          uplinkclk_i         => uplink_clk,
          uplinkrst_n_i       => uplink_reset_n,
          mgt_word_i          => mgt_data,
          bypassinterleaver_i => g_LPGBT_BYPASS_INTERLEAVER,
          bypassfecencoder_i  => g_LPGBT_BYPASS_FEC,
          bypassscrambler_i   => g_LPGBT_BYPASS_SCRAMBLER,

          uplinkclkouten_o           => fec_uplink_data(J).valid,
          userdata_o(223 downto 0)   => fec_uplink_data(J).data,
          userdata_o(229 downto 224) => fec_unused_bits(J * 6 + 5 downto J * 6),
          ecdata_o                   => fec_uplink_data(J).ec,  --external control
          icdata_o                   => fec_uplink_data(J).ic,  --internal control
          mgt_bitslipctrl_o          => fec_bitslip(J),
          datacorrected_o            => fec_datacorrected(J * 230 + 229 downto J * 230),
          iccorrected_o              => fec_iccorrected(J * 2 + 1 downto J * 2),
          eccorrected_o              => fec_eccorrected(J * 2 + 1 downto J * 2),
          rdy_o                      => fec_uplink_ready(J)
          );
    end generate;

    --------------------------------------------------------------------------------
    -- FEC Select Multiplexing
    --------------------------------------------------------------------------------

    -- Converting fec_mode_i into an integer
    fec_sel <= 1 when fec_mode_i(I) = '1' else 0;

    process (uplink_clk) is
    begin
      if (rising_edge(uplink_clk)) then
        uplink_data   <= fec_uplink_data(fec_sel);
        unused_bits   <= fec_unused_bits(fec_sel * 6 + 5 downto fec_sel * 6);
        bitslip       <= fec_bitslip(fec_sel);
        datacorrected <= fec_datacorrected(fec_sel * 230 + 229 downto fec_sel * 230);
        iccorrected   <= fec_iccorrected(fec_sel * 2 + 1 downto fec_sel * 2);
        eccorrected   <= fec_eccorrected(fec_sel * 2 + 1 downto fec_sel * 2);
        uplink_ready  <= fec_uplink_ready(fec_sel);
      end if;
    end process;

    --------------------------------------------------------------------------------
    -- Error Counters
    --------------------------------------------------------------------------------

    process (uplink_clk) is
    begin
      if (rising_edge(uplink_clk)) then

        -- pipeline to ease timing

        datacorrected_r <= datacorrected;

        reduce_pipe_s0(0) <= or_reduce(datacorrected_r(31 downto 0));
        reduce_pipe_s0(1) <= or_reduce(datacorrected_r(63 downto 32));
        reduce_pipe_s0(2) <= or_reduce(datacorrected_r(95 downto 64));
        reduce_pipe_s0(3) <= or_reduce(datacorrected_r(127 downto 96));
        reduce_pipe_s0(4) <= or_reduce(datacorrected_r(159 downto 128));
        reduce_pipe_s0(5) <= or_reduce(datacorrected_r(191 downto 160));
        reduce_pipe_s0(6) <= or_reduce(datacorrected_r(223 downto 192));
        reduce_pipe_s0(7) <= or_reduce(iccorrected & eccorrected & datacorrected_r(229 downto 224));

        uplink_fec_err_o(I) <= or_reduce(reduce_pipe_s0 (7 downto 0));
      end if;
    end process;

    --------------------------------------------------------------------------------
    -- optionally pipeline some of the uplink registers
    -- (fixed some timing issues)
    --------------------------------------------------------------------------------

    process (uplink_clk) is
    begin
      if (rising_edge(uplink_clk)) then
        uplink_ready_o(I) <= uplink_ready;
      end if;
    end process;

    uplink_data_pipe : process (uplink_clk, uplink_data) is
    begin
      if rising_edge(uplink_clk) or (not g_PIPELINE_LPGBT) then
        uplink_data_o(I) <= uplink_data;
      end if;
    end process;

    mgt_data_pipe : process (uplink_clk, uplink_mgt_word_array_i(I)) is
    begin  -- process uplink_data_pipe
      if rising_edge(uplink_clk) or (not g_PIPELINE_MGT) then
        mgt_data <= uplink_mgt_word_array_i(I);
      end if;
    end process;

    bitslip_pipe : process (uplink_clk, bitslip) is
    begin  -- process uplink_data_pipe
      if rising_edge(uplink_clk) or (not g_PIPELINE_BITSLIP) then
        uplink_bitslip_o(I) <= bitslip;
      end if;
    end process;

  end generate;

end Behavioral;
