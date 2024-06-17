#TCL for project creation

# if {$argc < 4} {
#   puts "Expected: <prj_root> <proj name> <proj dir> <freq>"
#   exit
# }
if {$argc < 7} {
  puts "Expected: <prj_root> <proj name> <proj dir> <ip_dir> <freq> <core_nr> <core_name> <wrapper_name>"
  exit
}


proc add_axi_lite_core {core_number trgt_freq core_name} \
{
    set axi_port [expr ${core_number} + 2]
    set axi_master_ultra_pr 2
    set axi_master [expr ${core_number} % $axi_master_ultra_pr]
    puts "\[INFO\] TCL-19 Axi port: ${axi_port} and core_nr ${core_number}"

    #create_bd_cell -type module -reference alveare_core_ip_v1_0 alveare_core_ip_v1_0_0
    create_bd_cell -type module -reference ${core_name} ${core_name}_${core_number}

    #set_property -dict [list CONFIG.PSU__USE__S_AXI_GP${axi_port} {1}] [get_bd_cells zynq_ultra_ps_e_0]

    set clk "/zynq_ultra_ps_e_0/pl_clk0 (${trgt_freq} MHz)"

    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [list Master /zynq_ultra_ps_e_0/M_AXI_HPM${axi_master}_FPD intc_ip {New AXI Interconnect} Clk_xbar {Auto} Clk_master {Auto} Clk_slave {Auto} ]  [get_bd_intf_pins ${core_name}_${core_number}/s00_axi]

    create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_${core_number}
    set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Enable_32bit_Address {false} CONFIG.Use_Byte_Write_Enable {false} CONFIG.Byte_Size {9} CONFIG.Write_Depth_A {16384} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {128} CONFIG.Read_Width_B {128} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Use_RSTA_Pin {false} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.use_bram_block {Stand_Alone} CONFIG.EN_SAFETY_CKT {false}] [get_bd_cells blk_mem_gen_${core_number}]
    connect_bd_net [get_bd_pins blk_mem_gen_${core_number}/addra] [get_bd_pins ${core_name}_${core_number}/BRAM_WADDR_A]
    connect_bd_net [get_bd_pins blk_mem_gen_${core_number}/dina] [get_bd_pins ${core_name}_${core_number}/BRAM_DATA_OUT_A]
    connect_bd_net [get_bd_pins blk_mem_gen_${core_number}/wea] [get_bd_pins ${core_name}_${core_number}/BRAM_WE]
    connect_bd_net [get_bd_pins blk_mem_gen_${core_number}/addrb] [get_bd_pins ${core_name}_${core_number}/BRAM_RADDR_B]
    connect_bd_net [get_bd_pins blk_mem_gen_${core_number}/doutb] [get_bd_pins ${core_name}_${core_number}/BRAM_DATA_IN_B]
    connect_bd_net [get_bd_pins blk_mem_gen_${core_number}/clkb] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
    connect_bd_net [get_bd_pins blk_mem_gen_${core_number}/clka] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]

}


#consider to add axi folder or whatever
# pull cmdline variables to use during setup
set prj_root  [lindex $argv 0]
set prj_root_build "$prj_root/build/ultra-96"
set prj_root_core "$prj_root/src/hw/core"
set prj_root_core_data_types "$prj_root_core/data_types"
set prj_name [lindex $argv 1]
set prj_dir [lindex $argv 2]
#set trgt_freq [lindex $argv 3]

set ip_dir [lindex $argv 3]
set trgt_freq [lindex $argv 4]
set core_nr [lindex $argv 5]
#set core_nr 7
set core_name [lindex $argv 6]
#set core_name alveare_core_ip_v1_0
set wrapper_name [lindex $argv 7]
#set wrapper_name "alveare"
puts "\[TCL INFO\] Core Name $core_name"
puts "\[TCL INFO\] Block Design and wrapper name $wrapper_name"
if {$core_nr > 32} {
    puts "\[TCL Error\] cannot handle more than 32 core"
    exit
}


# fixed for platform
set prj_part "xczu3eg-sbva484-1-i"

