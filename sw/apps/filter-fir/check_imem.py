import re

# Read the hex dump of the elf file, wait, we don't have objdump.
# But we can read pext.elf directly to find symbol values if we parse the symbol table, which is hard in Python without ELF parser.
# Instead, let's just find the pattern of the store instruction at the end of main.
# Wait, let's just use Python's regex on the binary to find the instruction sequence.

def check_hex():
    with open('pext_imem.hex', 'r') as f:
        print("IMEM Hex first 10 lines:")
        for _ in range(10):
            print(f.readline().strip())

check_hex()
