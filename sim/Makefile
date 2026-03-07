TBNAME      ?= rv32im_pipeline
TOP         := $(TBNAME)

CC  = gcc-11
CXX = g++-11

FILELIST_DIR := filelists
LOG_DIR      := logs

VERILATOR    := verilator

all: build run

build:
	mkdir -p $(LOG_DIR)
	$(VERILATOR) \
	    --cc -f $(FILELIST_DIR)/$(TBNAME).f \
	    --top-module $(TOP) \
	    --exe sim_main.cpp \
	    --build \
	    -Wno-fatal | tee $(LOG_DIR)/compile_$(TBNAME).log

run:
	./obj_dir/V$(TOP) | tee $(LOG_DIR)/run_$(TBNAME).log

clean:
	rm -rf obj_dir
	rm -rf $(LOG_DIR)

help:
	@echo ""
	@echo "****************************************"
	@echo "** make build TBNAME=rv32im_pipeline"
	@echo "** make run"
	@echo "** make all"
	@echo "** make clean"
	@echo "****************************************"
	@echo ""

###########################################
# For questasim
###########################################

#TBNAME	    ?=
#TESTNAME    ?=	$(TBNAME)
#RADIX	    ?=	hexadecimal
#
#FILELIST_DIR	:=  filelists
#LOG_DIR		:=  logs
#WAVE_DIR	:=  waves
#
#all: build run
#
#build:
#	mkdir -p $(FILELIST_DIR) $(LOG_DIR)
#	vlib work
#	vmap work work
#	vlog -f $(FILELIST_DIR)/tb_$(TBNAME).f | tee $(LOG_DIR)/compile_$(TBNAME).log
#
#run:
#	vsim -voptargs=+acc -debugDB -c tb_$(TBNAME) -l $(LOG_DIR)/$(TESTNAME).log -do "log -r /*; run -all; quit"
#
#wave:
#	vsim -i -view vsim.wlf -do "add wave -r /*; radix -$(RADIX)" &
#
#clean:
#	rm -rf work
#	rm -rf vsim.dbg
#	rm -rf *.ini
#	rm -rf $(LOG_DIR)/*
#	rm -rf *.wlf
#	rm -rf transcript
#
#help:
#	@echo ""
#	@echo "****************************************"
#	@echo "** make build                         : compile RTL + TB"
#	@echo "** make run TBNAME=tb_x TESTNAME=x  : run specific test"
#	@echo "** make all                          : build + run"
#	@echo "** make wave TESTNAME=x              : open waveform"
#	@echo "** make clean                        : clean sim outputs"
#	@echo "****************************************"
#	@echo ""
