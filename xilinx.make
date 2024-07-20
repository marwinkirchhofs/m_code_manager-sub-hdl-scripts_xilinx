#!/usr/bin/env bash

include _T_FILE_MAKE_VARIABLES_T_

XIL_TOOL 		:= _T_XILINX_TOOL_T_
XIL_PRJ_NAME	:= _T_PRJ_NAME_T_
XIL_PRJ			:= _vivado_prj/${XIL_PRJ_NAME}.xpr
SHELL			:= bash

GET_PRJ_CONFIG_VAR	:= python3 _T_DIR_SCRIPTS_T_/_T_SCRIPT_READ_JSON_VAR_T_ _T_FILE_PROJECT_CONFIG_T_
# language-independent by the classic trick: assume there is only one file that 
# is named <top>.<file_ending>
FILE_RTL_TOP	:= $(wildcard ${DIR_RTL}/$(shell ${GET_PRJ_CONFIG_VAR} top).*)

##############################
# PROJECT MANAGEMENT
##############################

.PHONY: project
project: ${XIL_PRJ}

${XIL_PRJ}:
	${XIL_TOOL} -mode batch -source ${DIR_TCL}/_T_SCRIPT_CREATE_PROJECT_T_

.PHONY: read_sources
read_sources:
	${XIL_TOOL} -mode batch -source ${DIR_TCL}/_T_SCRIPT_READ_SOURCES_T_ ${XIL_PRJ}

.PHONY: open
open:
	${XIL_TOOL} -mode tcl ${XIL_PRJ} -source ${DIR_TCL}/_T_SCRIPT_SOURCE_HELPERS_T_

.PHONY: open_gui
open_gui:
	${XIL_TOOL} -mode gui ${XIL_PRJ} -source ${DIR_TCL}/_T_SCRIPT_SOURCE_HELPERS_T_

.PHONY: export_hw
export_hw:
	# TODO
	@echo "target $@ is not supported yet"

.PHONY: xip_ctrl
xip_ctrl: ${XIL_DEBUG_CORE_FILES}

# TODO: export that function to some other script that the code manager
# generates. The guideline is that the code manager must not generate anything
# that again calls the code manager
${DIR_XIPS}/xips_debug_cores_%.tcl: ${DIR_RTL}/%.*
	@m_code_manager hdl xip_ctrl --target $*

.PHONY: xips
xips:	xip_ctrl
	${XIL_TOOL} -mode batch -source ${DIR_TCL}/_T_SCRIPT_XILINX_IP_GENERATION_T_ ${XIL_PRJ}

##############################
# LINTING
##############################
# Use the verilator linting function for checking (System)Verilog syntax and 
# style, but don't perform any verilation or compilation.
# All targets refer to linting targets within the sim/makefile because all the 
# verilator options are set up there. So although linting in fact has nothing to 
# do with simulation, it's more convenient and for coding more consistent to do 
# it this way.
#
# For providing additional verilator options (like excluding certain warnings in
# the first place), one can specify these as a string in vl_opts:
# make lint vl_opts="-Wno-STMTDLY -Wno-PINCONNECTEMPTY"

# convenience target to refer to vl_lint
.PHONY: lint
lint:	vl_lint

.PHONY: vl_lint
vl_lint:
	@make -C ${DIR_SIM} vl_lint vl_opts="${vl_opts}"

##############################
# SIMULATION
##############################

.PHONY: vl_start_gui
vl_start_gui:
	@make -C ${DIR_SIM} vl_start_gui

.PHONY: sim
sim:
	@make -C ${DIR_SIM} sim

.PHONY: vl_sim
# vl_sim:			hls_synth
vl_sim:
	@make -C ${DIR_SIM} vl_sim

.PHONY: vl_build
# vl_build:		hls_synth
vl_build:
	@make -C ${DIR_SIM} vl_build

# add direct access to other simulators here

##############################
# HW BUILD
##############################

# TODO: needs to depend on hw and sw once sw is implemented
.PHONY: build
build:	project build_hw

.PHONY: build_hw
build_hw:	xips
	${XIL_TOOL} -mode batch -source ${DIR_TCL}/_T_SCRIPT_BUILD_HW_T_ ${XIL_PRJ}

.PHONY: manage_hw_builds
manage_hw_builds:
	${SHELL} _T_DIR_SCRIPTS_T_/_T_SCRIPT_MANAGE_BUILDS_T_

##############################
# SW BUILD
##############################

.PHONY: sdk_project
sdk_project:
	# TODO
	@echo "target $@ is not supported yet"

.PHONY: build_sw
build_sw:
	# TODO
	@echo "target $@ is not supported yet"

##############################
# EXECUTION
##############################

.PHONY: program_fpga
program_fpga:
	${XIL_TOOL} -mode batch -source ${DIR_TCL}/_T_SCRIPT_BUILD_HW_T_ \
					-tclargs _T_COMMAND_PROG_FPGA_T_

.PHONY: program_soc
program_soc:
	# TODO
	@echo "target $@ is not supported yet"

.PHONY: program_sw
program_sw:
	# TODO
	@echo "target $@ is not supported yet"

# convenience target - maybe in the future when there are more (elaborated) run 
# options, this one can differentiate and link to something different
.PHONY: run
run: run_hw_ctrl

# start up top level vio hardware control
.PHONY: run_hw_ctrl
run_hw_ctrl:
	${XIL_TOOL} -mode tcl -source ${DIR_TCL}/_T_SCRIPT_XILINX_VIO_CONTROL_T_
