import sys
import re

def create_mif(filename, depth, width, data):
    with open(filename, 'w') as f:
        f.write(f"DEPTH = {depth};\n")
        f.write(f"WIDTH = {width};\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT\nBEGIN\n")
        for i, val in enumerate(data):
            f.write(f"{i:X} : {val};\n")
        if len(data) < depth:
            f.write(f"[{len(data):X}..{depth-1:X}] : 00;\n")
        f.write("END;\n")

def convert_hex_to_mifs(input_file, depth=4096):
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Extract all hex words (8 chars)
    words = re.findall(r'\b[0-9a-fA-F]{8}\b', content)
    
    data0, data1, data2, data3 = [], [], [], []
    for w in words:
        # Little endian extraction from 8-char hex string
        data0.append(w[6:8])
        data1.append(w[4:6])
        data2.append(w[2:4])
        data3.append(w[0:2])
        
    create_mif(input_file.replace('.hex', '_0.mif'), depth, 8, data0)
    create_mif(input_file.replace('.hex', '_1.mif'), depth, 8, data1)
    create_mif(input_file.replace('.hex', '_2.mif'), depth, 8, data2)
    create_mif(input_file.replace('.hex', '_3.mif'), depth, 8, data3)

if len(sys.argv) > 1:
    convert_hex_to_mifs(sys.argv[1], 4096)
else:
    convert_hex_to_mifs('pext_dmem.hex', 4096)
