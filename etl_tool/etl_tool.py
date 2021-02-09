#!/usr/bin/env python3
#
# Handy list of reg methods:
#   reg.getAddress(
#   reg.getClient(
#   reg.getDescription(
#   reg.getFirmwareInfo(
#   reg.getId(
#   reg.getMask(
#   reg.getMode(
#   reg.getModule(
#   reg.getNode(
#   reg.getNodes(
#   reg.getParameters(
#   reg.getPath(
#   reg.getPermission(
#   reg.getSize(
#   reg.getTags(
#   reg.read(
#   reg.readBlock(
#   reg.readBlockOffset(
#   reg.write(
#   reg.writeBlock(
#   reg.writeBlockOffset(

import os
import random  # For randint
import uhal
import argparse
import reg_parser as lpgbt
import colors
import matplotlib.pyplot as plt
import numpy as np
import sys
from time import sleep

IPB_PATH = "ipbusudp-2.0://192.168.0.10:50001"
ADR_TABLE = "../address_tables/etl_test_fw.xml"


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument('-ipbus',
                        '--ipbus',
                        dest='ipbus',
                        help="Ipbus Endpoint, e.g. ipbusudp-2.0://192.168.0.10:50001")

    parser.add_argument('-x',
                        '--xml',
                        dest='xml',
                        help="XML Address Table")

    parser.add_argument('-a',
                        '--addr',
                        dest='addr',
                        help="Address")

    parser.add_argument('-n',
                        '--node',
                        dest='node',
                        help="Node")

    parser.add_argument('-r',
                        '--read',
                        action="store_true",
                        help="Read a node")

    parser.add_argument('-w',
                        '--write',
                        action="store_true",
                        help="Read a node")

    parser.add_argument('-v',
                        '--value',
                        dest='val',
                        help="Value to write")

    parser.add_argument('-reset',
                        '--reset',
                        dest='reset',
                        help="Reset, e.g. reset lpgbt, reset pattern")

    parser.add_argument('-pattern',
                        '--pattern',
                        action="store_true",
                        help="Read pattern checkers")

    parser.add_argument('-l',
                        '--loopback',
                        dest='loopback',
                        help="Loopback test")

    parser.add_argument('-s',
                        '--status',
                        action="store_true",
                        help="Status print")

    parser.add_argument('-c',
                        '--clocks',
                        action="store_true",
                        help="Print Clocks")

    parser.add_argument('-p',
                        '--print',
                        action="store_true",
                        help="Print list of registers")

    parser.add_argument('-d',
                        '--dump',
                        action="store_true",
                        help="Dump all registers")

    args = parser.parse_args()

    if (args.ipbus):
        global IPB_PATH
        IPB_PATH = args.ipbus

    if (args.xml):
        global ADR_TABLE
        ADR_TABLE = args.xml

    if (args.loopback):
        loopback_test(int(args.loopback))

    if (args.read):
        hw = setup()
        if (args.node):
            print_reg(hw, args.node, pad="")

    if (args.write):
        if (args.val and args.node):
            write_node(args.node, args.val)

    if (args.dump):
        regdump()

    # resets

    if (args.reset == "lpgbt"):
        reset_lpgbt_links()

    if (args.reset == "pattern"):
        reset_pattern_checkers()

    if (args.pattern):
        read_pattern_checkers()

    if (args.status):
        status()

    if (args.clocks):
        read_clock_frequencies()

    if (args.print):
        printregs()


def setup():

    uhal.disableLogging()
    hw = uhal.getDevice("my_device", IPB_PATH, "file://" + ADR_TABLE)
    return hw


def loopback_test(loops=100000):

    hw = setup()

    id = "LOOPBACK.LOOPBACK"
    reg = hw.getNode(id)
    for i in range(loops):
        wr = random.randint(0, 2**32)
        reg.write(wr)
        rd = reg.read()
        hw.dispatch()
        if wr != rd:
            print("ERR: %d %s wr=0x%08X rd=0x%08X" % (i, id, wr, rd))
            return
        if (i % (loops/100) == 0 and i != 0):
            print("%i reads done..." % i)


def read_clock_frequencies():
    hw = setup()
    for id in hw.getNodes(".*FW_INFO.*CLK.*_FREQ"):
        rd = read_node(id)
        freq = int(rd) / 1000000.0
        print("%s = %6.2f MHz" % (id, freq))


def status():

    hw = setup()
    print("LPGBT Link Status:")
    pad = "    "
    for id in hw.getNodes(".*LPGBT.*DAQ.*DOWNLINK.*READY"):
        print_reg(hw, hw.getNode(id), pad)
    for id in hw.getNodes(".*LPGBT.*DAQ.*UPLINK.*READY"):
        print_reg(hw, hw.getNode(id), pad)
    for id in hw.getNodes(".*LPGBT.*DAQ.*UPLINK.*FEC_ERR_CNT"):
        print_reg(hw, hw.getNode(id), pad)


def write_node(id, value):
    hw = setup()
    reg = hw.getNode(id)
    if (reg.getPermission() == uhal.NodePermission.WRITE):
        action_reg(hw, reg)
    else:
        reg.write(value)
        hw.dispatch()


def read_node(id):
    hw = setup()
    reg = hw.getNode(id)
    ret = reg.read()
    hw.dispatch()
    return ret


def printregs():

    hw = setup()

    for id in hw.getNodes():
        reg = hw.getNode(id)
        # if (reg.getModule() == ""):
        if (reg.getMode() != uhal.BlockReadWriteMode.HIERARCHICAL):
            print(format_reg(reg.getAddress(), reg.getPath()[4:], -1,
                             format_permission(reg.getPermission())))


def reset_lpgbt_links():
    hw = setup()
    for id in hw.getNodes(".*LPGBT.*LINK.*RESET"):
        print("Resetting %s" % id)
        reg = hw.getNode(id)
        action_reg(hw, reg)


def action(id):
    hw = setup()
    reg = hw.getNode(id)
    addr = reg.getAddress()
    mask = reg.getMask()
    hw.getClient().write(addr, mask)
    hw.dispatch()


def action_reg(hw, reg):
    addr = reg.getAddress()
    mask = reg.getMask()
    hw.getClient().write(addr, mask)
    hw.dispatch()


def regdump():
    hw = setup()
    for id in hw.getNodes():
        reg = hw.getNode(id)
        if (((reg.getPermission() == uhal.NodePermission.READ) or
             (reg.getPermission() == uhal.NodePermission.READWRITE)) and
            (reg.getMode() != uhal.BlockReadWriteMode.HIERARCHICAL)):
            print_reg(hw, reg, "")


