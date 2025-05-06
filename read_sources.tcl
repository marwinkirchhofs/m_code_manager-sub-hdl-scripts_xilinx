
source scripts/util.tcl

proc _mcm_prj_read_hdl_sources_synth {} {
    set dir_rtl "rtl"

    # TODO: if there are problems with vivado file read/compile order (e.g. for 
    # sv packages), separate the variables into module and package/interface 
    # code)
    # TODO: with the new option to have submodules within the rtl directory, 
    # this ends up adding tb sources rtl submodules to the sources fileset, 
    # instead of sim only. Guess I'll have to adapth the find_files method in 
    # order to fix that.
    set rtl_sv          [list]
    set rtl_sv [list {*}$rtl_sv {*}[glob -nocomplain $dir_rtl/*.sv]]
    set rtl_sv [list {*}$rtl_sv {*}[glob -nocomplain $dir_rtl/*/*.sv]]
    set rtl_vlog          [list]
    set rtl_vlog [list {*}$rtl_vlog {*}[glob -nocomplain $dir_rtl/*.v]]
    set rtl_vlog [list {*}$rtl_vlog {*}[glob -nocomplain $dir_rtl/*/*.v]]
    set rtl_vhdl          [list]
    set rtl_vhdl [list {*}$rtl_vhdl {*}[glob -nocomplain $dir_rtl/*.vhd]]
    set rtl_vhdl [list {*}$rtl_vhdl {*}[glob -nocomplain $dir_rtl/*/*.vhd]]
#     set rtl_sv          [mcm_util_find_files $dir_rtl *.sv]
#     set rtl_vlog        [mcm_util_find_files $dir_rtl *.v]
#     set rtl_vhdl        [mcm_util_find_files $dir_rtl *.vhd]

    # TODO: think about an option to support libraries
    if {[llength $rtl_sv] != 0}         { add_files -fileset sources_1 $rtl_sv }
    if {[llength $rtl_vlog] != 0}       { add_files -fileset sources_1 $rtl_vlog }
    if {[llength $rtl_vhdl] != 0}       { add_files -fileset sources_1  $rtl_vhdl }
}

proc _mcm_prj_read_hdl_sources_sim {} {
    set dir_tb "tb"
    set dir_rtl "rtl"
#     set tb_generic_sv   [mcm_util_find_files $dir_tb *.sv]
#     set tb_sv           [mcm_util_find_files $dir_tb */*.sv]
    set tb_sv [list]
    set tb_sv [list {*}$tb_sv {*}[glob -nocomplain $dir_tb/*.sv]]
    set tb_sv [list {*}$tb_sv {*}[glob -nocomplain $dir_tb/*/*.sv]]
    set tb_sv [list {*}$tb_sv {*}[glob -nocomplain $dir_rtl/*/tb/*.sv]]

#     if {[llength $tb_generic_sv] != 0}  { add_files -fileset sim_1 $tb_generic_sv }
    if {[llength $tb_sv] != 0}          { add_files -fileset sim_1 $tb_sv }
}

proc mcm_prj_read_hdl_sources {} {
    _mcm_prj_read_hdl_sources_synth
    _mcm_prj_read_hdl_sources_sim
}

proc mcm_prj_read_constraints {} {
    set dir_constraints "constraints"
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
