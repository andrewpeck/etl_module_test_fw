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

import random  # For randint
import uhal
import argparse
import reg_parser as lpgbt
import colors
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

    prbs_en_id = "READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN" % rb
    upcnt_en_id = "READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN" % rb
    write_node(prbs_en_id, 0)
    write_node(upcnt_en_id, 0)

    write_node(prbs_en_id, 0x00FFFFFF)
    write_node(upcnt_en_id, 0x00FFFFFF)

    action("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CNT_RESET" % rb)


def read_pattern_checkers(rb=0, quiet=False):

    prbs_en = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN" % rb)
    upcnt_en = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN" % rb)

    prbs_errs = 28*[0]
    upcnt_errs = 28*[0]

    for mode in ["PRBS", "UPCNT"]:
        if quiet is False:
            print(mode + ":")
        for i in range(28):

            check = False

            if mode == "UPCNT" and ((upcnt_en >> i) & 0x1):
                check = True
            if mode == "PRBS" and ((prbs_en >> i) & 0x1):
                check = True

            if check:
                write_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.SEL" % (rb), i)

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


def set_uplink_alignment(val, link, rb=0):
    id = "READOUT_BOARD_%d.LPGBT.DAQ.UPLINK.ALIGN_%d" % (rb, link)
    write_node(id, val)


def lpgbt_rd_adr(adr, rb=0):
    write_node("READOUT_BOARD_%d.SC.TX_GBTX_ADDR" % rb, 115)
    write_node("READOUT_BOARD_%d.SC.TX_NUM_BYTES_TO_READ" % rb, 1)
    write_node("READOUT_BOARD_%d.SC.TX_REGISTER_ADDR" % rb, adr)
    action("READOUT_BOARD_%d.SC.TX_START_READ" % rb)
    empty = read_node("READOUT_BOARD_%d.SC.RX_EMPTY" % rb)
    if empty:
        print("RX Fifo empty")
        read = "0xDD"
    else:
        #action("READOUT_BOARD_%d.SC.RX_RD" % rb)
        lpgbt_rd_flush()
        read = read_node("READOUT_BOARD_%d.SC.RX_DATA_FROM_GBTX" % rb)
        return read

def lpgbt_rd_flush(rb=0):
    #i = 0
    while (not read_node("READOUT_BOARD_%d.SC.RX_EMPTY" % rb)):
        action("READOUT_BOARD_%d.SC.RX_RD" % rb)
        #print("FlushLoop %d" % i)
        #i= i + 1


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
    action("READOUT_BOARD_%d.SC.RX_RD" % 0)


def lpgbt_rd_reg(id, rb=0):
    node = lpgbt.get_node(id)
    data = lpgbt.read_reg(lpgbt_rd_adr, node)
    return data


def lpgbt_loopback(nloops=100, rb=0):
    for i in range(nloops):
        wr = random.randint(0, 255)
        lpgbt_wr_adr (0, wr)
        rd = lpgbt_rd_adr (0)
        if wr != rd:
            print("ERR: %d wr=0x%08X rd=0x%08X" % (i, wr, rd))
            return
        if (i % (nloops/100) == 0 and i != 0):
            print("%i reads done..." % i)


if __name__ == '__main__':

    # use 2 for loopback, 0 for internal data generator
    for i in range(28):
        set_uplink_alignment(0, i)
    # for i in range(28):
    #    set_uplink_alignment(0, i)

    set_downlink_data_src("prbs")

    lpgbt.parse_xml()

    #lpgbt_loopback(nloops=1000, rb=0)

    main()
