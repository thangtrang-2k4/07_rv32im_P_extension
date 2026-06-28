import sys
import re

def create_mif(filename, data_list, depth=1096, width=8):
    with open(filename, 'w') as f:
        f.write(f"DEPTH = {depth};\n")
        f.write(f"WIDTH = {width};\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT BEGIN\n")
        for i, val in enumerate(data_list):
            f.write(f"    {hex(i)[2:]} : {val};\n")
        if len(data_list) < depth:
            f.write(f"    [{hex(len(data_list))[2:]}..{hex(depth-1)[2:]}] : 00;\n")
        f.write("END;\n")

def split_hex(input_file):
    with open(input_file, 'r') as f:
        content = f.read()
        
    words = re.findall(r'\b[0-9a-fA-F]{8}\b', content)
    data0 = []
    data1 = []
    data2 = []
    data3 = []
    
    for w in words:
        data0.append(w[6:8])
        data1.append(w[4:6])
        data2.append(w[2:4])
        data3.append(w[0:2])
        
    create_mif(input_file.replace('.hex', '_0.mif'), data0)
    create_mif(input_file.replace('.hex', '_1.mif'), data1)
    create_mif(input_file.replace('.hex', '_2.mif'), data2)
    create_mif(input_file.replace('.hex', '_3.mif'), data3)
    print("MIF generation successful!")

if __name__ == '__main__':
    split_hex('pext_dmem.hex')
