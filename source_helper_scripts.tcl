
# bundles all the other helper scripts.
# advantage: you can start vivado/vitis with sourcing only this script, and you
# have all the custom project management functions available in the tool
source _T_DIR_SCRIPTS_T_/_T_SCRIPT_READ_SOURCES_T_
source _T_DIR_SCRIPTS_T_/_T_SCRIPT_BUILD_HW_T_
source _T_DIR_SCRIPTS_T_/_T_SCRIPT_MANAGE_XIL_PRJ_T_
# if it exists, source xilinx ip generation script
if { [file exists _T_DIR_SCRIPTS_T_/_T_SCRIPT_XILINX_IP_GENERATION_T_] == 1} {
    source _T_DIR_SCRIPTS_T_/_T_SCRIPT_XILINX_IP_GENERATION_T_
}
