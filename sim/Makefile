# ======================================================================
# Makefile - QuestaSim testcase runs
#
# Usage:
#   make rv32i-inst        -> run RV32I signature test
#   make rv32im-inst       -> run RV32IM signature test
#   make rv32imp-inst      -> run RV32IMP signature test
#   make hazards-rv32imp   -> run integrated hazard test
# ======================================================================

TBNAME	    ?=
TESTNAME    ?=	$(TBNAME)
RADIX	    ?=	hexadecimal
IMEM	    ?=
DMEM	    ?=	none
GOLDEN	    ?=
RESULT	    ?=	../sw/tests/$(TESTNAME)/result.hex
SIG_WORDS   ?=	1
SIG_ADDR    ?=	80010000

FILELIST_DIR	:=  filelists
LOG_DIR		:=  logs

all: rv32i-inst rv32im-inst rv32imp-inst hazards-rv32imp

build:
	mkdir -p $(FILELIST_DIR) $(LOG_DIR)
	vlib work

	vlog -work work -f $(FILELIST_DIR)/tb_$(TBNAME).f | tee $(LOG_DIR)/compile_$(TBNAME).log

run:
	vsim -voptargs=+acc -debugDB -c tb_$(TBNAME) -l $(LOG_DIR)/$(TESTNAME).log -do "log -r /*; run -all; quit"

run_signature:
	mkdir -p $(LOG_DIR)
	vsim -voptargs=+acc -debugDB -c tb_$(TBNAME) -l $(LOG_DIR)/$(TESTNAME).log \
	    +IMEM=$(IMEM) +DMEM=$(DMEM) +GOLDEN=$(GOLDEN) +RESULT=$(RESULT) +SIG_WORDS=$(SIG_WORDS) +SIG_ADDR=$(SIG_ADDR) \
	    -do "log -r /*; run -all; quit"

rv32i-inst:
	$(MAKE) build TBNAME=rv32im_signature
	$(MAKE) run_signature TBNAME=rv32im_signature TESTNAME=rv32i-inst \
	    IMEM=../sw/tests/rv32i-inst-test/rv32i_imem.hex \
	    DMEM=../sw/tests/rv32i-inst-test/rv32i_dmem.hex \
	    GOLDEN=../sw/tests/rv32i-inst-test/golden.hex \
	    RESULT=../sw/tests/rv32i-inst-test/result.hex \
	    SIG_WORDS=28

rv32im-inst:
	$(MAKE) build TBNAME=rv32im_signature
	$(MAKE) run_signature TBNAME=rv32im_signature TESTNAME=rv32im-inst \
	    IMEM=../sw/tests/rv32im-inst-test/rv32im_imem.hex \
	    DMEM=../sw/tests/rv32im-inst-test/rv32im_dmem.hex \
	    GOLDEN=../sw/tests/rv32im-inst-test/golden.hex \
	    RESULT=../sw/tests/rv32im-inst-test/result.hex \
	    SIG_WORDS=17

rv32imp-inst:
	$(MAKE) build TBNAME=rv32imp_signature
	$(MAKE) run_signature TBNAME=rv32imp_signature TESTNAME=rv32imp-inst \
	    IMEM=../sw/tests/rv32imp-inst-test/rv32imp_imem.hex \
	    DMEM=../sw/tests/rv32imp-inst-test/rv32imp_dmem.hex \
	    GOLDEN=../sw/tests/rv32imp-inst-test/golden.hex \
	    RESULT=../sw/tests/rv32imp-inst-test/result.hex \
	    SIG_WORDS=34

hazards-rv32imp:
	$(MAKE) build TBNAME=rv32imp_signature
	$(MAKE) run_signature TBNAME=rv32imp_signature TESTNAME=hazards-rv32imp \
	    IMEM=../sw/tests/hazards-rv32imp-test/hazards_rv32imp_imem.hex \
	    DMEM=../sw/tests/hazards-rv32imp-test/hazards_rv32imp_dmem.hex \
	    GOLDEN=../sw/tests/hazards-rv32imp-test/golden.hex \
	    RESULT=../sw/tests/hazards-rv32imp-test/result.hex \
	    SIG_WORDS=25

wave:
	vsim -i -view vsim.wlf -do "add wave -r /*; radix -$(RADIX)" &

clean:
	rm -rf work
	rm -rf vsim.dbg
	rm -rf *.ini
	rm -rf $(LOG_DIR)/*
	rm -rf *.wlf
	rm -rf transcript

help:
	@echo ""
	@echo "****************************************"
	@echo "** make build                         : compile RTL + TB"
	@echo "** make run TBNAME=tb_x TESTNAME=x  : run specific test"
	@echo "** make rv32i-inst                   : run RV32I signature test"
	@echo "** make rv32im-inst                  : run RV32IM signature test"
	@echo "** make rv32imp-inst                 : run RV32IMP signature test"
	@echo "** make hazards-rv32imp              : run integrated hazard test"
	@echo "** make all                          : run all signature tests"
	@echo "** make wave TESTNAME=x              : open waveform"
	@echo "** make clean                        : clean sim outputs"
	@echo "****************************************"
	@echo ""

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
	vsim -voptargs=+acc -debugDB -c tb_top -l $(LOG_DIR)/oop_$(CORE)_$(APP).log \
	    +IMEM=$(IMEM_PATH) +DMEM=$(DMEM_PATH) +GOLDEN=$(GOLDEN_PATH) +RESULT=$(RESULT_PATH) +DEPTH=$(DEPTH) +OADDR=$(OADDR) \
	    -do "log -r /*; run -all; quit"
