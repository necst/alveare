
KERNEL ?= alveare
KERNEL_NAME ?= alveare_v2
BENCHMARK ?= poweren
AXI_MODE ?= lite
CORE_NR ?= 1
ifeq ($(AXI_MODE), lite)
    DRIVER_NAME :=lite
    CORE_NAME :=alveare_core_ip_v1_0
else
    DRIVER_NAME :=master_one
    CORE_NAME :=alveare_${CORE_NR}_core
endif

## RTL src related
dtype_entities := $(wildcard $(CORE_DIR)/data_types/*.vhd)
ents_entities := $(wildcard $(CORE_DIR)/*.vhd)
tb_entities := $(wildcard $(TB_DIR)/*.vhd)
axi_lite_entities := $(wildcard $(AXI_DIR)/lite/*.vhd)
###################################################################
#Compiler related src
compiler_src := $(wildcard $(COMPILER_DIR)/ast.*)
compiler_src += $(wildcard $(COMPILER_DIR)/compiler.*)
###################################################################
# IP/Top/xo related stuffs
IP_REPO ?= $(BUILD_DIR)/ip_repo
PORT_NR ?= 1
VIVADO_IP_SCRIPT := $(TOP)/src/scripts/$(TRGT_PLATFORM)/building/ip_creation.tcl
CURR_CONFIG=${AXI_MODE}_${CORE_NR}_${PORT_NR}

##############################################################
#Target boards 

TRGT_PLATFORM ?= ultra_96
GENERIC_TRGT_PLATFORM ?=zynq

SUPPORTED_ZYNQ_MPSOC=( ultra_96 )

ifneq ($(filter $(TRGT_PLATFORM),$(SUPPORTED_ZYNQ_MPSOC)),)
    $(info $(TRGT_PLATFORM) exists in $(SUPPORTED_ZYNQ_MPSOC))
    GENERIC_TRGT_PLATFORM=zynq_mpsoc
else
    $(info $(TRGT_PLATFORM) not supported)
    GENERIC_TRGT_PLATFORM=
endif

##############################################################
