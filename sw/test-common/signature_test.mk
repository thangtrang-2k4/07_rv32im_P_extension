CROSS ?= riscv32-unknown-elf
CC := $(CROSS)-gcc
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump

TEST ?= test
PREFIX ?= $(TEST)
SRC ?= $(TEST).S
MARCH ?= rv32im
LINKER ?= ../test-common/link.ld

CFLAGS ?= -nostdlib -nostartfiles -ffreestanding -march=$(MARCH) -mabi=ilp32
LDFLAGS ?= -T $(LINKER)

all: $(PREFIX)_imem.hex $(PREFIX)_dmem.hex $(PREFIX).dump

$(PREFIX).elf: $(SRC) $(LINKER)
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRC) -o $@

$(PREFIX)_imem.hex: $(PREFIX).elf
	$(OBJCOPY) -O verilog --only-section=.text --verilog-data-width=4 $< $@

$(PREFIX)_dmem.hex: $(PREFIX).elf
	$(OBJCOPY) -O verilog \
	    --only-section=.signature --only-section=.rodata --only-section=.data --only-section=.bss \
	    --verilog-data-width=4 $< $@

$(PREFIX).dump: $(PREFIX).elf
	$(OBJDUMP) -d $< > $@

clean:
	rm -f $(PREFIX).elf $(PREFIX).dump $(PREFIX)_imem.hex $(PREFIX)_dmem.hex result.hex

.PHONY: all clean
