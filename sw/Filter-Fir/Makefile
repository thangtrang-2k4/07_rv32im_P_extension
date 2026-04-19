# ======================================================================
# Makefile — Filter-Fir (Scala vs P-Extension)
#
# Cách dùng:
#   make scala      → biên dịch scala.c → scala_imem.hex + scala_dmem.hex
#   make pext       → biên dịch pext.c  → pext_imem.hex  + pext_dmem.hex
#   make all        → biên dịch cả hai
#   make clean      → xoá file trung gian
# ======================================================================

CROSS   := riscv32-unknown-elf
CC      := $(CROSS)-gcc
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump

# Địa chỉ gốc (khớp với link.ld)
IMEM_ORIGIN := 0x80000000
DMEM_ORIGIN := 0x80010000

SCALA_CFLAGS  := -O2 -nostdlib -march=rv32im -mabi=ilp32
PEXT_CFLAGS   := -O2 -nostdlib -march=rv32imp -mabi=ilp32
LDFLAGS       := -T link.ld

# ── Scala (RV32IM) ──────────────────────────────────────────────────
scala: scala_imem.hex scala_dmem.hex

scala.elf: start.s scala.c link.ld
	$(CC) $(SCALA_CFLAGS) $(LDFLAGS) start.s scala.c -o $@

scala.s: scala.elf
	$(OBJDUMP) -d $< > $@

scala_imem.hex: scala.elf
	$(OBJCOPY) -O verilog \
	    --only-section=.text --verilog-data-width=4 \
	    $< $@

scala_dmem.hex: scala.elf
	$(OBJCOPY) -O verilog \
	    --only-section=.rodata --only-section=.data --only-section=.bss --verilog-data-width=4 \
	    $< $@

# ── P-Extension (RV32IMP) ───────────────────────────────────────────
pext: pext_imem.hex pext_dmem.hex

pext.elf: start.s pext.c link.ld
	$(CC) $(PEXT_CFLAGS) $(LDFLAGS) start.s pext.c -o $@

pext.s: pext.elf
	$(OBJDUMP) -d $< > $@

pext_imem.hex: pext.elf
	$(OBJCOPY) -O verilog \
	    --only-section=.text --verilog-data-width=4 \
	    $< $@

pext_dmem.hex: pext.elf
	$(OBJCOPY) -O verilog \
	    --only-section=.rodata --only-section=.data --only-section=.bss --verilog-data-width=4 \
	    $< $@

# ── All & Clean ─────────────────────────────────────────────────────
all: scala pext

clean:
	rm -f *.elf *.hex

.PHONY: all scala pext clean
