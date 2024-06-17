#TCL for project creation
package require math::bignum

if {$argc < 3} {
  puts "Expected: <prj_root> <port number> <reg_config file>"
  exit
}
################################################################################################






proc add_registers {registers memory_map_name} {
    # {{{
    set memory_maps [ ipx::get_memory_maps -quiet -of_objects [ ipx::current_core ] ] 
    if { $memory_maps eq "" } {
      set slaves_axi [ ipx::get_bus_interfaces -filter { ABSTRACTION_TYPE_NAME==aximm_rtl && interface_mode==slave } -of_objects [ ipx::current_core ] ]
      set slave_axi [ lindex $slaves_axi 0  ] 
      set memory_map [ ipx::add_memory_map [ get_property name $slave_axi ] [ipx::current_core ] ]
      # and point back to this memory map
      set_property  slave_memory_map_ref [get_property name $memory_map ] $slave_axi 
    } else {
      foreach memory_map_item $memory_maps {
        set memory_map_item_name [get_property name $memory_map_item]
        if {$memory_map_name eq $memory_map_item_name} {
          set memory_map $memory_map_item
        }
      }
    }
    
    set address_blocks [ ipx::get_address_blocks -quiet -of_objects $memory_map ]
    if { $address_blocks eq "" } {
      set address_block [ ipx::add_address_block [get_property name $memory_map ] $memory_map ]
      set_property base_address 0 $address_block 
      set_property range 4096 $address_block 
      set_property width 8 $address_block 
    } else {
      set address_block [ lindex $address_blocks 0 ]
    }
    
    
    foreach reg $registers {
      set offset [ lindex $reg 0 ]
      set name   [ lindex $reg 1 ]
      set data_width [lindex $reg 2]
      set access [ lindex $reg 3 ]
      set reset_val [ lindex $reg 4 ]
      set descr  [ lindex $reg 5 ]
      set fields  [ lindex $reg 6 ]
      # puts "$offset"
      # puts "$name"
      # puts "$data_width"
      # puts "$access"
      # puts "$reset_val"
      # puts "$descr"
    #puts "Register line: [join $reg \"]"
    
      # compare offset and address range, if offset > default address rang(64k), we should expand the address range
      set address_range  [get_property range $address_block]
      set offset_value [::math::bignum::tostr  [ ::math::bignum::fromstr $offset ] ]
      while {$address_range <= $offset_value} {
          set address_range [expr $address_range * 2]
      }
    
      set_property range $address_range $address_block
      set ipx_reg [ ipx::add_register $name $address_block ]
      set_property address_offset $offset_value $ipx_reg 
      set_property size $data_width $ipx_reg 
      set_property size_format long $ipx_reg 
      set_property reset_value  [::math::bignum::tostr [ ::math::bignum::fromstr $reset_val ] ] $ipx_reg 
      set_property reset_value_format long $ipx_reg 
      set_property description $descr $ipx_reg 
      set_property display_name $name $ipx_reg 
    
      # read-only, write-only, read-write, writeOnce, read-writeOnce 
      set_access $access $ipx_reg
    
      foreach field $fields {
    #puts "  field line: [join $field \"]"
         set offset [ lindex $field 0 ]
         set width [ lindex $field 1 ]
         set name [ lindex $field 2 ]
         set access [ lindex $field 3 ]
         set reset_value [ lindex $field 4 ]
         set description [ lindex $field 5 ]
        # puts "$offset"
        # puts "$width"
        # puts "$name"
        # puts "$access"
        # puts "$reset_value"
        # puts "$description"
         set ipx_field [ ipx::add_field $name $ipx_reg ]
         set_property bit_offset $offset $ipx_field
    
         set_dependent bit_width $width $ipx_field
         set_access $access $ipx_field 1
    
         #  set_property reset_value  [::math::bignum::tostr [ ::math::bignum::fromstr $offset ] ] $ipx_field 
         # set_property reset_value_format long $ipx_field 
         set_property description $description $ipx_field 
      }
    
    }

    # }}}
}



proc set_access { access obj {is_field 0}} {
    # {{{
  # read-only, write-only, read-write, writeOnce, read-writeOnce 
  if        { $access eq "RW" } {
             set_property access "read-write" $obj
             if {$is_field} {
               set_property modified_write_value modify $obj 
             }
  } elseif { $access eq "R" } {
             set_property access "read-only" $obj
             if {$is_field} {
               set_property read_action modify $obj 
             }
  } elseif { $access eq "W" } {
             set_property access "write-only" $obj
  } elseif { $access eq "WO" } {
             set_property access "writeOnce" $obj
  } elseif { $access eq "RWO" } {
             set_property access "read-writeOnce" $obj
  } elseif { $access eq "RTOW" } {
             set_property access "read-only" $obj 
             if {$is_field} {
               set_property modified_write_value oneToToggle $obj 
               set_property read_action modify $obj 
             }
  } else {
    puts "Unmatched access type \"$access\""
  }

    # }}}
}



