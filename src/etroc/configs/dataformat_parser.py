import yaml

filename = "dataformat"
stream = open(filename+".yaml", "r")
ROC2dat = yaml.safe_load(stream)["ETROC2"]

def toVHDhex(num, length=0):
    hexnum = str(hex(num))
    if length == 0:
        length = len(hexnum)
        hexnum = hexnum[1]+"\""+str.upper(hexnum[2:])+"\""
    elif length <= len(hexnum):
        hexnum = hexnum[1]+"\""+str.upper(hexnum[2:])[:length]+"\""
    else:
        num0 = length - len(hexnum) + 2
        hexnum = hexnum[1]+"\""+"0"*num0+str.upper(hexnum[2:])+"\""
    return hexnum

def mask2range(num):
    binnum = bin(num)[2:]
    start = len(binnum) - 1
    end = len(binnum) - binnum.rfind("1") - 1
    return str(start)+" down to "+str(end)

def defConstants(dat):
    data = dat["identifiers"]
    for const in data:
        for typ in data[const]:
            vhd.write("constant "+str.upper(const)+"_IDENTIFIER_"
                +str.upper(typ)+"\t: std_logic_vector (39 downto 0) := "
                +toVHDhex(data[const][typ], 10)+";\n")

def defSubTypes(dat, name):
    data = dat["data"][name]
    vhd.write("  -- "+name+"\n")
    for const in reversed(data):
        vhd.write("  subtype "+str.upper(const)+"_RANGE is natural range "
            +mask2range(data[const]["mask"])+";\n")
    vhd.write("\n")


vhd = open(filename+".vhd", "w")

vhd.write("library ieee;\n")
vhd.write("use ieee.std_logic_1164.all;\n")
vhd.write("use ieee.std_logic_misc.all;\n")
vhd.write("use ieee.numeric_std.all;\n")
vhd.write("\n")

vhd.write("constant REVERSE : boolean := ")
if ROC2dat["bitorder"] == "reversed": vhd.write("true")
else: vhd.write("false")
vhd.write(";\n\n")

defConstants(ROC2dat)
vhd.write("\n")

vhd.write("package "+filename+"_pkg is"+"\n")
vhd.write("\n")

defSubTypes(ROC2dat, "header")
defSubTypes(ROC2dat, "data")
defSubTypes(ROC2dat, "trailer")

vhd.write("end package "+filename+"_pkg;")