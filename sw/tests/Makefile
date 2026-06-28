# ======================================================================
# Makefile - RV32 instruction/signature testcase software builds
#
# Usage:
#   make rv32i-inst        -> build rv32i_imem.hex + rv32i_dmem.hex
#   make rv32im-inst       -> build rv32im_imem.hex + rv32im_dmem.hex
#   make rv32imp-inst      -> build rv32imp_imem.hex + rv32imp_dmem.hex
#   make hazards-rv32imp   -> build hazards_rv32imp_imem.hex + hazards_rv32imp_dmem.hex
#   make all               -> build all testcase hex files
#   make clean             -> remove generated outputs
# ======================================================================

CROSS ?= riscv32-unknown-elf
CC := $(CROSS)-gcc
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump

LINKER := ../common/link.ld
CFLAGS := -nostdlib -nostartfiles -ffreestanding -mabi=ilp32
LDFLAGS := -T $(LINKER)

RV32I_PREFIX := rv32i-inst-test/rv32i
RV32IM_PREFIX := rv32im-inst-test/rv32im
RV32IMP_PREFIX := rv32imp-inst-test/rv32imp
HAZARDS_PREFIX := hazards-rv32imp-test/hazards_rv32imp

all: rv32i-inst rv32im-inst rv32imp-inst hazards-rv32imp

rv32i-inst: $(RV32I_PREFIX)_imem.hex $(RV32I_PREFIX)_dmem.hex $(RV32I_PREFIX).dump

$(RV32I_PREFIX).elf: rv32i-inst-test/rv32i_test.S $(LINKER)
	$(CC) $(CFLAGS) -march=rv32i $(LDFLAGS) $< -o $@

$(RV32I_PREFIX)_imem.hex: $(RV32I_PREFIX).elf
	$(OBJCOPY) -O verilog --adjust-vma=-0x80000000 --only-section=.text --verilog-data-width=4 $< $@

$(RV32I_PREFIX)_dmem.hex: $(RV32I_PREFIX).elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80010000 --only-section=.signature --only-section=.rodata --only-section=.data --only-section=.bss \
	    --verilog-data-width=4 $< $@

$(RV32I_PREFIX).dump: $(RV32I_PREFIX).elf
	$(OBJDUMP) -d $< > $@

rv32im-inst: $(RV32IM_PREFIX)_imem.hex $(RV32IM_PREFIX)_dmem.hex $(RV32IM_PREFIX).dump

$(RV32IM_PREFIX).elf: rv32im-inst-test/rv32im_test.S $(LINKER)
	$(CC) $(CFLAGS) -march=rv32im $(LDFLAGS) $< -o $@

$(RV32IM_PREFIX)_imem.hex: $(RV32IM_PREFIX).elf
	$(OBJCOPY) -O verilog --adjust-vma=-0x80000000 --only-section=.text --verilog-data-width=4 $< $@

$(RV32IM_PREFIX)_dmem.hex: $(RV32IM_PREFIX).elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80010000 --only-section=.signature --only-section=.rodata --only-section=.data --only-section=.bss \
	    --verilog-data-width=4 $< $@

$(RV32IM_PREFIX).dump: $(RV32IM_PREFIX).elf
	$(OBJDUMP) -d $< > $@

rv32imp-inst: $(RV32IMP_PREFIX)_imem.hex $(RV32IMP_PREFIX)_dmem.hex $(RV32IMP_PREFIX).dump

$(RV32IMP_PREFIX).elf: rv32imp-inst-test/rv32imp_test.S $(LINKER)
	$(CC) $(CFLAGS) -march=rv32imp $(LDFLAGS) $< -o $@

$(RV32IMP_PREFIX)_imem.hex: $(RV32IMP_PREFIX).elf
	$(OBJCOPY) -O verilog --adjust-vma=-0x80000000 --only-section=.text --verilog-data-width=4 $< $@

$(RV32IMP_PREFIX)_dmem.hex: $(RV32IMP_PREFIX).elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80010000 --only-section=.signature --only-section=.rodata --only-section=.data --only-section=.bss \
	    --verilog-data-width=4 $< $@

$(RV32IMP_PREFIX).dump: $(RV32IMP_PREFIX).elf
	$(OBJDUMP) -d $< > $@

hazards-rv32imp: $(HAZARDS_PREFIX)_imem.hex $(HAZARDS_PREFIX)_dmem.hex $(HAZARDS_PREFIX).dump

$(HAZARDS_PREFIX).elf: hazards-rv32imp-test/hazards_rv32imp_test.S $(LINKER)
	$(CC) $(CFLAGS) -march=rv32imp $(LDFLAGS) $< -o $@

$(HAZARDS_PREFIX)_imem.hex: $(HAZARDS_PREFIX).elf
	$(OBJCOPY) -O verilog --adjust-vma=-0x80000000 --only-section=.text --verilog-data-width=4 $< $@

$(HAZARDS_PREFIX)_dmem.hex: $(HAZARDS_PREFIX).elf
	$(OBJCOPY) -O verilog \
	    --adjust-vma=-0x80010000 --only-section=.signature --only-section=.rodata --only-section=.data --only-section=.bss \
	    --verilog-data-width=4 $< $@

$(HAZARDS_PREFIX).dump: $(HAZARDS_PREFIX).elf
	$(OBJDUMP) -d $< > $@

clean:
	rm -f \
	    $(RV32I_PREFIX).elf $(RV32I_PREFIX).dump $(RV32I_PREFIX)_imem.hex $(RV32I_PREFIX)_dmem.hex rv32i-inst-test/result.hex \
	    $(RV32IM_PREFIX).elf $(RV32IM_PREFIX).dump $(RV32IM_PREFIX)_imem.hex $(RV32IM_PREFIX)_dmem.hex rv32im-inst-test/result.hex \
	    $(RV32IMP_PREFIX).elf $(RV32IMP_PREFIX).dump $(RV32IMP_PREFIX)_imem.hex $(RV32IMP_PREFIX)_dmem.hex rv32imp-inst-test/result.hex \
	    $(HAZARDS_PREFIX).elf $(HAZARDS_PREFIX).dump $(HAZARDS_PREFIX)_imem.hex $(HAZARDS_PREFIX)_dmem.hex hazards-rv32imp-test/result.hex

.PHONY: all rv32i-inst rv32im-inst rv32imp-inst hazards-rv32imp clean
