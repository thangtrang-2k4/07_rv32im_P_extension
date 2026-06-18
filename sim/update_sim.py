import os

filelists_dir = 'd:/01_Projects/2025-12_Graduation_Thesis/02-rv32im-pext/sim/filelists'

with open(os.path.join(filelists_dir, 'tb_rv32im_pipeline.f'), 'r') as f:
    im_f = f.read()
im_f = im_f.replace('../tb/tb_rv32im_pipeline.sv', '+incdir+../tb/rv32im\n../tb/rv32im/tb_top.sv')
with open(os.path.join(filelists_dir, 'tb_rv32im_oop.f'), 'w') as f:
    f.write(im_f)

with open(os.path.join(filelists_dir, 'tb_rv32imp_pipeline.f'), 'r') as f:
    imp_f = f.read()
imp_f = imp_f.replace('../tb/tb_rv32imp_pipeline.sv', '+incdir+../tb/rv32imp\n../tb/rv32imp/tb_top.sv')
with open(os.path.join(filelists_dir, 'tb_rv32imp_oop.f'), 'w') as f:
    f.write(imp_f)

print('Created OOP filelists.')

# Append run-app to Makefile
makefile_path = 'd:/01_Projects/2025-12_Graduation_Thesis/02-rv32im-pext/sim/Makefile'
with open(makefile_path, 'r') as f:
    mk = f.read()

if 'run-app:' not in mk:
    with open(makefile_path, 'a') as f:
        f.write('''
# ======================================================================
# OOP Testbench Run Targets
# ======================================================================
APP ?= filter-fir
CORE ?= rv32im

ifeq ($(APP), filter-fir)
  DEPTH = 100
  OADDR = 800101b0
else ifeq ($(APP), filter-sobel)
  DEPTH = 1024
  OADDR = 80011000
else ifeq ($(APP), matrix-multiplication)
  DEPTH = 1024
  OADDR = 80010804
endif

PREFIX = $(ifeq ($(CORE),rv32imp)pext$(else)scala$(endif))
IMEM_PATH = ../sw/apps/$(APP)/scala_imem.hex
DMEM_PATH = ../sw/apps/$(APP)/scala_dmem.hex
GOLDEN_PATH = ../sw/apps/$(APP)/scala_goldenw.hex
RESULT_PATH = ../sw/apps/$(APP)/scala_signature.hex

run-app:
	$(MAKE) build TBNAME=$(CORE)_oop
	mkdir -p $(LOG_DIR)
	vsim -voptargs=+acc -debugDB -c tb_top -l $(LOG_DIR)/oop_$(CORE)_$(APP).log \\
	    +IMEM=$(IMEM_PATH) +DMEM=$(DMEM_PATH) +GOLDEN=$(GOLDEN_PATH) +RESULT=$(RESULT_PATH) +DEPTH=$(DEPTH) +OADDR=$(OADDR) \\
	    -do "log -r /*; run -all; quit"
''')
    print('Appended run-app to Makefile.')
else:
    print('run-app already exists in Makefile.')
