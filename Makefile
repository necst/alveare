#makefile for generic builds
#path where to look for modified prerequisite
VPATH = src/hw/core:src/hw/core/data_types:src/hw/testbench

#######################################################
include platforms/configuration_parameters.mk
#######################################################
# target frequency for Vivado FPGA synthesis in MHz
FREQ_MHZ ?= 150.0
# controls whether Vivado will run in command-line or GUI mode
VIVADO_MODE ?= batch # or gui
# which C++ compiler to use
CC = g++
# scp/rsync target to copy files to board
TRGT_PLATFORM ?= ultra_96
URI = $($(TRGT_PLATFORM)_URI)
VIVADO_VERSION = 2019.2
# internal build dirs and names for the Makefile
TOP ?= $(shell readlink -f .)
VIVADO_IN_PATH := $(shell command -v vivado 2> /dev/null)
KERNEL ?= alveare

KERNEL_NAME ?= Alveare_kernel

JOBS_HW =2

#################################################################
#build related
BUILD_DIR ?= $(TOP)/build
CURR_BUILD_DIR ?= $(BUILD_DIR)/$(TRGT_PLATFORM)/$(CURR_CONFIG)
DEPLOY_DIR := $(CURR_BUILD_DIR)/deploy
#########################################################
#scripts
SCRIPT_DIR ?= $(TOP)/src/scripts
VIVADO_SCRIPT_DIR := $(TOP)/src/scripts/$(TRGT_PLATFORM)/building
########################################################################
# Software related stuffs
SW_DIR ?= $(TOP)/src/sw
COMPILER_DIR ?= $(SW_DIR)/compiler

NEED_VIVADO = all analyze% test_% synth_%
#ZSH_IN_PATH := $(shell command -v zsh 2> /dev/null)

# RTL related stuffs
HW_DIR ?= $(TOP)/src/hw
AXI_DIR ?= $(HW_DIR)/axi_interface
CORE_DIR ?= $(HW_DIR)/core
TB_DIR ?= $(HW_DIR)/testbench

#first rule executed when "make"
#@ starting line don't print makefile recipe
help:
	@echo ""
	@echo "*****************************************************"
	@echo "*****************************************************"
	@echo "*****************************************************"
	@echo "**********  BUILDING HELPER  ************************"
	@echo "*****************************************************"
	@echo "*****************************************************"
	@echo "*****************************************************"
	@echo ""
	@echo "test% will prepare, analyze and simulate pre and post synthesis"
	@echo ""
	@echo "*****************************************************"
	@echo ""
	@echo "presyntest% will simulate in presynthesis, while "
	@echo "postsyntest% will synthesize and simulate just post"
	@echo ""
	@echo "*****************************************************"
	@echo ""
	@echo "analyze% will vhdl syntax of a file"
	@echo ""
	@echo "*****************************************************"
	@echo ""
	@echo "all will build hw, sw driver and scripts ready to deploy"
	@echo "the whole infrastructure "
	@echo ""
	@echo "*****************************************************"
	@echo ""
	@echo "clean will clean just current build project directory"
	@echo ""
	@echo "*****************************************************"
	@echo ""
	@echo "cleanall will clean everything in the build directory"
	@echo ""
	@echo "*****************************************************"
	@echo ""
	@echo "cleantest will clean all testbenches folder"
	@echo ""
	@echo "*****************************************************"
	@echo ""
	@echo "*****************************************************"
	@echo "'make clean' clean everything inside the platform related directory"
	@echo ""
	@echo "'make cleanall' clean everything inside build directory"
	@echo ""
	@echo "'make cleanip' clean ip repo related to the platform"
	@echo "*****************************************************"
	@echo ""
	@make platforms
	@make helplat

########################
# platform-specific Makefile include for bitfile synthesis
include platforms/$(TRGT_PLATFORM).mk

# note that all targets are phony targets, no proper dependency tracking
.PHONY: script rsync clean help cleanall platforms presyntest%

check_vivado:
ifndef VIVADO_IN_PATH
	ifneq($@, NEED_VIVADO)
		$(error "vivado not found in path")
endif


platforms:
	@echo "*******************************************"
	@echo "**********POSSIBLE PLATFORMS***************"
	@echo "*******************************************"
	@echo " "
	@echo "TRGT_PLATFORM ?= ultra_96 "
	@echo " "
	@echo "*******************************************"
	@echo "*******************************************"
#check_zsh:
#ifndef ZSH_IN_PATH
#    $(error "zsh not in path; needed by oh-my-xilinx for characterization")
#endif

# get everything ready to copy onto the platform and create a deployment folder
all: |check_vivado hw sw script

test%: |check_vivado presyntest% postsyntest% %.vhd %_tb.vhd
	@echo " ***** EXTRACTING STATS FOR $* ***** "
	$(TOP)/misc/verification/extractStats.bash  $(BUILD_DIR)/test_$* $*
	cat $(BUILD_DIR)/test_$*/log/final_stats.log
	@echo " ***** END OF STATS $* ***** "

%.vhd:
	@echo "analyzing $*"

%_tb.vhd:
	@echo "analyzing $*"

