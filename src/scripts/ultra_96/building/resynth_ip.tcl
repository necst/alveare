#TCL resynth OOC of ip

if {$argc != 5} {
  puts "Expected: <prj_root> <proj name> <proj dir> <krnl_name> <bd_name>"
  exit
}


#consider to add axi folder or whatever
# pull cmdline variables to use during setup
set prj_root  [lindex $argv 0]
set prj_root_build "$prj_root/build/ultra_96"
set prj_name [lindex $argv 1]
set prj_dir [lindex $argv 2]
set krnl_name [lindex $argv 3]
set bd_name [lindex $argv 4]

# fixed for platform
set prj_part "xczu3eg-sbva484-1-i"


# vivado prj related stuffs
set bd_obj "$prj_root_build/$prj_name/${prj_name}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd"
set sim_stuff "$prj_root_build/$prj_name/${prj_name}.cache/compile_simlib/"


open_project $prj_dir/${prj_name}.xpr

update_ip_catalog -rebuild -scan_changes
report_ip_status -return_string


upgrade_ip -vlnv user.org:user:${krnl_name}:1.0 [get_ips  ${bd_name}_${krnl_name}_0_0] -log ip_upgrade.log

export_ip_user_files -of_objects [get_ips ${bd_name}_${krnl_name}_0_0] -no_script -sync -force -quiet

generate_target all [get_files  $bd_obj]
catch { config_ip_cache -export [get_ips -all ${bd_name}_${krnl_name}_0_0] }
catch { config_ip_cache -export [get_ips -all ${bd_name}_auto_ds_0] }
catch { config_ip_cache -export [get_ips -all ${bd_name}_auto_pc_0] }

export_ip_user_files -of_objects [get_files $bd_obj] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $bd_obj]

launch_runs -jobs 3 ${bd_name}_${krnl_name}_0_0_synth_1
wait_on_run synth_1
export_simulation -of_objects [get_files $bd_obj] -directory $prj_root_build/$prj_name/${prj_name}.ip_user_files/sim_scripts -ip_user_files_dir $prj_root_build/$prj_name/${prj_name}.ip_user_files -ipstatic_source_dir $prj_root_build/$prj_name/${prj_name}.ip_user_files/ipstatic -lib_map_path [list {modelsim=$sim_stuff/modelsim} {questa=$sim_stuff/questa} {ies=$sim_stuff/ies} {xcelium=$sim_stuff/xcelium} {vcs=$sim_stuff/vcs}  {riviera=$sim_stuff/riviera}]  -use_ip_compiled_libs -force -quiet
