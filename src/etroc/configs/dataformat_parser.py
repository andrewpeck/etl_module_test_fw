import yaml

filename = "dataformat"
stream = open(filename+".yaml", "r")
ROC2dat = yaml.safe_load(stream)["ETROC2"]

def toVHDhex(num, length=0):
    return 'x"{num:0{width}X}"'.format(num=num, width=length)


def mask2range(num):
    binnum = bin(num)[2:]
    start = len(binnum) - 1
    end = len(binnum) - binnum.rfind("1") - 1
    return str(start)+" downto "+str(end)

def defConstants(dat):
    data = dat["identifiers"]

    max = 0
    for const in data:
        for typ in data[const]:
            length = len(str.upper(const) + str.upper(typ))
            if (length > max):
                max = length

    for const in data:
        for typ in data[const]:
            vhd.write("  constant %s_IDENTIFIER_%s%s: std_logic_vector (39 downto 0) := %s;\n" % (
                    str.upper(const),
                    str.upper(typ),
                    " "*(max-len(str.upper(const) + str.upper(typ))),
                    toVHDhex(data[const][typ], 10)))

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

vhd.write("package "+filename+"_pkg is"+"\n")

vhd.write("\n")

vhd.write("  constant REVERSE : boolean := ")
if ROC2dat["bitorder"] == "reversed": vhd.write("true")
else: vhd.write("false")
vhd.write(";\n\n")

defConstants(ROC2dat)

vhd.write("\n")

defSubTypes(ROC2dat, "header")
defSubTypes(ROC2dat, "data")
defSubTypes(ROC2dat, "trailer")

vhd.write("end package "+filename+"_pkg;")
