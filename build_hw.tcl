
package require json

set dir_xilinx_log _T_DIR_XILINX_HW_BUILD_LOG_T_
set dir_hw_export _T_DIR_HW_EXPORT_T_
set dir_hw_export_latest [file join $dir_hw_export latest]

proc mcm_build_run_synthesis {} {
    global dir_xilinx_log

    # TODO: make sure that all the xips are synthesized first, before proceeding 
    # with the main synthesis. Otherwise the waiting fails...

    # TODO: add other potentially set up runs here
    reset_run synth_1
    launch_runs synth_1
    wait_on_run synth_1

    open_run synth_1            -name netlist_1
    write_checkpoint            -force  $dir_xilinx_log/post_synth
    report_timing_summary       -file   $dir_xilinx_log/post_synth_timing_summary.rpt
    report_power                -file   $dir_xilinx_log/post_synth_power.rpt
}

proc mcm_build_run_implementation {} {
    global dir_xilinx_log
    global dir_hw_export
    global dir_hw_export_latest

    set run impl_1

    # TODO: add other potentially set up runs here
    reset_run $run
    launch_runs $run -to_step write_bitstream
    wait_on_run $run

    open_run $run
    write_checkpoint        -force  $dir_xilinx_log/post_place
    report_timing_summary   -file   $dir_xilinx_log/post_place_timing_summary.rpt
    report_power            -file   $dir_xilinx_log/post_impl_power.rpt

    # copy hardware description files to 'dir_hw_export/latest'
    set prj_name [file tail [pwd]]
    set dir_vivado_build [file join _vivado_prj ${prj_name}.runs $run]
    set top_module [get_property top [get_filesets sources_1]]

    set l_hardware_files []
    set vivado_bit_file [glob -nocomplain [file join ${dir_vivado_build} ${top_module}.bit]]
    if {[llength $vivado_bit_file] != 0} {
        lappend l_hardware_files [lindex $vivado_bit_file 0]
    }
    set vivado_probes_file [glob -nocomplain [file join ${dir_vivado_build} ${top_module}.ltx]]
    if {[llength $vivado_probes_file] != 0} {
        lappend l_hardware_files [lindex $vivado_probes_file 0]
    }
    set vivado_sysdef_file [glob -nocomplain [file join ${dir_vivado_build} ${top_module}.sysdef]]
    if {[llength $vivado_sysdef_file] != 0} {
        lappend l_hardware_files [lindex $vivado_sysdef_file 0]
    }

    file mkdir $dir_hw_export_latest
    foreach hardware_file $l_hardware_files {
        file copy -force $hardware_file $dir_hw_export_latest
    }
}

proc mcm_run_program_fpga {} {
    global dir_hw_export
    global dir_hw_export_latest

    # OPEN HARDWARE SERVER
    open_hw
    connect_hw_server

    # FIND AND OPEN HW TARGET/DEVICE
    # - (assuming that there is only one target connected)
    # - one target can have multiple devices, by xilinx hierarchy
    current_hw_target [lindex [get_hw_targets] 0]
    open_hw_target
    current_hw_device [lindex [get_hw_devices] 0]

    # HARDWARE PROGRAMMING FILES

    # determine selected hardware build
    set d_project_config [::json::json2dict                             \
                        [read [open _T_FILE_PROJECT_CONFIG_T_ r]]]
    set hw_build_name [dict get $d_project_config hw_version]
    set hw_build_path [file join $dir_hw_export $hw_build_name]

    # fetch hardware files
    # TODO: set probes file
    set bit_file [lindex [glob ${hw_build_path}/*.bit] 0]
    set_property PROGRAM.FILE $bit_file [current_hw_device]

    # PROGRAM
    program_hw_devices [current_hw_device]
}

# if the script is called, instead of sourced
if {[info exists ::argv0] && $::argv0 eq [info script]} {
    # act on tcl argument: if none is given, build the hardware
    if {$argc >= 1} {
        switch [lindex $argv 0] {
            _T_COMMAND_BUILD_HW_T_ {
                mcm_build_run_synthesis
                mcm_build_run_implementation
            }
            _T_COMMAND_PROG_FPGA_T_ {
                mcm_run_program_fpga
            }
        }
    } else {
        mcm_build_run_synthesis
        mcm_build_run_implementation
    }
}
