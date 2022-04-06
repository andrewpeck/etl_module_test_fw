import yaml

filename = "fast_commands"
stream = open(filename+".yaml", "r")
ROC2dat = yaml.safe_load(stream)["ETROC2"]

def toVHDhex(num, length=0):
    VHDhex = str(hex(num))
    if length == 0: length = len(VHDhex)
    return VHDhex[1]+"\""+str.upper(VHDhex[2:])[:length]+"\""

def writeData(dat, vhd):
    for const in dat:
        vhd.write("\tconstant "+const+"_CMD\t: ")
        vhd.write("std_logic_vector(7 downto 0) := "+toVHDhex(dat[const])+";\n")
    return

vhd = open(filename+".vhd", "w")

vhd.write("library ieee;\n")
vhd.write("use ieee.std_logic_1164.all;\n")
vhd.write("use ieee.std_logic_misc.all;\n")
vhd.write("use ieee.numeric_std.all;\n")
vhd.write("\n")
vhd.write("package "+filename+"_pkg is"+"\n")
writeData(ROC2dat, vhd)
vhd.write("end package "+filename+"_pkg;")