def print_reg(hw, reg, pad=""):
    val = reg.read()
    id = reg.getPath()
    hw.dispatch()
    print(format_reg(reg.getAddress(), id[4:], val,
                     format_permission(reg.getPermission())))


def tab_pad(s, maxlen):
    return (s+"\t"*(int((8*maxlen-len(s)-1)/8)+1))


def format_reg(address, name, val, permission=""):
    s = ("0x%04X" % address) + ' ' + tab_pad(permission, 1) \
        + tab_pad(str(name), 8)
    if (val != -1):
        s = s + ("0x%08X" % val)
    return s


def format_permission(perm):
    if perm == uhal.NodePermission.READ:
        return "r"
    if perm == uhal.NodePermission.READWRITE:
        return "rw"
    if perm == uhal.NodePermission.WRITE:
        return "w"


def reset_pattern_checkers(rb=0):

    action("READOUT_BOARD_%i.LPGBT.PATTERN_CHECKER.RESET" % rb)

    for link in (0, 1):
        prbs_en_id = "READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_%d" % (rb, link)
        upcnt_en_id = "READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_%d" % (rb, link)
        write_node(prbs_en_id, 0)
        write_node(upcnt_en_id, 0)

        write_node(prbs_en_id, 0x00FFFFFF)
        write_node(upcnt_en_id, 0x00FFFFFF)

    action("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CNT_RESET" % rb)


def read_pattern_checkers(rb=0, quiet=False):

    for link in (0, 1):

        prbs_en = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN_%d" % (rb, link))
        upcnt_en = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN_%d" % (rb, link))

        prbs_errs = 28*[0]
        upcnt_errs = 28*[0]

        for mode in ["PRBS", "UPCNT"]:
            if quiet is False:
                print("Link " + str(link) + " " + mode + ":")
            for i in range(28):

                check = False

                if mode == "UPCNT" and ((upcnt_en >> i) & 0x1):
                    check = True
                if mode == "PRBS" and ((prbs_en >> i) & 0x1):
                    check = True

                if check:
                    write_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.SEL" % (rb), link*28+i)

                    uptime_msbs = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.TIMER_MSBS" % (rb))
                    uptime_lsbs = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.TIMER_LSBS" % (rb))

                    uptime = (uptime_msbs << 32) | uptime_lsbs

                    errs = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.%s_ERRORS" % (rb, mode))

                    if quiet is False:
                        s = "    Channel %02d %s bad frames of %s (%.0f Gb)" % (i, ("{:.2e}".format(errs)), "{:.2e}".format(uptime), uptime*8*40/1000000000.0)
                        if (errs == 0):
                            s += " (ber <%s)" % ("{:.1e}".format(1/(uptime*8)))
                            print(colors.green(s))
                        else:
                            s += " (ber>=%s)" % ("{:.1e}".format((1.0*errs)/uptime))
                            print(colors.red(s))

                    if mode == "UPCNT":
                        upcnt_errs[i] = errs
                    if mode == "PRBS":
                        prbs_errs[i] = errs

                else:
                    if mode == "UPCNT":
                        upcnt_errs[i] = 0xFFFFFFFF
                    if mode == "PRBS":
                        prbs_errs[i] = 0xFFFFFFFF

    return (prbs_errs, upcnt_errs)


def sc_reset(rb=0):
    action("READOUT_BOARD_%d.SC.TX_RESET" % rb)
    action("READOUT_BOARD_%d.SC.RX_RESET" % rb)


def sca_inj_crc(rb=0):
    action("READOUT_BOARD_%d.SC.INJ_CRC_ERR" % rb)

# def sca_wr(adr, rb=0):
# def sca_rd(adr, rb=0):
    # "READOUT_BOARD_%d.SC.RX_DATA_FROM_GBTX" % rb
    # "READOUT_BOARD_%d.SC.RX_RD" % rb
    # "READOUT_BOARD_%d.SC.TX_READY" % rb
    # "READOUT_BOARD_%d.SC.TX_CMD" % rb
    # "READOUT_BOARD_%d.SC.TX_ADDRESS" % rb
    # "READOUT_BOARD_%d.SC.TX_TRANSID" % rb
    # "READOUT_BOARD_%d.SC.TX_CHANNEL" % rb
    # "READOUT_BOARD_%d.SC.TX_DATA" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_LEN" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_ADDRESS" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_CONTROL" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_TRANSID" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_ERR" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_RECEIVED" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_CHANNEL" % rb
    # "READOUT_BOARD_%d.SC.RX.RX_DATA" % rb
    # "READOUT_BOARD_%d.SC.SCA_ENABLE" % rb
    # "READOUT_BOARD_%d.SC.START_RESET" % rb
    # "READOUT_BOARD_%d.SC.START_CONNECT" % rb
    # "READOUT_BOARD_%d.SC.START_COMMAND" % rb


def set_downlink_data_src(source, rb=0):
    id = "READOUT_BOARD_%d.LPGBT.DAQ.DOWNLINK.DL_SRC" % rb
    if (source == "etroc"):
        write_node(id, 0)
    if (source == "upcnt"):
        write_node(id, 1)
    if (source == "prbs"):
        write_node(id, 2)


def set_daq_uplink_alignment(val, link, rb=0):
    id = "READOUT_BOARD_%d.LPGBT.DAQ.UPLINK.ALIGN_%d" % (rb, link)
    write_node(id, val)

def set_trig_uplink_alignment(val, link, rb=0):
    id = "READOUT_BOARD_%d.LPGBT.TRIGGER.UPLINK.ALIGN_%d" % (rb, link)
    write_node(id, val)


def lpgbt_rd_flush(rb=0):
    i = 0
    #print("Flushing...")
    while (not read_node("READOUT_BOARD_%d.SC.RX_EMPTY" % rb)):
        action("READOUT_BOARD_%d.SC.RX_RD" % rb)
        read = read_node("READOUT_BOARD_%d.SC.RX_DATA_FROM_GBTX" % rb)
        #print("i=%d, data=0x%02x" % (i,read))
        #print("FlushLoop %d" % i)
        i= i + 1


