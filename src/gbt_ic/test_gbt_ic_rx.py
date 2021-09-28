#!/usr/bin/env python3
""
import os
import random
import functools

from cocotb_test.simulator import run

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


async def send_gbt_ic_transaction(dut, chip_adr, wr_bit, nwords, reg_adr, wr_data):
    ""

    data_frames = [
        chip_adr << 1 | (0 if wr_bit else 1),
        0x0,  # reserved
        0x0,  # command
        (nwords >> 0) & 0xff,
        (nwords >> 8) & 0xff,
        (reg_adr >> 0) & 0xff,
        (reg_adr >> 8) & 0xff] + wr_data

    parity = functools.reduce(lambda x, y: x ^ y, data_frames)
    data_frames.append(parity)

    await RisingEdge(dut.clock_i)
    dut.valid_i = 1
    for frame in data_frames:
        dut.frame_i = frame
        await RisingEdge(dut.clock_i)
    dut.valid_i = 0


@cocotb.test()
async def gbt_ic_rx_test(dut):
    "Test the GBT IC RX state machine decoder"

    cocotb.fork(Clock(dut.clock_i, 40, units="ns").start())  # Create a clock

    dut.frame_i = 0
    dut.reset_i = 0
    dut.valid_i = 0

    await RisingEdge(dut.clock_i)

    for wr_bit in [0, 1]:
        for nwords in [1, 2, 3, 4]:
            for _ in range(1000):

                # generate inputs
                chip_adr = random.randint(0, 127)
                reg_adr = random.randint(0, 255)
                wr_data = [random.randint(0, 255)] * nwords

                await RisingEdge(dut.clock_i)

                # send the transaction
                await send_gbt_ic_transaction(dut, chip_adr, wr_bit, nwords, reg_adr, wr_data)

                # wait for data to come out
                await RisingEdge(dut.clock_i)
                await RisingEdge(dut.clock_i)

                # ASSERT outputs
                assert dut.chip_adr_o.value == chip_adr
                assert dut.reg_adr_o.value == reg_adr
                assert dut.valid_o.value == 1
                assert dut.err_o.value == 0
                assert dut.length_o.value == nwords
                for i, databyte in enumerate(wr_data):
                    assert (dut.data_o.value >> 8 * i) & 0xff == databyte


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
