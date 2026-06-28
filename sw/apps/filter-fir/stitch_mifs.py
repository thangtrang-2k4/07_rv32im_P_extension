import sys
import re

def parse_mif(filename):
    data = []
    with open(filename, 'r') as f:
        in_content = False
        for line in f:
            line = line.strip()
            if line.startswith('CONTENT'):
                in_content = True
                continue
            if in_content and ':' in line:
                # Format: "addr : data;"
                parts = line.split(':')
                if len(parts) == 2:
                    val = parts[1].strip().strip(';')
                    # Handle ranges like "[1A..FF] : 00" -> not strictly needed if we just read up to DEPTH
                    if '..' not in parts[0]:
                        data.append(val)
    return data

def stitch_mifs(out_filename, mif0, mif1, mif2, mif3, depth=1096):
    d0 = parse_mif(mif0)
    d1 = parse_mif(mif1)
    d2 = parse_mif(mif2)
    d3 = parse_mif(mif3)
    
    # Pad if necessary
    for d in [d0, d1, d2, d3]:
        while len(d) < depth:
            d.append("00")

    with open(out_filename, 'w') as f:
        for i in range(depth):
            # Combine bytes: DM3 (MSB) -> DM2 -> DM1 -> DM0 (LSB)
            # Make sure each is 2 chars
            b0 = d0[i].zfill(2) if i < len(d0) else "00"
            b1 = d1[i].zfill(2) if i < len(d1) else "00"
            b2 = d2[i].zfill(2) if i < len(d2) else "00"
            b3 = d3[i].zfill(2) if i < len(d3) else "00"
            
            # Write 32-bit hex word
            f.write(f"{b3}{b2}{b1}{b0}\n")

if __name__ == '__main__':
    stitch_mifs('final_output.hex', 'dm0.mif', 'dm1.mif', 'dm2.mif', 'dm3.mif')
    print("Stitched successfully into final_output.hex!")
