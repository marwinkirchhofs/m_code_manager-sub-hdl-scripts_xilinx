
# CALLING
# when called, the scripts (re-)generates the IP xo export for alveo by 
# directing the call to mcm_alveo_ip_export. The arguments are the same as to 
# that function:
# $1 - ip configuration file (the json file that _mcm_alveo_ip_load_user_config 
# needs and specifies)
# $2 - the export directory. The script will create an `ip` and an `xo` 
# directory at that path, holding the temporary ip configuration project and the 
# exported final xo respectively.

package require json

source scripts_xil/read_sources.tcl
source scripts_xil/generate_xips.tcl
source scripts_xil/manage_project.tcl

# specific tcl file for specifying IPs within the alveo kernel design, to make 
# sure only those are loaded into the IP export
set file_xips_alveo xips/xips_alveo.tcl

# TODO: allow for specifying a kernel xml, for users who want all the options 
# and know how to do that
# TODO: allow specifying kernel files which provide a c simulation model or 
# something like that

# project name: directory name two hierarchy levels upwards
set prj_name [file tail [file dirname [file dirname [file normalize [info script]]]]]

set file_ip_config "alveo/alveo_ip_config.json"
set file_build_config "build_config.json"

set dir_build "build"
# TODO: turned out: it was a stupid idea to hardcode the IP output directory, so 
# please fix that and make that an argument to the script
set dir_alveo_export [file join $dir_build "alveo"]
set dir_ip [file join $dir_alveo_export "ip"]
set dir_xo [file join $dir_alveo_export "xo"]


############################################################
# HELPER FUNCTIONS
############################################################

proc _mcm_alveo_ip_get_dir_ip {dir_alveo_export} {
    return [file join $dir_alveo_export "ip"]
}

proc _mcm_alveo_ip_get_dir_xo {dir_alveo_export} {
    return [file join $dir_alveo_export "xo"]
}

proc _mcm_alveo_ip_get_ip_name {file_ip_config} {

    set d_ip_config [::json::json2dict [read [open $file_ip_config r]]]
    if {[dict exists $d_ip_config "name"]} {
        set ip_name [dict get $d_ip_config "name"]
    } else {
        set ip_name [dict get $d_ip_config $prj_name]
    }
    return $ip_name
}

proc _mcm_alveo_ip_create_clk {name} {
    ipx::infer_bus_interface $name xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
}

# set up all associated clocks for bus interfaces and resets
# :signal_type: one of the known signal types; so far I know of "busif", "reset" 
# and presumably "interrupt"
proc _mcm_alveo_ip_associate_clk {signal signal_type clk} {
    switch $signal_type {
        "busif" {
            set sig_opt "-busif"
        }
        "reset" {
            set sig_opt "-reset"
        }
        "interrupt" {
            set sig_opt "-interrupt"
        }
        default {
            puts "Unknown signal type: $signal_type"
        }
    }
    ipx::associate_bus_interfaces $sig_opt $signal -clock $clk [ipx::current_core]
}
 
# add a register to the resp
# I know that in theory you wouldn't have to even provide the option to set the 
# bus interface because as per the alveo rtl kernel specs it HAS to be called 
# "s_axi_control", but anyways...
proc _mcm_alveo_ip_create_register {name size offset {busif_ctrl "s_axi_control"}} {
    set address_block [ipx::get_address_blocks reg0 -of_objects             \
            [ipx::get_memory_maps $busif_ctrl -of_objects [ipx::current_core]]]
    ipx::add_register $name $address_block
    set reg [ipx::get_registers $name -of_objects $address_block]
    set_property size $size $reg
    set_property address_offset $offset $reg
}