presyntest%: check_vivado prep_%  %.vhd %_tb.vhd
	mkdir -p $(BUILD_DIR)/test_$*/log/orig/tb
	@echo " ***** RUNNING TESTS FOR $* ***** "
	cd $(BUILD_DIR)/test_$*
	@echo "***** PRE-SYNTH SIMULATION STARTED *****"
	$(TOP)/misc/verification/sim_pre_synth.bash $(BUILD_DIR) $* $(CORE_DIR) $(SCRIPT_DIR)
	@echo "***** PRE-SYNTH SIMULATION CONCLUDED *****"
	cp -r xsim.dir $(BUILD_DIR)/test_$*/log/orig/tb
	@rm -f webtalk*
	@echo " ***** END OF TESTS FOR $* ***** "
	cd $(TOP) 
	mv *.wdb $(BUILD_DIR)/test_$*/log/orig/tb
	rm -f *.pb
	rm -rf x*
	rm -f vivado*

postsyntest%: |check_vivado synth% %.vhd %_tb.vhd
	mkdir -p $(BUILD_DIR)/test_$*/log/synth/tb
	@echo " ***** RUNNING TESTS FOR $* ***** "
	cd $(BUILD_DIR)/test_$*
	@echo "***** POST-SYNTH SIMULATION STARTED *****"
	$(TOP)/misc/verification/sim_post_synth.bash $(BUILD_DIR) $* $(CORE_DIR) $(SCRIPT_DIR)
	@echo "***** POST-SYNTH SIMULATION CONCLUDED *****"
	cp -r xsim.dir $(BUILD_DIR)/test_$*/log/orig/tb
	@rm -f webtalk*
	@echo " ***** END OF TESTS FOR $* ***** "
	cd $(TOP)
	mv *.wdb $(BUILD_DIR)/test_$*/log/synth/tb
	rm -f *.pb
	rm -rf x*
	rm -f vivado*


synth%: check_vivado prep_% %.vhd 
	mkdir -p $(BUILD_DIR)/test_$*/vhdl/synth
	mkdir -p $(BUILD_DIR)/test_$*/log/synth
	bash $(SCRIPT_DIR)/dependency_synthesizer.bash $(CORE_DIR) $* $(BUILD_DIR)/test_$*/vhdl/orig
	#bash $(SCRIPT_DIR)/dependency_synthesizer.bash $(CORE_DIR) $*_tb: $(BUILD_DIR)/test_$*/vhdl/synth
	cd $(BUILD_DIR)/test_$*
	@echo " ***** START SYNTHESYS ***** "
	vivado -mode batch -source $(TOP)/misc/verification/viv_syn.tcl -tclargs $(TOP) $* $(BUILD_DIR)/test_$* 200.0 $*
	mv vivado.log $(BUILD_DIR)/test_$*/log/vivado_synth.log
	@echo " ***** END SYNTHESYS ***** "
	cd $(TOP)
	rm -r vivado*

prep_%: warning%
	mkdir -p $(BUILD_DIR)/test_$*
	mkdir -p $(BUILD_DIR)/test_$*/log
	mkdir -p $(BUILD_DIR)/test_$*/log/orig
	mkdir -p $(BUILD_DIR)/test_$*/vhdl
	mkdir -p $(BUILD_DIR)/test_$*/vhdl/orig
	cp -f $(TOP)/misc/verification/constr.xdc $(BUILD_DIR)/test_$*/log
	cp -f $(TB_DIR)/$*_tb.vhd $(BUILD_DIR)/test_$*/vhdl/orig/
	cp -f $(CORE_DIR)/$*.vhd $(BUILD_DIR)/test_$*/vhdl/orig/

warning%:
	@echo ""
	@echo ""
	@echo "********************************************************************"
	@echo ""
	@echo "WATCH OUT: File and Tesbench must obey convention: $*.vhd $*_tb.vhd"
	@echo ""
	@echo "Also when importing libraries start library name with lower case and"
	@echo "Pack with the uppercase "
	@echo ""
	@echo "********************************************************************"
	@echo ""
	@echo ""

#consider to use a depency analysis also for libraries instead of hard coding	
analyze%: check_vivado warning%
	mkdir -p $(BUILD_DIR)/analyze$*;\
	cd $(BUILD_DIR)/analyze$*;\
	xvhdl $(CORE_DIR)/data_types/genericsDefPack.vhd;\
	xvhdl $(CORE_DIR)/data_types/typesDefPack.vhd;\
	xvhdl $(CORE_DIR)/data_types/opcodeDefPack.vhd;\
	xvhdl $(CORE_DIR)/data_types/stackDefPack.vhd;\
	xvhdl $(CORE_DIR)/data_types/dataRecordType.vhd;\
	bash $(SCRIPT_DIR)/dependency_analysis.bash $(CORE_DIR) $*

# copy scripts to the deployment folder
script:
	mkdir -p $(DEPLOY_DIR); cp $(SCRIPT_DIR)/$(TRGT_PLATFORM)/target/* $(DEPLOY_DIR)/
# remove everything that is built
clean:
	rm -rf $(CURR_BUILD_DIR)
# remove everthing for that platform
cleanall: clean cleantest cleananlyze
	rm -rf $(BUILD_DIR)/*
#remove testbench folders
cleantest:
	rm -rf $(BUILD_DIR)/test_*
cleananlyze::
	rm -rf $(BUILD_DIR)/analyze*

cleanip:
	rm -rf $(IP_REPO)

cleandeploy:
	rm -rf $(DEPLOY_DIR)

helptargets:
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "                 Target platforms helpers               "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [HELP] Currently using Vivado version $(VIVADO_VERSION)"
	@echo ""
	@echo " [HELP] Supported Zynq boards: $(SUPPORTED_ZYNQ)"
	@echo ""
	@echo " [HELP] add TRGT_PLATFORM=<one_of_the_previous_platform> to a command"
	@echo " [HELP] For example 'make TRGT_PLATFORM=ultra_96 N_CORE=2'"
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "               END of Target platforms helpers                   "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
