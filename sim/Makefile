#TBNAME      ?= rv32im_pipeline
#TOP         := $(TBNAME)
#
#CC  = gcc-11
#CXX = g++-11
#
#FILELIST_DIR := filelists
#LOG_DIR      := logs
#
#VERILATOR    := verilator
#
#all: build run
#
#build:
#	mkdir -p $(LOG_DIR)
#	$(VERILATOR) \
#	    --cc -f $(FILELIST_DIR)/$(TBNAME).f \
#	    --top-module $(TOP) \
#	    --exe sim_main.cpp \
#	    --build \
#	    -Wno-fatal | tee $(LOG_DIR)/compile_$(TBNAME).log
#
#run:
#	./obj_dir/V$(TOP) | tee $(LOG_DIR)/run_$(TBNAME).log
#
#clean:
#	rm -rf obj_dir
#	rm -rf $(LOG_DIR)
#
#help:
#	@echo ""
#	@echo "****************************************"
#	@echo "** make build TBNAME=rv32im_pipeline"
#	@echo "** make run"
#	@echo "** make all"
#	@echo "** make clean"
#	@echo "****************************************"
#	@echo ""
#
###########################################
# For questasim
###########################################

TBNAME	    ?=
TESTNAME    ?=	$(TBNAME)
RADIX	    ?=	hexadecimal
IMEM	    ?=
DMEM	    ?=	none
GOLDEN	    ?=
RESULT	    ?=	../sw/$(TESTNAME)/result.hex
SIG_WORDS   ?=	1
SIG_ADDR    ?=	80010000

FILELIST_DIR	:=  filelists
LOG_DIR		:=  logs
WAVE_DIR	:=  waves

all: build run

build:
	mkdir -p $(FILELIST_DIR) $(LOG_DIR)
	vlib work
	vlog -work work -f $(FILELIST_DIR)/tb_$(TBNAME).f | tee $(LOG_DIR)/compile_$(TBNAME).log
#vlog -work work -f $(FILELIST_DIR)/tb_$(TBNAME).f | tee $(LOG_DIR)/compile_$(TBNAME).log

run:
	vsim -voptargs=+acc -debugDB -c tb_$(TBNAME) -l $(LOG_DIR)/$(TESTNAME).log -do "log -r /*; run -all; quit"

run_signature:
	mkdir -p $(LOG_DIR)
	vsim -voptargs=+acc -debugDB -c tb_$(TBNAME) -l $(LOG_DIR)/$(TESTNAME).log \
	    +IMEM=$(IMEM) +DMEM=$(DMEM) +GOLDEN=$(GOLDEN) +RESULT=$(RESULT) +SIG_WORDS=$(SIG_WORDS) +SIG_ADDR=$(SIG_ADDR) \
	    -do "log -r /*; run -all; quit"

rv32i-inst:
	$(MAKE) -C ../sw/rv32i-inst-test
	$(MAKE) build TBNAME=rv32im_signature
	$(MAKE) run_signature TBNAME=rv32im_signature TESTNAME=rv32i-inst \
	    IMEM=../sw/rv32i-inst-test/rv32i_imem.hex \
	    DMEM=../sw/rv32i-inst-test/rv32i_dmem.hex \
	    GOLDEN=../sw/rv32i-inst-test/golden.hex \
	    RESULT=../sw/rv32i-inst-test/result.hex \
	    SIG_WORDS=28

rv32im-inst:
	$(MAKE) -C ../sw/rv32im-inst-test
	$(MAKE) build TBNAME=rv32im_signature
	$(MAKE) run_signature TBNAME=rv32im_signature TESTNAME=rv32im-inst \
	    IMEM=../sw/rv32im-inst-test/rv32im_imem.hex \
	    DMEM=../sw/rv32im-inst-test/rv32im_dmem.hex \
	    GOLDEN=../sw/rv32im-inst-test/golden.hex \
	    RESULT=../sw/rv32im-inst-test/result.hex \
	    SIG_WORDS=17

rv32imp-inst:
	$(MAKE) -C ../sw/rv32imp-inst-test
	$(MAKE) build TBNAME=rv32imp_signature
	$(MAKE) run_signature TBNAME=rv32imp_signature TESTNAME=rv32imp-inst \
	    IMEM=../sw/rv32imp-inst-test/rv32imp_imem.hex \
	    DMEM=../sw/rv32imp-inst-test/rv32imp_dmem.hex \
	    GOLDEN=../sw/rv32imp-inst-test/golden.hex \
	    RESULT=../sw/rv32imp-inst-test/result.hex \
	    SIG_WORDS=34

hazards-rv32imp:
	$(MAKE) -C ../sw/hazards-rv32imp-test
	$(MAKE) build TBNAME=rv32imp_signature
	$(MAKE) run_signature TBNAME=rv32imp_signature TESTNAME=hazards-rv32imp \
	    IMEM=../sw/hazards-rv32imp-test/hazards_rv32imp_imem.hex \
	    DMEM=../sw/hazards-rv32imp-test/hazards_rv32imp_dmem.hex \
	    GOLDEN=../sw/hazards-rv32imp-test/golden.hex \
	    RESULT=../sw/hazards-rv32imp-test/result.hex \
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
	@echo "** make rv32i-inst                   : build/run RV32I signature test"
	@echo "** make rv32im-inst                  : build/run RV32IM signature test"
	@echo "** make rv32imp-inst                 : build/run RV32IMP signature test"
	@echo "** make hazards-rv32imp              : build/run integrated hazard test"
	@echo "** make all                          : build + run"
	@echo "** make wave TESTNAME=x              : open waveform"
	@echo "** make clean                        : clean sim outputs"
	@echo "****************************************"
	@echo ""
