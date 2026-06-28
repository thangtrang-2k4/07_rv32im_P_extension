import sys

def read_intel_hex(filename):
    mem = {}
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line.startswith(':'): continue
            byte_count = int(line[1:3], 16)
            address = int(line[3:7], 16)
            record_type = int(line[7:9], 16)
            if record_type == 0:
                data = line[9:9+byte_count*2]
                for i in range(byte_count):
                    mem[address + i] = int(data[i*2:i*2+2], 16)
    return mem

dm0 = read_intel_hex("quartus/rv32imp-de2/output_files/DM0.hex")
dm1 = read_intel_hex("quartus/rv32imp-de2/output_files/DM1.hex")
dm2 = read_intel_hex("quartus/rv32imp-de2/output_files/DM2.hex")
dm3 = read_intel_hex("quartus/rv32imp-de2/output_files/DM3.hex")

sig = []
with open("sw/apps/filter-fir/pext_signature.hex", "r") as f:
    for line in f:
        line = line.strip()
        if line:
            sig.append(int(line, 16))

OUTPUT_WORD_ADDR = 0x01B0 // 4

print("Addr      | Dumped   | Signature | Match?")
print("-" * 45)
mismatch_count = 0
for i in range(len(sig)):
    w_addr = OUTPUT_WORD_ADDR + i
    b0 = dm0.get(w_addr, 0)
    b1 = dm1.get(w_addr, 0)
    b2 = dm2.get(w_addr, 0)
    b3 = dm3.get(w_addr, 0)
    
    val = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    
    match = (val == sig[i])
    if not match:
        mismatch_count += 1
    
    # Only print first 20 and mismatched
    if i < 10 or not match:
        print(f"{w_addr*4:08x}  | {val:08x} | {sig[i]:08x}  | {'Yes' if match else 'No'}")

print(f"\nTotal Mismatches: {mismatch_count} / {len(sig)}")