def lpgbt_rd_adr(adr, rb=0):
    write_node("READOUT_BOARD_%d.SC.TX_GBTX_ADDR" % rb, 115)
    write_node("READOUT_BOARD_%d.SC.TX_NUM_BYTES_TO_READ" % rb, 1)
    write_node("READOUT_BOARD_%d.SC.TX_REGISTER_ADDR" % rb, adr)
    action("READOUT_BOARD_%d.SC.TX_START_READ" % rb)
    i = 0
    while (not read_node("READOUT_BOARD_%d.SC.RX_EMPTY" % rb)):
        action("READOUT_BOARD_%d.SC.RX_RD" % rb)
        read = read_node("READOUT_BOARD_%d.SC.RX_DATA_FROM_GBTX" % rb)
        #print("i=%d, data=0x%02x" % (i,read))
        if i == 6:
            return read
        i += 1
    print("lpgbt read failed!! SC RX empty")
    return 0xE9


def lpgbt_wr_adr(adr, data, rb=0):
    write_node("READOUT_BOARD_%d.SC.TX_GBTX_ADDR" % rb, 115)
    write_node("READOUT_BOARD_%d.SC.TX_REGISTER_ADDR" % rb, adr)
    write_node("READOUT_BOARD_%d.SC.TX_DATA_TO_GBTX" % rb, data)
    action("READOUT_BOARD_%d.SC.TX_WR" % rb)
    action("READOUT_BOARD_%d.SC.TX_START_WRITE" % rb)
    lpgbt_rd_flush()


def lpgbt_wr_reg(id, data, rb=0):
    node = lpgbt.get_node(id)
    lpgbt.write_reg(lpgbt_wr_adr, lpgbt_rd_adr, node, data)


def lpgbt_rd_reg(id, rb=0):
    node = lpgbt.get_node(id)
    data = lpgbt.read_reg(lpgbt_rd_adr, node)
    return data


def lpgbt_wr_node(node, data, rb=0):
    lpgbt.write_reg(lpgbt_wr_adr, lpgbt_rd_adr, node, data)


def lpgbt_rd_node(node, rb=0):
    data = lpgbt.read_reg(lpgbt_rd_adr, node)
    return data


def lpgbt_loopback(nloops=100, rb=0):
    for i in range(nloops):
        wr = random.randint(0, 255)
        lpgbt_wr_adr(1, wr)
        rd = lpgbt_rd_adr(1)
        if wr != rd:
            print("ERR: %d wr=0x%08X rd=0x%08X" % (i, wr, rd))
            return
        if (i % (nloops/100) == 0 and i != 0):
            print("%i reads done..." % i)


def set_ps0_phase(phase):
    phase = phase & 0x1ff
    msb = 0x1 & (phase >> 8)
    #print (phase)
    #print (msb)
    lpgbt_wr_reg("LPGBT.RWF.PHASE_SHIFTER.PS0ENABLEFINETUNE", 1)
    lpgbt_wr_reg("LPGBT.RWF.PHASE_SHIFTER.PS0DELAY_7TO0", 0xff & phase)
    lpgbt_wr_reg("LPGBT.RWF.PHASE_SHIFTER.PS0DELAY_8", msb)


def lpgbt_prbs_phase_scan():
    f = open("phase_scan.txt", "w")
    for phase in range(0x0, 0x1ff, 1):
        phase_ns = (50.0*(phase&0xf) + 800.0*(phase>>4))/1000
        set_ps0_phase(phase)
        reset_pattern_checkers()
        sleep(0.5)
        #read_pattern_checkers()
        prbs_errs = read_pattern_checkers(quiet=True)[0]
        s = "%f %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d" % (phase_ns, prbs_errs[0], prbs_errs[1], prbs_errs[2], prbs_errs[3], prbs_errs[4], prbs_errs[5], prbs_errs[6], prbs_errs[7], prbs_errs[8], prbs_errs[9], prbs_errs[10], prbs_errs[11], prbs_errs[12], prbs_errs[13], prbs_errs[14], prbs_errs[15], prbs_errs[16], prbs_errs[17], prbs_errs[18], prbs_errs[19], prbs_errs[20], prbs_errs[21], prbs_errs[22], prbs_errs[23])
        f.write("%s\n" % s)
        print (s)

def plot_phase_scan(fname, channel):
    data = np.loadtxt(fname, delimiter=' ')
    plt.yscale("log")
    plt.plot(data[:,0], data[:,channel])
    plt.show()


def sca_reset(rb=0):
    action("READOUT_BOARD_%d.SC.START_RESET" % rb)

def sca_connect(rb=0):
    action("READOUT_BOARD_%d.SC.START_CONNECT" % rb)

class SCA_CRB:
    ENSPI  = 0
    ENGPIO = 1
    ENI2C0 = 2
    ENI2C1 = 3
    ENI2C2 = 4
    ENI2C3 = 5
    ENI2C4 = 6

class SCA_CRC:
    ENI2C5 = 0
    ENI2C6 = 1
    ENI2C7 = 2
    ENI2C8 = 3
    ENI2C9 = 4
    ENI2CA = 5
    ENI2CB = 6
    ENI2CC = 7

class SCA_CRD:
    ENI2CD = 0
    ENI2CE = 1
    ENI2CF = 2
    ENJTAG = 3
    ENADC  = 4
    ENDAC  = 6

class SCA_CONTROL:
    CTRL_R_ID  = 0x14D1  # this is SCA V2
    CTRL_W_CRB = 0x0002
    CTRL_R_CRB = 0x0003
    CTRL_W_CRC = 0x0004
    CTRL_R_CRC = 0x0005
    CTRL_W_CRD = 0x0006
    CTRL_R_CRD = 0x0007
    CTRL_R_SEU = 0x13F1
    CTRL_C_SEU = 0x13F1

class SCA_GPIO:
    GPIO_W_DATAOUT   = 0x0210
    GPIO_R_DATAOUT   = 0x0211
    GPIO_R_DATAIN    = 0x0201
    GPIO_W_DIRECTION = 0x0220
    GPIO_R_DIRECTION = 0x0221

class SCA_JTAG:
    # JTAG COMMANDS
    JTAG_W_CTRL = 0x1380
    JTAG_R_CTRL = 0x1381
    JTAG_W_FREQ = 0x1390
    JTAG_R_FREQ = 0x1391
    JTAG_W_TDO0 = 0x1300
    JTAG_R_TDI0 = 0x1301
    JTAG_W_TDO1 = 0x1310
    JTAG_R_TDI1 = 0x1311
    JTAG_W_TDO2 = 0x1320
    JTAG_R_TDI2 = 0x1321
    JTAG_W_TDO3 = 0x1330
    JTAG_R_TDI3 = 0x1331
    JTAG_W_TMS0 = 0x1340
    JTAG_R_TMS0 = 0x1341
    JTAG_W_TMS1 = 0x1350
    JTAG_R_TMS1 = 0x1351
    JTAG_W_TMS2 = 0x1360
    JTAG_R_TMS2 = 0x1361
    JTAG_W_TMS3 = 0x1370
    JTAG_R_TMS3 = 0x1371
    JTAG_ARESET = 0x13C0
    JTAG_GO     = 0x13A2
    JTAG_GO_M   = 0x13B0


