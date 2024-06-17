if {$argc != 5} {
  puts "Expected: <project_to_synthesize> <prj_dir> <prj_name> <top> <jobs>"
  exit
}

set prj_dir [lindex $argv 1]
set prj_name [lindex $argv 2]
set top [lindex $argv 3]
set jobs [lindex $argv 4]

open_project [lindex $argv 0]
launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1


set vvd_version [version -short]
set vvd_version_split [split $vvd_version "."]
set vvd_vers_year [lindex $vvd_version_split 0]
if {$vvd_vers_year < 2019} {
  file copy -force $prj_dir/$prj_name.runs/impl_1/$top.sysdef $prj_dir/$top.hdf
} else {
  write_hw_platform -fixed -force  -include_bit -file $prj_dir/$top.xsa
}