set prj_top "$prj_root/src/hw/axi_interface/lite"
#set xdc_dir "$prj_root/src/scripts/ultra_96/building"

# set up project
create_project -force $prj_name $prj_dir -part $prj_part

# built-in command from vivado
set vvd_version [version -short]
set vvd_version_split [split $vvd_version "."]
#vivado version year
set vvd_vers_year [lindex $vvd_version_split 0] 

#
update_ip_catalog
#set_property target_language VHDL [current_project]
set_property board_part avnet.com:ultra96v2:part0:1.1 [current_project]

# add the vhdl core implementation files
add_files -norecurse $prj_root_core
add_files -norecurse $prj_top
add_files -norecurse $prj_root_core_data_types
import_files -force -norecurse
update_compile_order -fileset sources_1

#Add Ultra96 XDC

# create block design
create_bd_design "${wrapper_name}"

# source "${xdc_dir}/ultra96.tcl"
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
set clkdiv [expr { int(round(1500.0/$trgt_freq)) }]
set_property -dict [list CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR0 $clkdiv] [get_bd_cells zynq_ultra_ps_e_0]
set actual_freq [get_property CONFIG.FREQ_HZ [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] ]
set actual_freq_mhz [expr $actual_freq / 1000000]
puts ""
puts ""
puts "***********************************************************************"
puts "\[UTILS\] Targeting ${trgt_freq} MHz getting ${actual_freq_mhz} MHz "
puts "***********************************************************************"
puts ""
puts ""
puts ""


# enable AXI HP ports, set target frequency
#set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1} CONFIG.PSU__USE__S_AXI_GP2 {1}] [get_bd_cells zynq_ultra_ps_e_0]
#set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1} CONFIG.PSU__USE__S_AXI_GP4 {1} CONFIG.PSU__USE__S_AXI_GP5 {1}] [get_bd_cells zynq_ultra_ps_e_0]
#set_property -dict [list CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} CONFIG.PSU__USE__S_AXI_GP4 {1} CONFIG.PSU__SAXIGP4__DATA_WIDTH {128} CONFIG.PSU__SAXIGP5__DATA_WIDTH {128}] [get_bd_cells zynq_ultra_ps_e_0]

set_property -dict [list CONFIG.PSU__USE__S_AXI_GP2 {0}] [get_bd_cells zynq_ultra_ps_e_0]
#instantiate alveare
for {set i 0} {$i < $core_nr} {incr i} {
    puts $i
    add_axi_lite_core $i $actual_freq_mhz $core_name
}
save_bd_design

if {$core_nr == 1} {
    set clk "/zynq_ultra_ps_e_0/pl_clk0 (${actual_freq_mhz} MHz)"
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [list Clk_master {Auto} Clk_slave $clk Clk_xbar $clk Master /zynq_ultra_ps_e_0/M_AXI_HPM1_FPD Slave /${core_name}_0/s00_axi intc_ip {/ps8_0_axi_periph} master_apm {0}]  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
}
# make the block design look prettier
regenerate_bd_layout
validate_bd_design
save_bd_design

# create HDL wrapper
make_wrapper -files [get_files $prj_dir/$prj_name.srcs/sources_1/bd/${wrapper_name}/${wrapper_name}.bd] -top
add_files -norecurse $prj_dir/$prj_name.srcs/sources_1/bd/${wrapper_name}/hdl/${wrapper_name}_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property source_mgmt_mode None [current_project]
set_property top ${wrapper_name}_wrapper [current_fileset]
set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1

set_property strategy Flow_PerfOptimized_high [get_runs synth_1]

set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AlternateRoutability [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AlternateCLBRouting [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap [get_runs impl_1]
# do not ignore failure-level VHDL assertions
set_param synth.elaboration.rodinMoreOptions {rt::set_parameter ignoreVhdlAssertStmts false}

# generate tcl for PYNQ, used to set fclk
write_bd_tcl $prj_dir/${wrapper_name}_wrapper.tcl
# launch bitstream generation
#launch_runs impl_1 -to_step write_bitstream -jobs 4
close_project
#wait_on_run impl_1
