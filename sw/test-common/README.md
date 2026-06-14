# Signature Test Flow

These tests write observed values to the `.signature` buffer at `0x80010000`.
The testbench dumps that memory range and compares it against `golden.hex`.

Build a test from its directory:

```sh
make
```

Run from `sim/` using one of the convenience targets:

```sh
make rv32i-inst
make rv32im-inst
make rv32imp-inst
make hazards-rv32imp
```

Address map:

| Region | Address |
|---|---:|
| IMEM | `0x80000000` |
| DMEM | `0x80010000` |
| Signature start | `0x80010000` |
| Done flag | `0x80013ffc` |