def sca_rw_reg(reg, data=0x0, adr=0x00, transid=0x00, rb=0):

    cmd = reg & 0xFF
    channel = (reg >> 8) & 0xFF

    return sca_rw_cmd(cmd, channel, data, adr, transid, rb)


def sca_rw_cmd(cmd, channel, data, adr=0x0, transid=0x00, rb=0):

    """
    adr = chip address (0x0 by default)
    """

    if transid == 0:
        transid = random.randint(0, 2**8-1)

    # request packet structure
    # sof
    # address : destination packet address (chip id)
    # control : connect/sabm, reset, test
    # {
    #  transid
    #  channel
    #  length
    #  command
    #  data[31:0]
    # }
    # fcs
    # eof

    write_node("READOUT_BOARD_%d.SC.TX_CHANNEL" % rb, channel)
    write_node("READOUT_BOARD_%d.SC.TX_CMD" % rb, cmd)
    write_node("READOUT_BOARD_%d.SC.TX_ADDRESS" % rb, adr)

    write_node("READOUT_BOARD_%d.SC.TX_TRANSID" % rb, transid)

    write_node("READOUT_BOARD_%d.SC.TX_DATA" % rb, data)
    action("READOUT_BOARD_%d.SC.START_COMMAND" % rb)

    # reply packet structure
    # sof
    # address
    # control
    # {
    #  transid
    #  channel
    #  error
    #  length
    #  data
    # }
    # fcs
    # eof

    # TODO: read reply
    err = read_node("READOUT_BOARD_%d.SC.RX.RX_ERR" % rb)  # 8 bit
    if err > 0:
        if (err & 0x1):
            print("SCA Read Error :: Generic Error Flag")
        if (err & 0x2):
            print("SCA Read Error :: Invalid Channel Request")
        if (err & 0x4):
            print("SCA Read Error :: Invalid Command Request")
        if (err & 0x8):
            print("SCA Read Error :: Invalid Transaction Number Request")
        if (err & 0x10):
            print("SCA Read Error :: Invalid Length")
        if (err & 0x20):
            print("SCA Read Error :: Channel Not Enabled")
        if (err & 0x40):
            print("SCA Read Error :: Command In Treatment")

    if transid != read_node("READOUT_BOARD_%d.SC.RX.RX_TRANSID" % rb):
        print("SCA Read Error :: Transaction ID Does Not Match")


    return(read_node("READOUT_BOARD_%d.SC.RX.RX_DATA" % rb))  # 32 bit read data

    read_node("READOUT_BOARD_%d.SC.RX.RX_RECEIVED" % rb)  # flag pulse
    read_node("READOUT_BOARD_%d.SC.RX.RX_CHANNEL" % rb)  # channel reply
    read_node("READOUT_BOARD_%d.SC.RX.RX_LEN" % rb)
    read_node("READOUT_BOARD_%d.SC.RX.RX_ADDRESS" % rb)
    read_node("READOUT_BOARD_%d.SC.RX.RX_CONTROL" % rb)


def sca_setup():

    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRXECTERM", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRXECENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRXECACBIAS", 0)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRXECINVERT", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRXECPHASESELECT", 8)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRXECTRACKMODE", 2)

    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTXECINVERT", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTXECENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTXECDRIVESTRENGTH", 4)

    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK28FREQ", 1)  # 1 =  40mhz
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK28INVERT", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK28DRIVESTRENGTH", 4)


def lpgbt_configure_clocks(en_mask, invert_mask=0, rb=0):
    for i in range(27):
        if 0x1 & (en_mask >> i):
            lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK%dFREQ" % i, 1)
        if 0x1 & (invert_mask >> i):
            lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK%dINVERT" % i, 1)


def sca_enable(state=1, rb=0):
    write_node("READOUT_BOARD_%d.SC.SCA_ENABLE" % rb, state)


def sca_inject_crc(rb=0):
    action("READOUT_BOARD_%d.SC.INJ_CRC_ERR" % rb)


def lpgbt_init():
    # invert high speed data output
    lpgbt_wr_adr(0x36, 0x80)  # "LPGBT.RWF.CHIPCONFIG.HIGHSPEEDDATAOUTINVERT"

    # turn on clock outputs
    lpgbt_configure_clocks(0x0fc0081f, 0x0)

    # setup up sca eptx/rx
    sca_setup()

    #lpgbt_configure_eptx()
    #lpgbt_configure_eprx()


def sca_hard_reset():
    bit = 0
    set_gpio(bit, 0)
    set_gpio(bit, 1)


def ld_disable():
    bit = 13
    set_gpio(bit, 1)


def ld_enable():
    bit = 13
    set_gpio(bit, 0)


def ld_reset():
    bit = 10
    set_gpio(bit, 0)
    set_gpio(bit, 1)


def set_gpio(ch, val, default=0x401):

    if (ch > 7):
        rd = default >> 8
        node = "LPGBT.RWF.PIO.PIOOUTH"
        ch = ch - 8
    else:
        node = "LPGBT.RWF.PIO.PIOOUTL"
        rd = default & 0xff

    if val == 0:
        rd = rd & (0xff ^ (1 << ch))
    else:
        rd = rd | (1 << ch)

    reg = lpgbt.get_node(node)
    adr = reg.address
    lpgbt_wr_adr(adr, rd)


def configure_gpio_outputs(outputs=0x2401, defaults=0x0401):
    lpgbt_wr_adr(0x52, outputs >> 8)
    lpgbt_wr_adr(0x53, outputs & 0xFF)
    lpgbt_wr_adr(0x54, defaults >> 8)
    lpgbt_wr_adr(0x55, defaults & 0xFF)


def init_adc():
    lpgbt_wr_reg("LPGBT.RW.ADC.ADCENABLE", 0x1)  # enable ADC
    lpgbt_wr_reg("LPGBT.RW.ADC.TEMPSENSRESET", 0x1)  # resets temp sensor
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDMONENA", 0x1)  # enable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDTXMONENA", 0x1)  # enable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDRXMONENA", 0x1)  # enable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDPSTMONENA", 0x1,)  # enable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDANMONENA", 0x1)  # enable dividers
    lpgbt_wr_reg("LPGBT.RWF.CALIBRATION.VREFENABLE", 0x1)  # vref enable
    lpgbt_wr_reg("LPGBT.RWF.CALIBRATION.VREFTUNE", 0x63)


