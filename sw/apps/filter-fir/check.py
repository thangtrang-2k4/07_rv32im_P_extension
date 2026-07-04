import subprocess
import os

def check_elf(elf_path):
    # Try to find riscv32-unknown-elf-nm or use python library
    print("Checking ELF:", elf_path)
    try:
        # Just search the hex file if elf dump fails
        pass
    except Exception as e:
        print(e)

if __name__ == "__main__":
    with open("pext.c", "r") as f:
        print("pext.c content snippet:")
        print(f.read()[-300:])
