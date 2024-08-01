
# bundles all the other helper scripts.
# advantage: you can start vivado/vitis with sourcing only this script, and you
# have all the custom project management functions available in the tool
source scripts_xil/read_sources.tcl
source scripts_xil/build_hw.tcl
source scripts_xil/manage_project.tcl
# if it exists, source xilinx ip generation script
if { [file exists scripts_xil/generate_xips.tcl] == 1} {
    source scripts_xil/generate_xips.tcl
}