proc _mcm_alveo_ip_associate_mem_busif {reg_name bus_if_name} {
    set address_block [ipx::get_address_blocks reg0 -of_objects             \
            [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
    set reg_obj [ipx::get_registers $reg_name -of_objects $address_block]
    ipx::add_register_parameter ASSOCIATED_BUSIF $reg_obj
    set_property value $bus_if_name [ipx::get_register_parameters           \
            ASSOCIATED_BUSIF -of_objects $reg_obj]
}


############################################################
# FLOW STEPS
############################################################

# create a project for exporting the IP
# allows for both setting up a project, or doing it in-memory. The in-memory 
# option is for automated build flows, once everything works, the project is for 
# debugging/inspection/running step-by-step if something goes wrong.
# (the reason for not using the existing project is that I don't want to clutter 
# that with the IP, and that I have seen errors happening with dubious duplicate 
# top level module warnings, which exported fine but in the end didn't correctly 
# work in vitis. so fresh project, full control, always). The command removes 
# anything that is there already to be sure that the export is clean.
# :prj_path: used to switch between project and in-memory flow - if non-empty, 
# a project is created at this path, otherwise an in-memory project is used
proc _mcm_alveo_ip_prj {{prj_path ""}} {
    global file_ip_config
    global file_xips_alveo

    if {$prj_path eq ""} {
        create_project -in_memory
    } else {
        set ip_name [_mcm_alveo_ip_get_ip_name $file_ip_config]
        create_project -name ip_prj_${ip_name} -dir $prj_path
    }
    _mcm_prj_read_hdl_sources_synth
    # general project management function from manage_project.tcl, to apply some 
    # fields from build_config.json - sets the "part" and "board_part" 
    # properties, and sets the top module
    mcm_prj_update
    mcm_xips_generate_xips $file_xips_alveo
    # TODO: it might be necessary to also process constraints here, don't know 
    # if you apply them in the IP or later when you do the implementation in 
    # vivado
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1

    set d_build_config [::json::json2dict [read [open build_config.json r]]]
    set top         [dict get $d_build_config top]
    set_property top $top [get_filesets sources_1]
}

proc _mcm_alveo_ip_package_core {dir_alveo_export} {
    set dir_ip [_mcm_alveo_ip_get_dir_ip $dir_alveo_export]
    ipx::package_project -root_dir $dir_ip \
        -vendor user.org -library rtl_kernel \
        -taxonomy /KernelIP -import_files -set_current false
    ipx::unload_core $dir_ip/component.xml
}

proc _mcm_alveo_ip_export_xo {file_ip_config dir_alveo_export} {
    set dir_ip [_mcm_alveo_ip_get_dir_ip $dir_alveo_export]
    set dir_xo [_mcm_alveo_ip_get_dir_xo $dir_alveo_export]
    set ip_name [_mcm_alveo_ip_get_ip_name $file_ip_config]
    set file_xo [file join $dir_xo ${ip_name}.xo]
    if {[file exists $file_xo]} {
        file delete -force $file_xo
    }
    package_xo -xo_path $file_xo \
            -kernel_name $ip_name -ip_directory $dir_ip
}

# load a json config for an alveo module export and apply it
# The config file is a json file with the following format.
# - bus interfaces and simple signals like reset and interrupt are treated 
# equally. Therefore, the "registers" field SHOULD be present for a control axi 
# bus, and it SHOULD NOT be present for anything else.
# - within "registers", "associated_busif" is optional and should only be 
# present for registers that represent base addresses for shared memory access 
# buses.
# - "name" is optional. If not present, the IP has the project name (project 
# directory name)
# - "type" as per vitis ("busif", "reset", "interrupt")
# - recommended to do size in decimal notation, offset in hex (but shouldn't 
# matter as long as it's tcl syntax)
# {
#     "name": <name>,
#     "interfaces": {
#         <busif/port>: {
#             "type" : <type>,
#             "clock": <clock>,
#             "registers": {
#                 <name>: {
#                     "size": <size>,
#                     "offset": <offset>,
#                     "associated_busif": <busif>
#                 }
#             }
#         }
#     }
# }
proc _mcm_alveo_ip_load_user_config {file_ip_config} {

    # TODO: name -> should actually already be there, in _mcm_alveo_ip_export_xo
    set d_ip_config [::json::json2dict [read [open $file_ip_config r]]]
    set ip_interfaces [dict get $d_ip_config "interfaces"]
    dict for {intf intf_config} $ip_interfaces {
        if {[dict get $intf_config "type"] == "clock"} {
            # if it's a clock, just create it (and make sure you don't try to 
            # associate a clock with a clock)
            _mcm_alveo_ip_create_clk $intf
        } else {
            # associate clock
            _mcm_alveo_ip_associate_clk                     \
                    $intf                                   \
                    [dict get $intf_config "type"]          \
                    [dict get $intf_config "clock"]
            # associate busif
            # TODO: seems like that part just doesn't work yet, fix it
            if {[dict exists $intf_config "registers"]} {
                dict for {reg_name reg_config} [dict get $intf_config "registers"] {
                    _mcm_alveo_ip_create_register           \
                            $reg_name                       \
                            [dict get $reg_config "size"]   \
                            [dict get $reg_config "offset"]
                    if {[dict exists $reg_config "associated_busif"]} {
                        _mcm_alveo_ip_associate_mem_busif   \
                                $reg_name                   \
                                [dict get $reg_config "associated_busif"]
                    }
                }
            }
        }
    }
}

proc _mcm_alveo_ip_configure {file_ip_config} {
    set core [ipx::current_core]
    foreach user_param [ipx::get_user_parameters] {
      ipx::remove_user_parameter [get_property NAME $user_param] $core
    }
    _mcm_alveo_ip_enable_vitis
    _mcm_alveo_ip_load_user_config $file_ip_config
    ipx::create_xgui_files $core

    # code effectively from tutorial design, I don't know where to find 
    # documentation for these fields
    # https://github.com/Xilinx/Vitis-Tutorials/tree/2024.1/Hardware_Acceleration/Feature_Tutorials/01-rtl_kernel_workflow
    set d_ip_config [::json::json2dict [read [open $file_ip_config r]]]
    set xpm_libs_raw [dict get $d_ip_config "xpm"]
    set xpm_libs {}
    foreach xpm_lib $xpm_libs_raw {
        lappend xpm_libs [string cat XPM_ [string toupper $xpm_lib]]
    }
    set_property xpm_libraries $xpm_libs $core
    set_property supported_families {} $core
    set_property auto_family_support_level level_2 $core
}

# prepare everything for vitis export
# -> basically, that sets up everything that vivado needs to run `package_xo` 
# during packaging the IP
proc _mcm_alveo_ip_enable_vitis {} {
    # TODO: update to wherever you get the core from
    set core [ipx::current_core]
    set_property sdx_kernel true $core
    set_property sdx_kernel_type rtl $core
    set_property vitis_drc {ctrl_protocol user_managed} $core
    set_property ipi_drc {ignore_freq_hz true} $core
}

proc _mcm_alveo_ip_edit_in_prj {dir_alveo_export} {
    set dir_ip [_mcm_alveo_ip_get_dir_ip $dir_alveo_export]
    ipx::edit_ip_in_project -upgrade true -name tmp_edit_project \
        -directory $dir_ip $dir_ip/component.xml
}


############################################################
# MAIN API
############################################################

# creates an alveo-targeted export of the current top level module (build_config)
# TODO: where to set up the clock associations, register coniguration etc? there 
# needs to be some user-editable file in a nice format (probably json because 
# vivado) at a specific location.
# :prj_path: see _mcm_alveo_ip_prj
proc mcm_alveo_ip_export {file_ip_config dir_alveo_export {prj_path ""}} {

    # create project
    _mcm_alveo_ip_prj $prj_path
    # package IP
    _mcm_alveo_ip_package_core $dir_alveo_export
    # open IP in project
    _mcm_alveo_ip_edit_in_prj $dir_alveo_export
    # configure IP
    _mcm_alveo_ip_configure $file_ip_config

    ipx::update_checksums [ipx::current_core]
    ipx::save_core [ipx::current_core]
    close_project -delete

    _mcm_alveo_ip_export_xo $file_ip_config $dir_alveo_export
}

if {[info exists ::argv0] && $::argv0 eq [info script]} {
    mcm_alveo_ip_export {*}$argv
}
