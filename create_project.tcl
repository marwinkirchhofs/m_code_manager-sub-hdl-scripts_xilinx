
source _T_DIR_SCRIPTS_T_/_T_SCRIPT_SOURCE_HELPERS_T_

set vivado_prj_name _T_PRJ_NAME_T_
set vivado_prj_dir _vivado_prj

##############################
# SET UP PROJECT
##############################

if {[file exists ${vivado_prj_dir}/${vivado_prj_name}.xpr] == 0} {
    create_project $vivado_prj_name $vivado_prj_dir
} else {
    open_project ${vivado_prj_dir}/${vivado_prj_name}.xpr
}

set_property default_lib              xil_defaultlib [current_project]
set_property simulator_language       _T_SIMULATOR_LANGUAGE_T_ [current_project]
set_property target_language          _T_TARGET_LANGUAGE_T_ [current_project]

# create filesets (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}
if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -srcset constrs_1
}

##############################
# READ SOURCES
##############################

# RTL
mcm_prj_read_hdl_sources

# CONSTRAINTS
mcm_prj_read_constraints

##############################
# READ/APPLY PROJECT CONFIG
##############################
# It's wise to run mcm_prj_update after reading the sources, because 
# mcm_prj_update parses project_config.json and applies whatever project 
# settings it finds in there. That includes setting the top module. Therefore 
# you want to have read source files by that time.

mcm_prj_update

##############################
# NON-CODE PROJECT COMPONENTS
##############################
# You have to process the IPs after running mcm_prj_update. The reason: 
# mcm_prj_update sets the part according to what is configured in 
# project_config.json. If the IPs are configured before that, there is no part 
# set, Vivado assumes some random part, and then when changing the part to the 
# one that we actually want the IP gets locked and becomes read-only.

# TODO: add block design generation

if { [file exists _T_DIR_SCRIPTS_T_/_T_SCRIPT_XILINX_IP_GENERATION_T_] == 1} {
    mcm_xips_generate_xips
}
