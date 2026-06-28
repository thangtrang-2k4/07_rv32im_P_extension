import sys

def split_hex(input_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()
        
    out0 = open(input_file.replace('.hex', '_0.hex'), 'w')
    out1 = open(input_file.replace('.hex', '_1.hex'), 'w')
    out2 = open(input_file.replace('.hex', '_2.hex'), 'w')
    out3 = open(input_file.replace('.hex', '_3.hex'), 'w')
    
    for line in lines:
        line = line.strip()
        if line.startswith('@'):
            out0.write(line + '\n')
            out1.write(line + '\n')
            out2.write(line + '\n')
            out3.write(line + '\n')
        elif len(line) == 8:
            out0.write(line[6:8] + '\n')
            out1.write(line[4:6] + '\n')
            out2.write(line[2:4] + '\n')
            out3.write(line[0:2] + '\n')
            
    out0.close()
    out1.close()
    out2.close()
    out3.close()

split_hex('pext_dmem.hex')
