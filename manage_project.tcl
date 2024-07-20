package require json

proc mcm_prj_set_hw_platform {part {board_part ""}} {
    set_property part $part [current_project]
    if { $board_part ne "" } {
        # if a board part should be set, select the newest version that matches the 
        # board specification
        set xil_board_part [lindex [get_board_parts *${board_part}*] end]
        set_property board_part $xil_board_part [current_project]
    }
}

proc mcm_prj_update {} {
    # update the vivado project, based on the variables as they are set in the 
    # project config json file
    set d_project_config [::json::json2dict                             \
                        [read [open _T_FILE_PROJECT_CONFIG_T_ r]]]
    set part        [dict get $d_project_config part]
    set board_part  [dict get $d_project_config board_part]
    set top         [dict get $d_project_config top]

    mcm_prj_set_hw_platform $part $board_part
    set_property top $top [get_filesets sources_1]
}

proc mcm_prj_refresh {} {
    # if anyone knows a better way of taking over any changes that have been
    # made to the project from outside the opened project, please let me know
    close_project
    open_project [glob _vivado_prj/*.xpr]
}

# if the script is called, instead of sourced
if {[info exists ::argv0] && $::argv0 eq [info script]} {
    # act on tcl argument: if none is given, build the hardware
    if {$argc >= 1} {
        switch [lindex $argv 0] {
            _T_COMMAND_UPDATE_T_ {
                open_project [glob _vivado_prj/*.xpr]
                mcm_prj_update
            }
        }
    } else {
        open_project [glob _vivado_prj/*.xpr]
        mcm_prj_update
    }
}