proc set_dependent { name value obj } {
    # {{{
   # are there any operators in the value field?
   # No, set as immediate
   # Yes, set as xpath expr
   if { [string first < $value ] != -1 || \
        [string first > $value ] != -1 || \
        [string first - $value ] != -1 || \
        [string first + $value ] != -1 || \
        [string first / $value ] != -1 || \
        [string first * $value ] != -1 } {
     set_property ${name}_dependency [ ipx::get_xpath_expression $value [ipx::current_core] ] $obj
     set_property ${name}_format long $obj
   } else {
     set_property ${name} $value $obj
     set_property ${name}_format long $obj
   }
    # }}}
}


##############################################################################################
#consider to add axi folder or whatever
# pull cmdline variables to use during setup
set prj_root  [lindex $argv 0]
set prj_root_build "$prj_root/build/ultra_96"
set prj_root_core "$prj_root/src/hw/core"
set prj_root_core_data_types "$prj_root_core/data_types"
set ip_port_nr [lindex $argv 1]
#axi master specific
#set prj_master "$prj_root/src/hw/axi_interface/master/"
puts $ip_port_nr
set prj_top "$prj_root/src/hw/axi_interface/master/alveare_${ip_port_nr}_core"
# fixed for platform
set prj_part "xczu3eg-sbva484-1-i"
set xdc_dir "$prj_root/src/scripts/ultra_96/building"
#where to package ip
set ip_dir "$prj_root/build/ip_repo/ultra_96_${ip_port_nr}_port"
set registers_file [lindex $argv 2]
#set registers_file "$prj_top/registers.txt"
#puts "$registers_file"

# set up project
create_project project_ip $ip_dir -part $prj_part
set_property board_part avnet.com:ultra96v2:part0:1.1 [current_project]

update_ip_catalog

# add the vhdl core and the sv/v files implementation files
add_files -norecurse $prj_root_core
add_files -norecurse $prj_top
#add_files -norecurse $prj_master
add_files -norecurse $prj_root_core_data_types
import_files -force -norecurse
update_compile_order -fileset sources_1

#Add Ultra96 XDC
#add_files -fileset constrs_1 -norecurse "${prj_master}/alveare_v2_ooc.xdc"
update_compile_order -fileset sources_1
#ip flow packager
ipx::package_project -root_dir $ip_dir -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core $ip_dir/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $ip_dir $ip_dir/component.xml
update_compile_order -fileset sources_1
ipx::associate_bus_interfaces -busif m00_axi -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif m01_axi -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif m02_axi -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk [ipx::current_core]
ipx::infer_bus_interface ap_rst_n_2 xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface ap_clk_2 xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]

set_property core_revision 2 [ipx::current_core]


#
#set reg_file_fp [open "$registers_file" r]
#set reg_file_data [read $reg_file_fp]
#close $reg_file_fp

# set data [split $reg_file_data "\n"]
# foreach line $data {
#      puts $line
# }

# ########## DEBUG ##########
# puts $reg_file_data
#    foreach reg $reg_file_data {
#       set offset [ lindex $reg 0 ]
#       set name   [ lindex $reg 1 ]
#       set data_width [lindex $reg 2]
#       set access [ lindex $reg 3 ]
#       set reset_val [ lindex $reg 4 ]
#       set descr  [ lindex $reg 5 ]
#       set fields  [ lindex $reg 6 ]
#     puts "$offset"
#     puts "$name"
#     puts "$data_width"
#     puts "$access"
#     puts "$reset_val"
#     puts "$descr"
#     foreach field $fields {
#     #puts "  field line: [join $field \"]"
#          set offset [ lindex $field 0 ]
#          set width [ lindex $field 1 ]
#          set name [ lindex $field 2 ]
#          set access [ lindex $field 3 ]
#          set reset_value [ lindex $field 4 ]
#          set description [ lindex $field 5 ]
        
#         puts "$offset"
#         puts "$width"
#         puts "$name"
#         puts "$access"
#         puts "$reset_value"
#         puts "$description"
#       }
#     }

########## Eof DEBUG ##########
# procedure to add registers informatio to the IP, utility for PYNQ and reg mapping1
#add_registers $reg_file_data "s_axi_control"


ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]

ipx::save_core [ipx::current_core]

ipx::merge_project_changes ports [ipx::current_core]
ipx::merge_project_changes hdl_parameters [ipx::current_core]
close_project -delete
set_property  ip_repo_paths  $ip_dir [current_project]
update_ip_catalog
#delete project for ip creation using vivado packaging
#close_project -delete

#at the end there should be only the ip

