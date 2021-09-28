#!/usr/bin/env python3
import math
import os
import pytest
import random
import functools

from cocotb_test.simulator import run

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.triggers import RisingEdge
from cocotb.triggers import Event


async def send_gbt_ic_transaction(dut, chip_adr, wr, nwords, reg_adr, data):
    ""

    data = [
        chip_adr << 1 | (0x0 if wr else 0x1),
        0x0,  # reserved
        0x0,  # command
        nwords & 0xff,
        (nwords >> 8) & 0xff,
        reg_adr & 0xff,
        (reg_adr >> 8) & 0xff,
        data & 0xff]

    parity = functools.reduce(lambda x, y: x ^ y, data)
    data.append(parity)

    await RisingEdge(dut.clock_i)
    for frame in data:
        dut.frame_i = frame
        dut.valid_i = 1
        await RisingEdge(dut.clock_i)
    dut.valid_i = 0

@cocotb.test()
async def gbt_ic_rx_test(dut):
    "Test the GBT IC RX state machine decoder"

    cocotb.fork(Clock(dut.clock_i, 40, units="ns").start())  # Create a clock

    dut.frame_i = 0
    dut.reset_i = 0
    dut.valid_i = 0

    for _ in range(1000):
        chip_adr = random.randint(0, 127)
        wr = 1
        nwords = 1
        reg_adr = random.randint(0, 255)
        data = random.randint(0, 255)

        await RisingEdge(dut.clock_i)

        await send_gbt_ic_transaction(dut, chip_adr, wr, nwords, reg_adr, data)

        await RisingEdge(dut.clock_i)
        await RisingEdge(dut.clock_i)

        assert dut.chip_adr_o.value == chip_adr
        assert dut.data_o.value == data
        assert dut.reg_adr_o.value == reg_adr
        assert dut.valid_o.value == 1
        assert dut.err_o.value == 0
        assert dut.length_o.value == nwords

    # for wr in [0, 1]:


def test_gbt_ic_rx():
    ""

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(tests_dir, "gbt_ic_rx.vhd")
    ]

    parameters = {}

    os.environ["SIM"] = "questa"

    run(
        verilog_sources=[],
        vhdl_sources=vhdl_sources,
        module=module,
        toplevel="gbt_ic_rx",
        toplevel_lang="vhdl",
        parameters=parameters,
        # sim_args = ["do cluster_packer_wave.do"],
        # extra_env = {"SIM": "questa"},
        gui=0
    )


if __name__ == "__main__":
    test_gbt_ic_rx()
