import re
import sys
import os

def main():
    if len(sys.argv) < 3:
        print("Usage: python map_mismatch.py <log_file> <asm_file>")
        return

    log_file = sys.argv[1]
    asm_file = sys.argv[2]

    # Parse asm file
    tests = []
    current_context = ""
    try:
        with open(asm_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            for i, line in enumerate(lines):
                line_str = line.strip()
                if not line_str or line_str.startswith('#'):
                    # Check if it's a test section comment
                    if line_str.startswith('##################################################'):
                        continue
                    if line_str.startswith('#'):
                        current_context = line_str[1:].strip()
                    continue
                
                if line_str.startswith('sw '):
                    # Found a store, meaning the end of a test case
                    # The instruction tested is usually the one right before the store
                    prev_inst = ""
                    if i > 0:
                        prev_inst = lines[i-1].strip()
                    
                    tests.append({
                        'line': i + 1,
                        'inst': prev_inst,
                        'context': current_context
                    })
    except Exception as e:
        print(f"Error reading {asm_file}: {e}")
        return

    # Parse log file
    mismatches = []
    base_address = None
    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            log_lines = f.readlines()
            for line in log_lines:
                match = re.search(r'(Match|Mismatch) at address ([0-9a-fA-F]+): expected ([0-9a-fA-F]+), got ([0-9a-fA-F]+)', line)
                if match:
                    status = match.group(1)
                    addr = int(match.group(2), 16)
                    expected = match.group(3)
                    got = match.group(4)

                    if base_address is None or addr < base_address:
                        base_address = addr
                    
                    if status == 'Mismatch':
                        mismatches.append({
                            'addr': addr,
                            'expected': expected,
                            'got': got
                        })
    except Exception as e:
        print(f"Error reading {log_file}: {e}")
        return

    if base_address is None:
        print("No Match/Mismatch found in log.")
        return

    # Map mismatches
    print("=== Mismatch Report ===")
    for m in mismatches:
        index = (m['addr'] - base_address) // 4
        if 0 <= index < len(tests):
            test_info = tests[index]
            print(f"Mismatch at Address: 0x{m['addr']:x}")
            print(f"  Expected: {m['expected']} | Got: {m['got']}")
            print(f"  Test Case: {test_info['context']}")
            print(f"  Instruction: {test_info['inst']}")
            print(f"  File: {asm_file} at Line {test_info['line'] - 1} (Instruction) / {test_info['line']} (Store)")
            print("-" * 40)
        else:
            print(f"Mismatch at Address: 0x{m['addr']:x} (Could not map to a test case)")
            print(f"  Expected: {m['expected']} | Got: {m['got']}")
            print("-" * 40)

if __name__ == '__main__':
    main()
