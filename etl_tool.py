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

import time
import random # For randint
import sys # For sys.argv and sys.exit
import uhal
import argparse

IPB_PATH = "ipbusudp-2.0://192.168.0.10:50001"
ADR_TABLE = "address_tables/etl_test_fw.xml"

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
                       help="Reset")

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


    parser.add_argument('-p',
                        '--print',
                        action="store_true",
                        help="Print list of registers")

    parser.add_argument('-d',
                        '--dump',
                        action="store_true",
                        help="Dump test")


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
            print_reg (hw, args.node, pad="")

    if (args.write):
        if (args.val and args.node):
            write_node(args.node,args.val)

    if (args.dump):
        regdump()

    # resets

    if (args.reset=="lpgbt"):
        reset_lpgbt_links()

    if (args.reset=="pattern"):
        reset_pattern_checkers()

    if (args.pattern):
        read_pattern_checkers()

    if (args.status):
        status()

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
        wr = random.randint(0,2**32)
        reg.write(wr)
        rd = reg.read();
        hw.dispatch();
        if (wr != rd):
            print("ERR: %d %s wr=0x%08X rd=0x%08X" % (i, id, wr, rd))
            return
        if (i % (loops/100) == 0 and i!=0):
            print("%i reads done..." % i)

def status():

    hw=setup()
    print("LPGBT Link Status:")
    pad = "    "
    for id in hw.getNodes(".*LPGBT.*DAQ.*DOWNLINK.*READY"):
        print_reg(hw,id,pad)
    for id in hw.getNodes(".*LPGBT.*DAQ.*UPLINK.*READY"):
        print_reg(hw,id,pad)
    for id in hw.getNodes(".*LPGBT.*DAQ.*UPLINK.*FEC_ERR_CNT"):
        print_reg(hw,id,pad)

def write_node(id, value):
    hw = setup()
    reg = hw.getNode(id)
    if (reg.getPermission() == uhal.NodePermission.WRITE):
        action(hw,reg)
    else:
        reg.write(value)
        hw.dispatch();

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
        #if (reg.getModule() == ""):
        if (reg.getMode() != uhal.BlockReadWriteMode.HIERARCHICAL):
            print(format_reg (reg.getAddress(), reg.getPath()[4:], -1, format_permission(reg.getPermission())))

def reset_lpgbt_links():

    hw = setup()

    for id in hw.getNodes(".*LPGBT.*LINK.*RESET"):
        print("Resetting %s" % id)
        reg = hw.getNode(id)
        print(str(reg.getPermission()))
        action(hw,reg)
        #hw.dispatch();

def action(hw, reg):
    addr = reg.getAddress()
    mask = reg.getMask()
    hw.getClient().write(addr, mask)
    hw.dispatch()

def regdump():

    hw = setup()

    for id in hw.getNodes():
        reg = hw.getNode(id)
        if ((reg.getPermission() == uhal.NodePermission.READ) or \
            (reg.getPermission() == uhal.NodePermission.READWRITE) and \
            (reg.getModule() == "")
        ):
            print_reg(hw,reg,"")
            #val = reg.read();
            #hw.dispatch();
            #print("%s 0x%08X" % (id, val))

def print_reg (hw, reg, pad=""):
    val = reg.read();
    id = reg.getPath()
    hw.dispatch();
    print(format_reg (reg.getAddress(), id, val, format_permission(reg.getPermission())))

def tab_pad (s,maxlen):
    return (s+"\t"*(int((8*maxlen-len(s)-1)/8)+1))

def format_reg (address, name, val, permission=""):
    s = ("0x%04X" % address) + ' ' + tab_pad(permission,1) \
        + tab_pad (str(name),8)
    if (val!=-1):
        s = s + ("0x%08X" % val)
    return s

def format_permission (perm):
    if perm == uhal.NodePermission.READ:
        return "r"
    if perm == uhal.NodePermission.READWRITE:
        return "rw"
    if perm == uhal.NodePermission.WRITE:
        return "w"

def reset_pattern_checkers (rb=0):
    write_node("READOUT_BOARD_%i.LPGBT.PATTERN_CHECKER.RESET" % rb, 1)
    write_node("READOUT_BOARD_%i.LPGBT.PATTERN_CHECKER.RESET" % rb, 0)

    write_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN" % rb, 0)
    write_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN" % rb, 0)

    write_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN" % rb, 0xFFFFFFFF)
    write_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN" % rb, 0xFFFFFFFF)

def read_pattern_checkers (rb=0):

    prbs_en = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_PRBS_EN" % rb)
    upcnt_en = read_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.CHECK_UPCNT_EN" % rb)

    for mode in ["PRBS", "UPCNT"]:
        for i in range (0,27):

            if mode=="UPCNT" and ((upcnt_en >> i) & 0x1):
                check = True
            if mode=="PRBS" and ((prbs_en >> i) & 0x1):
                check = True

            if check:
                write_node("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.SEL" % (rb), 1)

                uptime_msbs = read_node ("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.TIMER_MSBS" % (rb))
                uptime_lsbs = read_node ("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.TIMER_LSBS" % (rb))

                uptime = (uptime_msbs << 32) | uptime_lsbs

                errs = read_node ("READOUT_BOARD_%d.LPGBT.PATTERN_CHECKER.%s_ERRORS" % (rb,mode))

                print ("Channel %02d %d bad frames in %.0f Gb" % (i, errs, uptime*8*320/1000000000.0))




if __name__ == '__main__':

    main()
