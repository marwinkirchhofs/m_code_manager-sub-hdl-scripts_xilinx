
proc mcm_prj_read_hdl_sources {} {
    set dir_rtl "_T_DIR_RTL_T_"
    set dir_tb "_T_DIR_TB_T_"
    
    # TODO: if there are problems with vivado file read/compile order (e.g. for 
    # sv packages), separate the variables into module and package/interface 
    # code)
    set rtl_sv          [glob -nocomplain -type f -directory $dir_rtl *.sv]
    set rtl_vlog        [glob -nocomplain -type f -directory $dir_rtl *.v]
    set rtl_vhdl        [glob -nocomplain -type f -directory $dir_rtl *.vhd]
    set tb_generic_sv   [glob -nocomplain -type f -directory $dir_tb *.sv]
    set tb_sv           [glob -nocomplain -type f -directory $dir_tb */*.sv]
    
    # TODO: think about an option to support libraries
    if {[llength $rtl_sv] != 0}         { add_files -fileset sources_1 $rtl_sv }
    if {[llength $rtl_vlog] != 0}       { add_files -fileset sources_1 $rtl_vlog }
    if {[llength $rtl_vhdl] != 0}       { add_files -fileset sources_1  $rtl_vhdl }
    if {[llength $tb_generic_sv] != 0}  { add_files -fileset sim_1 $tb_generic_sv }
    if {[llength $tb_sv] != 0}          { add_files -fileset sim_1 $tb_sv }
}

proc mcm_prj_read_constraints {} {
    set dir_constraints "_T_DIR_CONSTRAINTS_T_"
    set constraint_files [glob -type f -directory [file normalize ${dir_constraints}] *.xdc]

    read_xdc -unmanaged ${constraint_files}

    # exclude physical constraints and implementation-only timing constraints 
    # from synthesis
    if {[llength [glob -nocomplain -type f -directory ${dir_constraints} *_phys.xdc]] != 0} {
        set_property used_in_synthesis false [get_files -filter {NAME =~ *_phys.xdc}]
    }
    if {[llength [glob -nocomplain -type f -directory ${dir_constraints} *_impl_*.xdc]] != 0} {
        set_property used_in_synthesis false [get_files -filter {NAME =~ *_impl_*.xdc}]
    }
}

if {[info exists ::argv0] && $::argv0 eq [info script]} {
    mcm_prj_read_hdl_sources
    mcm_prj_read_constraints
}
