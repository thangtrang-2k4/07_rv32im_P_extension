import sys
import os
import argparse

def create_mif(filename, data_list, depth=4096):
    with open(filename, 'w') as f:
        f.write(f"DEPTH = {depth};\n")
        f.write("WIDTH = 8;\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT\nBEGIN\n")
        for addr, val in enumerate(data_list):
            f.write(f"{addr:04X} : {val};\n")
        if len(data_list) < depth:
            f.write(f"[{len(data_list):04X}..{depth-1:04X}] : 00;\n")
        f.write("END;\n")

def process_file(input_file, depth=4096):
    if not os.path.exists(input_file):
        print(f"File not found: {input_file}")
        return

    print(f"Processing {input_file}...")
    with open(input_file, 'r') as f:
        lines = f.readlines()
        
    data0, data1, data2, data3 = [], [], [], []
    
    for line in lines:
        line = line.strip()
        if line.startswith('@'):
            continue # Ignore address markers, assuming sequential
        elif len(line) == 8:
            data0.append(line[6:8])
            data1.append(line[4:6])
            data2.append(line[2:4])
            data3.append(line[0:2])
            
    base = input_file.replace('.hex', '')
    create_mif(f"{base}_0.mif", data0, depth)
    create_mif(f"{base}_1.mif", data1, depth)
    create_mif(f"{base}_2.mif", data2, depth)
    create_mif(f"{base}_3.mif", data3, depth)
    print(f"Generated {base}_0.mif to _3.mif successfully!")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        for f in sys.argv[1:]:
            process_file(f, depth=4096)
    else:
        apps = ['filter-fir', 'filter-sobel', 'matrix-multiplication']
        for app in apps:
            dmem_path = os.path.join(app, 'pext_dmem.hex')
            imem_path = os.path.join(app, 'pext_imem.hex')
            process_file(dmem_path, depth=4096)
            process_file(imem_path, depth=4096)
