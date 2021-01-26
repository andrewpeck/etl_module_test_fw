import xml.etree.ElementTree as xml

DEBUG = True
ADDRESS_TABLE_TOP = './lpgbt_registers.xml'
nodes = []
system = ""
TOP_NODE_NAME = "LPGBT"


class Node:
    name = ''
    vhdlname = ''
    address = 0x0
    real_address = 0x0
    permission = ''
    mask = 0x0
    lsb_pos = 0x0
    is_module = False
    parent = None
    level = 0
    mode = None

    def __init__(self):
        self.children = []

    def addChild(self, child):
        self.children.append(child)

    def getVhdlName(self):
        return self.name.replace(TOP_NODE_NAME + '.', '').replace('.', '_')

    def output(self):
        print('Name:', self.name)
        print('Address:', '{0:#010x}'.format(self.address))
        print('Permission:', self.permission)
        print('Mask:', self.mask)
        print('LSB:', self.lsb_pos)
        print('Module:', self.is_module)
        print('Parent:', self.parent.name)


def main():
    parse_xml()
    dump()

def dump():
    i = 0
    for node in nodes:
        if i > 0:
            print(node.name)
            #node.output()
        i = i+1


# Functions related to parsing registers.xml
def parse_xml(filename=None):
    if filename is None:
        filename = ADDRESS_TABLE_TOP
    print('Parsing', filename, '...')
    tree = xml.parse(filename)
    root = tree.getroot()[0]
    vars = {}
    make_tree(root, '', 0x0, nodes, None, vars, False)


def make_tree(node, base_name, base_address, nodes, parent_node, vars, is_generated):
    if ((is_generated is None or is_generated is False)
        and node.get('generate') is not None
        and node.get('generate') == 'true'):

        generate_size = parse_int(node.get('generate_size'))
        generate_step = parse_int(node.get('generate_address_step'))
        generate_var = node.get('generate_idx_var')
        for i in range(0, generate_size):
            vars[generate_var] = i
            make_tree(node, base_name, base_address + generate_step * i, nodes, parent_node, vars, True)
        return

    new_node = Node()
    name = base_name
    if base_name != '':
        name += '.'
    name += node.get('id')
    name = substitute_vars(name, vars)
    new_node.name = name
    address = base_address
    if node.get('address') is not None:
        address = base_address + parse_int(eval(node.get('address')))
    new_node.address = address
    new_node.real_address = address
    new_node.permission = node.get('permission')
    new_node.mask = parse_int(node.get('mask'))
    new_node.lsb_pos = mask_to_lsb(new_node.mask)
    new_node.is_module = node.get('fw_is_module') is not None and node.get('fw_is_module') == 'true'
    if node.get('mode') is not None:
        new_node.mode = node.get('mode')
    nodes.append(new_node)
    if parent_node is not None:
        parent_node.addChild(new_node)
        new_node.parent = parent_node
        new_node.level = parent_node.level+1
    for child in node:
        make_tree(child, name, address, nodes, new_node, vars, False)


def get_all_children(node, kids=[]):
    if node.children == []:
        kids.append(node)
        return kids
    else:
        for child in node.children:
            get_all_children(child, kids)


def get_node(nodeName):
    thisnode = next(
        (node for node in nodes if node.name == nodeName), None
    )
    if thisnode is None:
        print(nodeName)
    return thisnode


def get_node_by_id(number):
    return nodes[number]


def get_node_from_address(nodeAddress):
    return next((node for node in nodes if node.real_address == nodeAddress), None)


def get_nodes_containing(nodeString):
    nodelist = [node for node in nodes if nodeString in node.name]
    if len(nodelist):
        return nodelist
    else:
        return None


def getRegsContaining(nodeString):
    nodelist = [node for node in nodes if
                nodeString in node.name and node.permission is not None and 'r' in node.permission]
    if len(nodelist):
        return nodelist
    else:
        return None


def read_reg(mpeek, reg):
    try:
        address = reg.real_address
    except:
        print('Reg', reg, 'not a Node')
        return

    if 'r' not in reg.permission:
        print('No read permission!')
        return 'No read permission!'

    # read
    value = mpeek(address)

    # Apply Mask
    if reg.mask != 0:
        value = (reg.mask & value) >> reg.lsb_pos

    return value


def write_reg(mpoke, mpeek, reg, value, readback=False):
    try:
        address = reg.real_address
    except:
        print('Reg', reg, 'not a Node')
        return
    if 'w' not in reg.permission:
        return 'No write permission!'

    if readback:
        read = read_reg(mpeek, reg)
        if value != read:
            print("ERROR: Failed to read back register %s. Expect=0x%x Read=0x%x" % (reg.name, value, read))
    else:
        # Apply Mask if applicable
        if reg.mask != 0:
            value = value << reg.lsb_pos
            value = value & reg.mask
            if 'r' in reg.permission:
                value = (value) | (mpeek(address) & ~reg.mask)
        # mpoke
        mpoke(address, value)


def substitute_vars(string, vars):
    if string is None:
        return string
    ret = string
    for varKey in vars.keys():
        ret = ret.replace('${' + varKey + '}', str(vars[varKey]))
    return ret


def mask_to_lsb(mask):
    if mask is None:
        return 0
    if (mask & 0x1):
        return 0
    else:
        idx = 1
        while (True):
            mask = mask >> 1
            if (mask & 0x1):
                return idx
            idx = idx+1


def parse_int(s):
    if s is None:
        return None
    string = str(s)
    if string.startswith('0x'):
        return int(string, 16)
    elif string.startswith('0b'):
        return int(string, 2)
    else:
        return int(string)


if __name__ == '__main__':
    main()
