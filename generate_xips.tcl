# HELPER FUNCTIONS FOR XIP GENERATION AND INTEGRATION
# turns a dictionary describing xips into generated IP within a vivado project 

package require json

set dir_prj_top [file dirname [file dirname [info script]]]
set d_project_config [::json::json2dict                             \
                    [read [open $dir_prj_top/project_config.json r]]]
set xil_ip_precompile_path [dict get $d_project_config xil_ip_precompile_path]

############################################################
# HELPERS
############################################################

##############################
# VIVADO PROJECT CONTROL
##############################

proc _mcm_xips_create_single_xip {dict_ip_config} {
    set ip_design_name  [dict get $dict_ip_config name]
    set ip_lib_name     [dict get $dict_ip_config ip_name]
    set ip_vendor       [dict get $dict_ip_config ip_vendor]
    set ip_library      [dict get $dict_ip_config ip_library]
    set ip_config       [dict get $dict_ip_config config]

    if {[get_ips $ip_design_name] == ""} {
        create_ip                                                               \
                    -name $ip_lib_name -vendor $ip_vendor -library $ip_library  \
                    -module_name $ip_design_name
    }
    # you have to set all properties in one command because otherwise vivado 
    # aborts trying to set conflicting properties (before it gets to set the 
    # rest to actually match)
    set_property -dict $ip_config [get_ips $ip_design_name]
    generate_target all [get_ips $ip_design_name]
    export_ip_user_files -of_objects [get_ips $ip_design_name]                  \
                -no_script -sync -force -quiet
}

# set up runs for IP in vivado project
proc _mcm_xips_create_ip_run {dict_ip_config} {
    set ip_design_name  [dict get $dict_ip_config name]
    if {[llength [get_runs ${ip_design_name}_*]] == 0} {
        create_ip_run [get_ips $ip_design_name]
    }
}

# synthesis for all IPs
proc _mcm_xips_launch_ip_runs_synth {xips} {
    foreach xip $xips {
        set ip_design_name  [dict get $xip name]
        launch_runs ${ip_design_name}_synth_1
    }
}

# implementation for all IPs
proc _mcm_xips_launch_ip_runs_impl {xips} {
    foreach xip $xips {
        set ip_design_name  [dict get $xip name]
        launch_runs ${ip_design_name}_impl_1
    }
}


############################################################
# PUBLIC API
############################################################

proc _mcm_xips_process_xip_dict {xips} {
    # Handle a list of IP declaration dictionairies:
    # - Xilinx Project
    #   - create the IP in the project if it doesn't exist yet
    #   - generate all output products and user ip files
    #   - set up per-IP synthesis and implementation runs

    # iterate through all IPs in xips
    foreach xip $xips {
        puts "creating IP [dict get $xip name]"
        _mcm_xips_create_single_xip $xip

        # separate function to make switching off ooc easier should it be
        # necessary
        _mcm_xips_create_ip_run $xip
    }
}

proc mcm_xips_generate_xips {{xip_file ""}} {
    # iterate through all RTL modules and process their IPs
    if {$xip_file eq ""} {
        set list_xip_files [glob -nocomplain xips/xips_*.tcl]
    } else {
        set list_xip_files {}
        if {file exists $xip_file} {
            lappend list_xip_files $xip_file
        }
    }
    foreach xip_file $list_xip_files {
        source $xip_file
        puts $xips
        # process the described IPs
        _mcm_xips_process_xip_dict $xips
    }
    # (the runs are not launched here, thanks to vivado/vitis project mode 
    # they'll be automatically launched during build if they are not up-to-date)
}

# TODO: check what is the best way of dealing with debug cores (either exclude 
# them, because useless in simulation, or include them because otherwise 
# a design can break)
proc mcm_xips_export_sim {simulator export_dir} {
    global xil_ip_precompile_path
    export_simulation   -lib_map_path $xil_ip_precompile_path/$simulator    \
                        -of_objects [get_ips xip_*] -simulator $simulator         \
                        -directory $export_dir -absolute_path -force
}


############################################################
# SCRIPT "MAIN"
############################################################

if {[info exists ::argv0] && $::argv0 eq [info script]} {
    if {$argc >= 1} {
        switch [lindex $argv 0] {
            export_sim {
                # $argv[1]: simulator - $argv[2]: simulation scripts output 
                # directory
                mcm_xips_export_sim [lindex $argv 1] [lindex $argv 2]
            }
        }
    } else {
        mcm_xips_generate_xips
    }
}
