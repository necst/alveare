VIVADO_PRJNAME = ${KERNEL}-vivado
PRJDIR = $(CURR_BUILD_DIR)/$(VIVADO_PRJNAME)
BITSTREAM = $(PRJDIR)/$(VIVADO_PRJNAME).runs/impl_1/${KERNEL}_wrapper.bit
ifeq ($(AXI_MODE), lite)
	VVD_SCRIPT := $(VIVADO_SCRIPT_DIR)/create_vivado_project.tcl
endif
VVD_SYNTH_SCRIPT = $(VIVADO_SCRIPT_DIR)/synth_vivado_project.tcl
VVD_RESYNTH_OOC_SCRIPT := $(VIVADO_SCRIPT_DIR)/resynth_ip.tcl

.PHONY: hls hw gen_vivado_prj bitfile launch_vivado_gui sw helplat

# copy bitfile to the deployment folder, make an empty tcl script for bitfile loader
# added the hwh for the pynq os needs
hw: $(BITSTREAM)
	mkdir -p $(DEPLOY_DIR)
	cp $(BITSTREAM) $(DEPLOY_DIR)/${KERNEL}_wrapper.bit;\
	cp $(PRJDIR)/${KERNEL}_wrapper.tcl $(DEPLOY_DIR);\
	cp $(PRJDIR)/$(VIVADO_PRJNAME).srcs/sources_1/bd/$(KERNEL)/hw_handoff/$(KERNEL).hwh $(DEPLOY_DIR)/$(KERNEL)_wrapper.hwh 

hw_pre:
	mkdir -p $(DEPLOY_DIR)
	cp $(BITSTREAM) $(DEPLOY_DIR)/${KERNEL}_wrapper.bit; cp $(PRJDIR)/${KERNEL}_wrapper.tcl $(DEPLOY_DIR);\
	cp $(PRJDIR)/$(VIVADO_PRJNAME).srcs/sources_1/bd/$(KERNEL)/hw_handoff/$(KERNEL).hwh $(DEPLOY_DIR)/$(KERNEL)_wrapper.hwh 

# hw en, consider $(IP_REPO)
$(PRJDIR)/$(VIVADO_PRJNAME).xpr:
	vivado -mode $(VIVADO_MODE) -source $(VVD_SCRIPT) -tclargs $(TOP) $(VIVADO_PRJNAME) $(PRJDIR) $(IP_REPO) $(FREQ_MHZ) $(CORE_NR) $(CORE_NAME) $(KERNEL)

gen_vivado_prj:
	vivado -mode $(VIVADO_MODE) -source $(VVD_SCRIPT) -tclargs $(TOP) $(VIVADO_PRJNAME) $(PRJDIR) $(IP_REPO) $(FREQ_MHZ) $(CORE_NR) $(CORE_NAME) $(KERNEL)

bitfile:
	vivado -mode $(VIVADO_MODE) -source $(VVD_SYNTH_SCRIPT) -tclargs $(PRJDIR)/$(VIVADO_PRJNAME).xpr $(PRJDIR) $(VIVADO_PRJNAME) ${KERNEL}_wrapper

$(BITSTREAM): $(PRJDIR)/$(VIVADO_PRJNAME).xpr
	vivado -mode $(VIVADO_MODE) -source $(VVD_SYNTH_SCRIPT) -tclargs $(PRJDIR)/$(VIVADO_PRJNAME).xpr $(PRJDIR) $(VIVADO_PRJNAME) ${KERNEL}_wrapper ${JOBS_HW}

# launch Vivado in GUI mode with created project
launch_vivado_gui: $(PRJDIR)/$(VIVADO_PRJNAME).xpr
	vivado -mode gui $(PRJDIR)/$(VIVADO_PRJNAME).xpr

sw: 
	mkdir -p $(DEPLOY_DIR); cp $(PY_DIR)/* $(DEPLOY_DIR)/ ;
	cp $(COMPILER_DIR)/ast.* $(DEPLOY_DIR);
	cp $(COMPILER_DIR)/compiler.* $(DEPLOY_DIR);
	cp $(SCRIPT_DIR)/$(TRGT_PLATFORM)/target/deploy.mk $(DEPLOY_DIR)/Makefile ;
	cp $(SW_DIR)/tests/$(BENCHMARK)/* $(DEPLOY_DIR)/ ;
	
prepdeploy:
	mkdir -p $(DEPLOY_DIR)
	cp $(TOP)/platforms/$(GENERIC_TRGT_PLATFORM).mk $(DEPLOY_DIR)/Makefile
########################
helplat: 
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "                      Zynq Specific helper                     "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [INFO] 'make hw' create the bitstream, and copy it to be deployed"
	@echo " [INFO] 'make bitfile' create the bitstream after project creation"
	@echo " [INFO] 'make gen_vivado_prj' creation of the vivado project with all the sources"
	@echo " [INFO] 'make launch_vivado_gui ' launch vivado in gui mode after creating the project"
	@echo ""
	@echo " [INFO] 'make sw' copy all the necessary stuffs on sw deployment side"
	@echo ""
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "               END of Zynq Specific helper                     "
	@echo ""
	@echo "*****************************************************************"
########################
