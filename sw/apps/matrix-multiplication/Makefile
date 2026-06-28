# ======================================================================
# Makefile — Matrix-Multiplication (Scala vs P-Extension)
# ======================================================================

CROSS   := riscv32-unknown-elf
CC      := $(CROSS)-gcc
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump

SCALA_CFLAGS  := -O2 -nostdlib -march=rv32im -mabi=ilp32
PEXT_CFLAGS   := -O2 -nostdlib -march=rv32imp -mabi=ilp32
LDFLAGS       := -T link.ld

# ── Scala (RV32IM) ──────────────────────────────────────────────────
scala: scala_imem.hex scala_dmem.hex scala.dump

scala.elf: start.s scala.c link.ld matrix_data.h
	$(CC) $(SCALA_CFLAGS) $(LDFLAGS) start.s scala.c -o $@

scala.dump: scala.elf
	$(OBJDUMP) -D $< > $@

scala_imem.hex: scala.elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80000000 --only-section=.text --verilog-data-width=4 \
	    $< $@

scala_dmem.hex: scala.elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80010000 --only-section=.rodata --only-section=.data --only-section=.bss --verilog-data-width=4 \
	    $< $@

# ── P-Extension (RV32IMP) ───────────────────────────────────────────
pext: pext_imem.hex pext_dmem.hex pext.dump

pext.elf: start.s pext.c link.ld matrix_data.h
	$(CC) $(PEXT_CFLAGS) $(LDFLAGS) start.s pext.c -o $@

pext.dump: pext.elf
	$(OBJDUMP) -D $< > $@

pext_imem.hex: pext.elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80000000 --only-section=.text --verilog-data-width=4 \
	    $< $@

pext_dmem.hex: pext.elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80010000 --only-section=.rodata --only-section=.data --only-section=.bss --verilog-data-width=4 \
	    $< $@
	@echo "Generating 4-way MIF files for Quartus..."
	python3 ../generate_mif.py $@

# ── All & Clean ─────────────────────────────────────────────────────
all: scala pext

clean:
	rm -f *.elf *.hex scala.dump pext.dump

.PHONY: all scala pext clean
