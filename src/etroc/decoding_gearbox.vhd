--! This file is part of the FELIX firmware distribution (https://gitlab.cern.ch/atlas-tdaq-felix/firmware/).
--! Copyright (C) 2001-2021 CERN for the benefit of the ATLAS collaboration.
--! Authors:
--!               Frans Schreuder
--!
--!   Licensed under the Apache License, Version 2.0 (the "License");
--!   you may not use this file except in compliance with the License.
--!   You may obtain a copy of the License at
--!
--!       http://www.apache.org/licenses/LICENSE-2.0
--!
--!   Unless required by applicable law or agreed to in writing, software
--!   distributed under the License is distributed on an "AS IS" BASIS,
--!   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--!   See the License for the specific language governing permissions and
--!   limitations under the License.

-- Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity DecodingGearBox is
  generic (
    MAX_INPUT      : integer := 32;
    MAX_OUTPUT     : integer := 66;
    -- 32, 16, 8, 4, 2
    SUPPORT_INPUT  : std_logic_vector(4 downto 0);
    -- 66, 4x10, 2x10, 10, 8
    SUPPORT_OUTPUT : std_logic_vector(4 downto 0)
    );
  port (
    Reset : in std_logic;               -- Active high reset
    clk40 : in std_logic;               -- BC clock

    ELinkData        : in std_logic_vector(MAX_INPUT-1 downto 0);
    ElinkAligned     : in std_logic;
    ElinkWidth       : in std_logic_vector(2 downto 0);  -- runtime configuration: 0:2, 1:4, 2:8, 3:16, 4:32
    MsbFirst         : in std_logic;                     --Default 1, make 0 to reverse the bit order
    ReverseInputBits : in std_logic;                     --Default 0, reverse the bits of the input Elink

    DataOut      : out std_logic_vector(MAX_OUTPUT-1 downto 0);  -- Aligned output with set number of bits.
    DataOutValid : out std_logic;                                --DataOut valid indicator
    OutputWidth  : in  std_logic_vector(2 downto 0);             --runtime configuration: 0:8, 1:10, 2:20, 3:40, 4:66

    BitSlip : in std_logic              --R Triggered by the protocol decoder to shift one bit

    );
end DecodingGearBox;

architecture rtl of DecodingGearBox is
  signal wIn       : integer range 0 to MAX_INPUT;   --Variable defined input width
  signal wOut      : integer range 0 to MAX_OUTPUT;  --Variable defined input width
  signal buf       : std_logic_vector((MAX_INPUT+MAX_OUTPUT)-1 downto 0);
  signal BitsInBuf : integer range 0 to (MAX_INPUT+MAX_OUTPUT);
begin

--! Gearbox for 2, 4, 8, 16 and 32b input and 8, 10, 2x10, 4x10 and 66b output.
  shift_proc : process(clk40, Reset)


    variable DataOut_v : std_logic_vector(MAX_OUTPUT-1 downto 0);
  begin
    if (Reset = '1') then
      buf          <= (others => '0');
      DataOut      <= (others => '0');
      DataOutValid <= '0';
      BitsInBuf    <= 0;
      wIn          <= MAX_INPUT;
      wOut         <= MAX_OUTPUT;
    elsif rising_edge(clk40) then
      DataOutValid <= '0';
      if (ElinkAligned = '1') then
        --32 bit Elink shift in
        if SUPPORT_INPUT(4) = '1' and MAX_INPUT = 32 and ElinkWidth = "100" then
          wIn <= 32;
        end if;
        --16 bit Elink shift in
        if SUPPORT_INPUT(3) = '1' and MAX_INPUT >= 16 and ElinkWidth = "011" then
          wIn <= 16;
        end if;
        --8 bit Elink shift in
        if SUPPORT_INPUT(2) = '1' and MAX_INPUT >= 8 and ElinkWidth = "010" then
          wIn <= 8;
        end if;
        --4 bit Elink shift in
        if SUPPORT_INPUT(1) = '1' and MAX_INPUT >= 4 and ElinkWidth = "001" then
          wIn <= 4;
        end if;
        --2 bit Elink shift in
        if SUPPORT_INPUT(0) = '1' and MAX_INPUT >= 2 and ElinkWidth = "000" then
          wIn <= 2;
        end if;

        --66 bit output
        if SUPPORT_OUTPUT(4) = '1' and MAX_OUTPUT >= 66 and OutputWidth = "100" then
          wOut <= 66;
        end if;
        --40 bit output
        if SUPPORT_OUTPUT(3) = '1' and MAX_OUTPUT >= 40 and OutputWidth = "011" then
          wOut <= 40;
        end if;
        --20 bit output
        if SUPPORT_OUTPUT(2) = '1' and MAX_OUTPUT >= 20 and OutputWidth = "010" then
          wOut <= 20;
        end if;
        --10 bit output
        if SUPPORT_OUTPUT(1) = '1' and MAX_OUTPUT >= 10 and OutputWidth = "001" then
          wOut <= 10;
        end if;
        --8 bit output
        if SUPPORT_OUTPUT(0) = '1' and MAX_OUTPUT >= 8 and OutputWidth = "000" then
          wOut <= 8;
        end if;

        for i in buf'high downto 0 loop
          if(i >= wIn) then
            buf(i) <= buf(i-wIn);
          else
            if(i < MAX_INPUT) then
              if (MsbFirst xor ReverseInputBits) = '0' then
                buf(i) <= ELinkData((wIn-1)-i);
              else
                buf(i) <= ELinkData(i);
              end if;
            end if;
          end if;
        end loop;

        if (BitsInBuf < wOut or (BitsInBuf = 0 and wIn = wOut and BitSlip = '1')) then  --we can't output enough in this case if bitslip is asserted.
          if BitSlip = '1' then
            BitsInBuf <= BitsInBuf + wIn - 1;                                           --Only add the number of bits on input, since no data was taken out of the buffer, -1 for bitslip.
          else
            BitsInBuf <= BitsInBuf + wIn;                                               --Only add the number of bits on input, since no data was taken out of the buffer
          end if;
          DataOutValid <= '0';
        else
          for i in MAX_OUTPUT-1 downto 0 loop
            if (i < wOut) then
              DataOut_v(i) := buf(BitsInBuf-((wOut)-i));
            else
              DataOut_v(i) := '0';
            end if;
          end loop;
          --DataOut_v(wOut-1 downto 0) := buf(BitsInBuf-1 downto BitsInBuf-wOut);
          if MsbFirst = '1' then
            DataOut <= DataOut_v;
          else
            for i in 0 to MAX_OUTPUT-1 loop
              if(i < wOut) then
                DataOut(i) <= DataOut_v((wOut-1)-i);
              end if;
            end loop;
          end if;
          DataOutValid <= '1';
          if BitSlip = '1' then
            BitsInBuf <= BitsInBuf + (wIn - wOut) - 1;                                  --Add input bits, but subtract output bits that were shefted out, -1 for bitslip.
          else
            BitsInBuf <= BitsInBuf + (wIn - wOut);                                      --Add input bits, but subtract output bits that were shefted out.
          end if;
        end if;

      end if;
    end if;
  end process;


end rtl;
