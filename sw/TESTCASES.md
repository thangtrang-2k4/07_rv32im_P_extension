# RV32I/RV32IM/RV32IMP Signature Testcases

## Test layout

| Directory | Purpose | Core/testbench |
|---|---|---|
| `rv32i-inst-test` | RV32I base instruction functional tests | `tb_rv32im_signature` |
| `rv32im-inst-test` | RV32M multiply/divide/remainder functional tests | `tb_rv32im_signature` |
| `rv32imp-inst-test` | P-extension functional tests | `tb_rv32imp_signature` |
| `hazards-rv32imp-test` | Integrated pipeline hazard tests | `tb_rv32imp_signature` |
| `test-common` | Shared linker script and address map notes | n/a |

All tests use the same signature flow:

1. Program writes observed results to `.signature` at `0x80010000`.
2. Program writes `1` to `_done_flag` at `0x80013ffc`.
3. Testbench dumps the signature words to `result.hex`.
4. Testbench compares `result.hex` against `golden.hex`.

## Build commands

On the GNU toolchain VM, build testcase hex files from `sw/`:

```sh
make rv32i-inst
make rv32im-inst
make rv32imp-inst
make hazards-rv32imp
```

This generates the `*_imem.hex`, `*_dmem.hex`, and `*.dump` files inside each testcase directory. The individual testcase directories do not have their own Makefiles; build commands are centralized in `sw/Makefile`.

## Simulation commands

On the QuestaSim VM, run testcase simulations from `sim/`:

```sh
make rv32i-inst
make rv32im-inst
make rv32imp-inst
make hazards-rv32imp
```

Prerequisites:

For `sw/` builds:

- `riscv32-unknown-elf-gcc`
- `riscv32-unknown-elf-objcopy`
- `riscv32-unknown-elf-objdump`
- GNU Make

For `sim/` runs:

- QuestaSim commands in PATH: `vlib`, `vlog`, `vsim`

## What each test covers

`rv32i-inst-test` covers:

- U-type: `lui`, `auipc`
- I-type ALU: `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, shifts
- R-type ALU: `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and`
- load/store: `lb`, `lh`, `lw`, `lbu`, `lhu`, `sb`, `sh`, `sw`
- control: all branch types, `jal`, `jalr`
- ISA edge rules: `x0` stays zero, shift amount mask, sign extension

`rv32im-inst-test` covers:

- `mul`, `mulh`, `mulhsu`, `mulhu`
- `div`, `divu`, `rem`, `remu`
- divide-by-zero and signed overflow behavior

`rv32imp-inst-test` covers:

- packed byte/halfword add, subtract, average, saturating add/subtract
- packed compare, min/max, abs, signed/unsigned clipping
- `pm4adda.b`, `pm4addau.b`, `pm4addasu.b`

`hazards-rv32imp-test` covers:

- EX/MEM and MEM/WB forwarding into ALU operands
- ALU-to-store data/base forwarding
- load-use stalls into ALU, store, branch, and MAC operands
- branch/jump flush behavior
- JAL/JALR link use
- M-extension result hazards
- P-extension result hazards
- MAC accumulator forwarding through `rd` as source and destination