def powerdown_adc():
    lpgbt_wr_reg("LPGBT.RW.ADC.ADCENABLE", 0x0)  # disable ADC
    lpgbt_wr_reg("LPGBT.RW.ADC.TEMPSENSRESET", 0x0)  # disable temp sensor
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDMONENA", 0x0)  # disable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDTXMONENA", 0x0)  # disable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDRXMONENA", 0x0)  # disable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDPSTMONENA", 0x0)  # disable dividers
    lpgbt_wr_reg("LPGBT.RW.ADC.VDDANMONENA", 0x0)  # disable dividers
    lpgbt_wr_reg("LPGBT.RWF.CALIBRATION.VREFENABLE", 0x0)  # vref disable


def lpgbt_read_adcs():
    init_adc()
    print("ADC Readings:")
    for i in range(16):
        name = ""
        conv = 0
        if (i==0 ): conv=1;      name="VTRX TH1"
        if (i==1 ): conv=1/0.55; name="1V4D * 0.55"
        if (i==2 ): conv=1/0.55; name="1V5A * 0.55"
        if (i==3 ): conv=1/0.33; name="2V5TX * 0.33"
        if (i==4 ): conv=1;      name="RSSI"
        if (i==5 ): conv=1;      name="N/A"
        if (i==6 ): conv=1/0.33; name="2V5RX * 0.33"
        if (i==7 ): conv=1;      name="RT1"
        if (i==8 ): conv=1;      name="EOM DAC (internal signal)"
        if (i==9 ): conv=1/0.42; name="VDDIO * 0.42 (internal signal)"
        if (i==10): conv=1/0.42; name="VDDTX * 0.42 (internal signal)"
        if (i==11): conv=1/0.42; name="VDDRX * 0.42 (internal signal)"
        if (i==12): conv=1/0.42; name="VDD * 0.42 (internal signal)"
        if (i==13): conv=1/0.42; name="VDDA * 0.42 (internal signal)"
        if (i==14): conv=1;      name="Temperature sensor (internal signal)"
        if (i==15): conv=1/0.50; name="VREF/2 (internal signal)"

        read = read_adc(i)
        print("\tch %X: 0x%03X = %f, reading = %f (%s)" % (i, read, read/1024., conv*read/1024., name))

def read_adc(channel):
    # ADCInPSelect[3:0]  |  Input
    # ------------------ |----------------------------------------
    # 4'd0               |  ADC0 (external pin)
    # 4'd1               |  ADC1 (external pin)
    # 4'd2               |  ADC2 (external pin)
    # 4'd3               |  ADC3 (external pin)
    # 4'd4               |  ADC4 (external pin)
    # 4'd5               |  ADC5 (external pin)
    # 4'd6               |  ADC6 (external pin)
    # 4'd7               |  ADC7 (external pin)
    # 4'd8               |  EOM DAC (internal signal)
    # 4'd9               |  VDDIO * 0.42 (internal signal)
    # 4'd10              |  VDDTX * 0.42 (internal signal)
    # 4'd11              |  VDDRX * 0.42 (internal signal)
    # 4'd12              |  VDD * 0.42 (internal signal)
    # 4'd13              |  VDDA * 0.42 (internal signal)
    # 4'd14              |  Temperature sensor (internal signal)
    # 4'd15              |  VREF/2 (internal signal)

    # "LPGBT.RW.ADC.ADCINPSELECT"
    # "LPGBT.RW.ADC.ADCINNSELECT"
    lpgbt_wr_reg("LPGBT.RW.ADC.ADCINPSELECT", channel)
    lpgbt_wr_reg("LPGBT.RW.ADC.ADCINNSELECT", 0xf)

    # "LPGBT.RW.ADC.ADCGAINSELECT"
    # "LPGBT.RW.ADC.ADCCONVERT"
    lpgbt_wr_reg("LPGBT.RW.ADC.ADCCONVERT", 0x1)
    lpgbt_wr_reg("LPGBT.RW.ADC.ADCENABLE", 0x1)

    # TODO: fixthis
    #done = 0
    #while (done==0):
        #done = 0x1 & (mpeek(0x1b8) >> 6) # "LPGBT.RO.ADC.ADCDONE"

    val = lpgbt_rd_reg("LPGBT.RO.ADC.ADCVALUEL")
    val |= lpgbt_rd_reg("LPGBT.RO.ADC.ADCVALUEH") << 8

    lpgbt_wr_reg("LPGBT.RW.ADC.ADCCONVERT", 0x0)
    lpgbt_wr_reg("LPGBT.RW.ADC.ADCENABLE", 0x1)

    return val

def config_eport_dlls():
    print ("Configuring eport dlls...")
    #2.2.2. Uplink: ePort Inputs DLL's
    #[0x034] EPRXDllConfig
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.EPRXDLLCURRENT", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.EPRXDLLCONFIRMCOUNT", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.EPRXDLLFSMCLKALWAYSON", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.EPRXDLLCOARSELOCKDETECTION", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.EPRXENABLEREINIT", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.EPRXDATAGATINGENABLE", 0x1)


def config_eprx():
    print ("Configuring elink inputs...")
    # Enable Elink-inputs

    #set banks to 320 Mbps
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX0DATARATE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX1DATARATE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX2DATARATE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX3DATARATE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX4DATARATE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX5DATARATE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX6DATARATE", 1)

    #set banks to fixed phase
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX0TRACKMODE", 0)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX1TRACKMODE", 0)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX2TRACKMODE", 0)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX3TRACKMODE", 0)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX4TRACKMODE", 0)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX5TRACKMODE", 0)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX6TRACKMODE", 0)

    #enable inputs
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX00ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX01ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX02ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX03ENABLE", 1)

    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX10ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX11ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX12ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX13ENABLE", 1)

    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX20ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX21ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX22ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX23ENABLE", 1)

    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX30ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX31ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX32ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX33ENABLE", 1)

    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX40ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX41ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX42ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX43ENABLE", 1)

    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX50ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX51ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX52ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX53ENABLE", 1)

    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX60ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX61ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX62ENABLE", 1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX63ENABLE", 1)

    #enable 100 ohm termination
    for i in range (28):
        lpgbt_wr_reg("LPGBT.RWF.EPORTRX.EPRX_CHN_CONTROL.EPRX%dTERM" % i, 1)

def configure_eptx():
    #[0x0a7] EPTXDataRate
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX0DATARATE", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX1DATARATE", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX2DATARATE", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX3DATARATE", 0x3)

    #EPTXxxEnable
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX12ENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX10ENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX20ENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX00ENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX23ENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX02ENABLE", 0x1)

    #EPTXxxDriveStrength
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX_CHN_CONTROL.EPTX6DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX_CHN_CONTROL.EPTX4DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX_CHN_CONTROL.EPTX8DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX_CHN_CONTROL.EPTX0DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX_CHN_CONTROL.EPTX11DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX_CHN_CONTROL.EPTX2DRIVESTRENGTH", 0x3)

    # enable mirror feature
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX0MIRRORENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX1MIRRORENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX2MIRRORENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EPORTTX.EPTX3MIRRORENABLE", 0x1)

    #turn on 320 MHz clocks
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK3FREQ",  0x4)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK5FREQ",  0x4)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK6FREQ",  0x4)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK7FREQ",  0x4)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK15FREQ", 0x4)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK16FREQ", 0x4)

    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK3DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK5DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK6DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK7DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK15DRIVESTRENGTH", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.EPORTCLK.EPCLK16DRIVESTRENGTH", 0x3)


def config_lpgbt():
    print ("Configuring Clock Generator, Line Drivers, Power Good for CERN configuration...")

    # Configure ClockGen Block:
    # [0x01f] EPRXLOCKFILTER
    lpgbt_wr_reg("LPGBT.RWF.CALIBRATION.EPRXLOCKTHRESHOLD", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.CALIBRATION.EPRXRELOCKTHRESHOLD", 0x5)

    # [0x020] CLKGConfig0
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCALIBRATIONENDOFCOUNT", 0xC)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGBIASGENCONFIG", 0x8)

    # [0x021] CLKGConfig1
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCONTROLOVERRIDEENABLE", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGDISABLEFRAMEALIGNERLOCKCONTROL", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCDRRES", 0x1 )
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGVCORAILMODE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGVCODAC", 0x8)

    # [0x022] CLKGPllRes
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGPLLRESWHENLOCKED", 0x4)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGPLLRES", 0x4)

    #[0x023] CLKGPLLIntCur
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGPLLINTCURWHENLOCKED", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGPLLINTCUR", 0x5)

    #[0x024] CLKGPLLPropCur
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGPLLPROPCURWHENLOCKED", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGPLLPROPCUR", 0x5)

    #[0x025] CLKGCDRPropCur
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCDRPROPCURWHENLOCKED", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCDRPROPCUR", 0x5)

    #[0x026] CLKGCDRIntCur
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCDRINTCURWHENLOCKED", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCDRINTCUR", 0x5)

    #[0x027] CLKGCDRFFPropCur
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCDRFEEDFORWARDPROPCURWHENLOCKED", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCDRFEEDFORWARDPROPCUR", 0x5)

    #[0x028] CLKGFLLIntCur
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGFLLINTCURWHENLOCKED", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGFLLINTCUR", 0x5)

    #[0x029] CLKGFFCAP
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCOCONNECTCDR", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCAPBANKOVERRIDEENABLE", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGFEEDFORWARDCAPWHENLOCKED", 0x3)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGFEEDFORWARDCAP", 0x3)

    #[0x02a] CLKGCntOverride
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCOOVERRIDEVC", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCOREFCLKSEL", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCOENABLEPLL", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCOENABLEFD", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCOENABLECDR", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCODISDATACOUNTERREF", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCODISDESVBIASGEN", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CDRCOCONNECTPLL", 0x0)

    #[0x02b] CLKGOverrideCapBank
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCAPBANKSELECT_7TO0", 0x00)

    #[0x02c] CLKGWaitTime
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGWAITCDRTIME", 0x8)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGWAITPLLTIME", 0x8)

    #[0x02d] CLKGLFCONFIG0
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGLOCKFILTERENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGCAPBANKSELECT_8", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGLOCKFILTERLOCKTHRCOUNTER", 0x9)

    #[0x02e] CLKGLFConfig1
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGLOCKFILTERRELOCKTHRCOUNTER", 0x9)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.CLKGLOCKFILTERUNLOCKTHRCOUNTER", 0x9)

    #[0x033] PSDllConfig
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.EPRXUNLOCKTHRESHOLD", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.PSDLLCONFIRMCOUNT", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.CLOCKGENERATOR.PSDLLCURRENTSEL", 0x1)

    # [0x039] Set H.S. Uplink Driver current:
    lpgbt_wr_reg("LPGBT.RWF.LINE_DRIVER.LDEMPHASISENABLE", 0x0)
    lpgbt_wr_reg("LPGBT.RWF.LINE_DRIVER.LDMODULATIONCURRENT", 0x20)

    # [0x03b] REFCLK
    lpgbt_wr_reg("LPGBT.RWF.LINE_DRIVER.REFCLKTERM", 0x1)

    # Enable PowerGood @ 1.0 V, Delay 100 ms:
    lpgbt_wr_reg("LPGBT.RWF.POWER_GOOD.PGENABLE", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.POWER_GOOD.PGLEVEL", 0x5)
    lpgbt_wr_reg("LPGBT.RWF.POWER_GOOD.PGDELAY", 0xC)

    # Datapath configuration
    lpgbt_wr_reg("LPGBT.RW.DEBUG.DLDPBYPASDEINTERLEVEAR", 0x0)
    lpgbt_wr_reg("LPGBT.RW.DEBUG.DLDPBYPASFECDECODER", 0x0)
    lpgbt_wr_reg("LPGBT.RW.DEBUG.DLDPBYPASSDESCRAMBLER", 0x0)
    lpgbt_wr_reg("LPGBT.RW.DEBUG.DLDPFECERRCNTENA", 0x1)
    lpgbt_wr_reg("LPGBT.RW.DEBUG.ULDPBYPASSINTERLEAVER", 0x0)
    lpgbt_wr_reg("LPGBT.RW.DEBUG.ULDPBYPASSSCRAMBLER", 0x0)
    lpgbt_wr_reg("LPGBT.RW.DEBUG.ULDPBYPASSFECCODER", 0x0)


def lpgbt_eyescan(count=7):

    lpgbt_wr_reg("LPGBT.RW.EOM.EOMENDOFCOUNTSEL", count)
    lpgbt_wr_reg("LPGBT.RW.EOM.EOMENABLE", 1)

    # Equalizer settings
    lpgbt_wr_reg("LPGBT.RWF.EQUALIZER.EQCAP", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EQUALIZER.EQRES0", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EQUALIZER.EQRES1", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EQUALIZER.EQRES2", 0x1)
    lpgbt_wr_reg("LPGBT.RWF.EQUALIZER.EQRES3", 0x1)

    #eyeimage = [[0 for y in range(32)] for x in range(64)]
    eyeimage = [[0 for y in range(31)] for x in range(64)]

    node = lpgbt.get_node(id)
    #cntvalregh    = lpgbt.get_node("LPGBT.RO.EOM.EOMCOUNTER40MH")
    #cntvalregl    = lpgbt.get_node("LPGBT.RO.EOM.EOMCOUNTER40ML")
    datavalregh    = lpgbt.get_node("LPGBT.RO.EOM.EOMCOUNTERVALUEH")
    datavalregl    = lpgbt.get_node("LPGBT.RO.EOM.EOMCOUNTERVALUEL")
    eomphaseselreg = lpgbt.get_node("LPGBT.RW.EOM.EOMPHASESEL")
    eomstartreg    = lpgbt.get_node("LPGBT.RW.EOM.EOMSTART")
    eomstatereg    = lpgbt.get_node("LPGBT.RO.EOM.EOMSMSTATE")
    eombusyreg     = lpgbt.get_node("LPGBT.RO.EOM.EOMBUSY")
    eomendreg      = lpgbt.get_node("LPGBT.RO.EOM.EOMEND")
    eomvofsel      = lpgbt.get_node("LPGBT.RW.EOM.EOMVOFSEL")

    cntvalmax = 0
    cntvalmin = 2**20

    #ymin=1
    #ymax=30
    ymin=0
    ymax=31
    xmin=0
    xmax=64

    print ("Starting loops: \n")
    for y_axis in range(ymin, ymax):
        # update yaxis
        lpgbt_wr_node(eomvofsel, y_axis, 0)

        for x_axis in range (xmin,xmax):
            if (x_axis >= 32):
                x_axis_wr = 63-(x_axis-32)
            else:
                x_axis_wr = x_axis

            # update xaxis
            lpgbt_wr_node(eomphaseselreg, x_axis_wr, 0)

            # wait few miliseconds
            sleep(0.005)

            # start measurement
            lpgbt_wr_node(eomstartreg, 0x1, 0)

            # wait until measurement is finished
            # FIXME: fixthis wtf...
            busy = 1
            end = 0
            while (busy and not end):
                busy = 0
                end = 1

            countervalue = (lpgbt_rd_node(datavalregh)) << 8 |lpgbt_rd_node(datavalregl)
            if (countervalue > cntvalmax):
                cntvalmax = countervalue
            if (countervalue < cntvalmin):
                cntvalmin = countervalue
            eyeimage[x_axis][y_axis] = countervalue

            # deassert eomstart bit
            lpgbt_wr_node(eomstartreg, 0x0, 0)

            #if (countervalue/1000 > 3.0):
            #    sys.stdout.write("-")
            #else:
            #    sys.stdout.write("x")
            sys.stdout.write("%01d" % int(eyeimage[x_axis][y_axis]/1000))
            #sys.stdout.write("%x" % (eyeimage[x_axis][y_axis]))
            #print(eyeimage[x_axis][y_axis])
            sys.stdout.flush()

        sys.stdout.write("\n")
        #percent_done = 100. * (y_axis*64. +64. ) / (32.*64.)
        #print ("%f percent done" % percent_done)
    print ("\nEnd Loops \n")

    print ("Counter value max=%d" % cntvalmax)
    if not os.path.isdir("eye_scan_results"):
        os.mkdir("eye_scan_results")
    f = open ("eye_scan_results/eye_data.py", "w+")
    f.write ("eye_data=[\n")
    for y  in range (ymin,ymax):
        f.write ("    [")
        for x in range (xmin,xmax):
            # normalize for plotting
            f.write("%d" % (100*(cntvalmax - eyeimage[x][y])/(cntvalmax-cntvalmin)))
            if (x<(xmax-1)):
                f.write(",")
            else:
                f.write("]")
        if (y<(ymax-1)):
            f.write(",\n")
        else:
            f.write("]\n")

def check_rom_readback():
    romreg=lpgbt_rd_reg("LPGBT.RO.ROMREG")
    if (romreg != 0xA5):
        print ("ERROR: no communication with LPGBT. ROMREG=0x%x, EXPECT=0x%x" % (romreg, 0xA5))
    else:
        print ("Testing communication with LGPBT IC... ok")

def set_uplink_group_data_source(type, pattern=0x55555555):
    setting = 0
    if (type == "normal"):
        setting = 0
    elif(type == "prbs7"):
        setting = 1
    elif(type == "cntup"):
        setting = 2
    elif(type == "cntdown"):
        setting = 3
    elif(type == "pattern"):
        setting = 4
    elif(type == "invpattern"):
        setting = 5
    elif(type == "loopback"):
        setting = 6
    else:
        print("Setting invalid in set_uplink_group_data_source")
        return

    lpgbt_wr_reg("LPGBT.RW.TESTING.ULG0DATASOURCE", setting)
    lpgbt_wr_reg("LPGBT.RW.TESTING.ULG1DATASOURCE", setting)
    lpgbt_wr_reg("LPGBT.RW.TESTING.ULG2DATASOURCE", setting)
    lpgbt_wr_reg("LPGBT.RW.TESTING.ULG3DATASOURCE", setting)
    lpgbt_wr_reg("LPGBT.RW.TESTING.ULG4DATASOURCE", setting)
    lpgbt_wr_reg("LPGBT.RW.TESTING.ULG5DATASOURCE", setting)
    lpgbt_wr_reg("LPGBT.RW.TESTING.ULG6DATASOURCE", setting)

    if (setting == 4 or setting == 5):
        lpgbt_wr_reg("LPGBT.RW.TESTING.DPDATAPATTERN0", 0xff & (pattern >> 0))
        lpgbt_wr_reg("LPGBT.RW.TESTING.DPDATAPATTERN1", 0xff & (pattern >> 8))
        lpgbt_wr_reg("LPGBT.RW.TESTING.DPDATAPATTERN2", 0xff & (pattern >> 16))
        lpgbt_wr_reg("LPGBT.RW.TESTING.DPDATAPATTERN3", 0xff & (pattern >> 24))


def lpgbt_program_from_file(filename, rb=0):
    f = open(filename, "r")
    for line in f:
        adr, data = line.split(" ")
        lpgbt_wr_adr(adr, data)

def configure_sca_control_registers(en_spi=0, en_gpio=0, en_i2c=0, en_adc=0, en_dac=0, rb=0):

    ENI2C0  = (en_i2c >> 0) & 0x1
    ENI2C1  = (en_i2c >> 1) & 0x1
    ENI2C2  = (en_i2c >> 2) & 0x1
    ENI2C3  = (en_i2c >> 3) & 0x1
    ENI2C4  = (en_i2c >> 4) & 0x1
    ENI2C5  = (en_i2c >> 5) & 0x1
    ENI2C6  = (en_i2c >> 6) & 0x1
    ENI2C7  = (en_i2c >> 7) & 0x1
    ENI2C8  = (en_i2c >> 8) & 0x1
    ENI2C9  = (en_i2c >> 9) & 0x1
    ENI2CA  = (en_i2c >> 10) & 0x1
    ENI2CB  = (en_i2c >> 11) & 0x1
    ENI2CC  = (en_i2c >> 12) & 0x1
    ENI2CD  = (en_i2c >> 13) & 0x1
    ENI2CE  = (en_i2c >> 14) & 0x1
    ENI2CF  = (en_i2c >> 15) & 0x1

    crb = 0
    crb |= en_spi << SCA_CRB.ENSPI
    crb |= en_gpio << SCA_CRB.ENGPIO
    crb |= ENI2C0 << SCA_CRB.ENI2C0
    crb |= ENI2C1 << SCA_CRB.ENI2C1
    crb |= ENI2C2 << SCA_CRB.ENI2C2
    crb |= ENI2C3 << SCA_CRB.ENI2C3
    crb |= ENI2C4 << SCA_CRB.ENI2C4

    crc = 0
    crc |= ENI2C5 << SCA_CRC.ENI2C5
    crc |= ENI2C6 << SCA_CRC.ENI2C6
    crc |= ENI2C7 << SCA_CRC.ENI2C7
    crc |= ENI2C8 << SCA_CRC.ENI2C8
    crc |= ENI2C9 << SCA_CRC.ENI2C9
    crc |= ENI2CA << SCA_CRC.ENI2CA
    crc |= ENI2CB << SCA_CRC.ENI2CB
    crc |= ENI2CC << SCA_CRC.ENI2CC

    crd = 0
    crd |= ENI2CD << SCA_CRD.ENI2CD
    crd |= ENI2CE << SCA_CRD.ENI2CE
    crd |= ENI2CF << SCA_CRD.ENI2CF
    crd |= en_adc << SCA_CRD.ENADC
    crd |= en_dac << SCA_CRD.ENDAC

    sca_rw_reg(SCA_CONTROL.CTRL_W_CRB, crb << 24)
    sca_rw_reg(SCA_CONTROL.CTRL_W_CRC, crc << 24)
    sca_rw_reg(SCA_CONTROL.CTRL_W_CRD, crd << 24)

    crb_rd = sca_rw_reg(SCA_CONTROL.CTRL_R_CRB) >> 24
    crc_rd = sca_rw_reg(SCA_CONTROL.CTRL_R_CRC) >> 24
    crd_rd = sca_rw_reg(SCA_CONTROL.CTRL_R_CRD) >> 24

    if (crb != crb_rd or crc != crc_rd or crd != crd_rd):
        print("SCA Control Register Readback Error, Not configured Correctly")
        print("CRB wr=%02X, rd=%02X" % (crb, crb_rd))
        print("CRC wr=%02X, rd=%02X" % (crc, crc_rd))
        print("CRD wr=%02X, rd=%02X" % (crd, crd_rd))


if __name__ == '__main__':

    # use 2 for loopback, 0 for internal data ggenerator
    #for i in range(28):
    #    set_uplink_alignment(0, i)

    lpgbt.parse_xml()

    configure_gpio_outputs()
    lpgbt_init()
    #config_lpgbt()
    config_eport_dlls()

    sca_hard_reset()
    sca_setup()
    sca_reset()
    sca_connect()

    action("READOUT_BOARD_%d.SC.TX_RESET" % 0)
    action("READOUT_BOARD_%d.SC.RX_RESET" % 0)

    configure_sca_control_registers(en_adc=1, en_gpio=1)

    print(hex(sca_rw_reg(SCA_CONTROL.CTRL_R_ID)))
    #print(hex(sca_rw_reg(SCA_JTAG.JTAG_R_CTRL)))

    lpgbt_eyescan(count=7)
    #lpgbt_loopback()
    check_rom_readback()
    main()
    # for i in range(28):
    #    set_uplink_alignment(0, i)

    #set_downlink_data_src("prbs")

    #ld_disable()

    #configure_gpio_outputs()
    #ld_enable()

    #lpgbt_prbs_phase_scan()
    #plot_phase_scan("phase_scan.txt", 1)
    #set_ps0_phase(0x1ff)
    #lpgbt_wr_adr(0x0, 0xaa)
    #lpgbt_wr_adr(0x1, 0xbb)
    #lpgbt_wr_adr(0x2, 0xcc)
    #lpgbt_wr_adr(0x3, 0xdd)
    #print(hex(lpgbt_rd_adr(0x0)))
    #print(hex(lpgbt_rd_adr(0x1)))
    #print(hex(lpgbt_rd_adr(0x2)))
    #print(hex(lpgbt_rd_adr(0x3)))
    #print(hex(lpgbt_rd_adr(0x00)))
    #print(hex(lpgbt_rd_adr(0x01)))
    #lpgbt_wr_adr(0x2, 0xcc)
    #print(hex(lpgbt_rd_adr(0x01)))
    #lpgbt_wr_adr(0x3, 0xdd)
    #print(hex(lpgbt_rd_adr(0x01)))

    #lpgbt_wr_adr(0x5d, 0x0)
    #lpgbt_rd_flush()
    #print(hex(lpgbt_rd_adr(0x5d)))
    #lpgbt_rd_flush()
    #print(hex(lpgbt_rd_reg("LPGBT.RWF.PHASE_SHIFTER.PS0DELAY_7TO0")))
    #lpgbt_wr_reg("LPGBT.RWF.PHASE_SHIFTER.PS0DELAY_7TO0", 0xbb)
    #print(hex(lpgbt_rd_adr(0x5D)))
    #print(hex(lpgbt_rd_reg("LPGBT.RWF.PHASE_SHIFTER.PS0DELAY_7TO0")))
    #lpgbt_loopback(nloops=1000, rb=0)

