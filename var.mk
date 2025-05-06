
ifndef _VAR_MAKE_XILINX_
_VAR_MAKE_XILINX_ := 1

DIR_VAR_MAKE_XILINX		:= $(abspath $(dir $(lastword ${MAKEFILE_LIST})))

include ${DIR_VAR_MAKE_XILINX}/../var.mk

# TODO: this needs to go somewhere in the xilinx-respective scripts (maybe 
# a make var there that gets included by this one?)
XIL_TOOL 				:= vivado
XIL_SIM 				:= xsim
XIL_PRJ_NAME			:= ${PRJ_NAME}
DIR_XIL_PRJ				:= ${DIR_PRJ_TOP}/_vivado_prj
XIL_PRJ					:= ${DIR_XIL_PRJ}/${XIL_PRJ_NAME}.xpr

DIR_XIL_PRJ_XIPS		:= ${DIR_XIL_PRJ}/${XIL_PRJ_NAME}.srcs/sources_1/ip

DIR_XIPS        		:= ${DIR_PRJ_TOP}/xips
DIR_SCRIPTS_XIL 		:= ${DIR_PRJ_TOP}/scripts_xil
DIR_XIP_CTRL			:= ${DIR_PRJ_TOP}/xip_ctrl

SCRIPT_LOCATE_VIVADO	:= ${DIR_SCRIPTS_XIL}/locate_vivado_install.bash
VIVADO_INSTALL_PATH		:= $(shell bash ${SCRIPT_LOCATE_VIVADO})

SCRIPT_CREATE_PROJECT	:= ${DIR_SCRIPTS_XIL}/create_project.tcl
SCRIPT_MANAGE_PROJECT	:= ${DIR_SCRIPTS_XIL}/manage_project.tcl
SCRIPT_READ_SOURCES		:= ${DIR_SCRIPTS_XIL}/read_sources.tcl
SCRIPT_SOURCE_HELPERS	:= ${DIR_SCRIPTS_XIL}/source_helper_scripts.tcl
SCRIPT_GENERATE_XIPS	:= ${DIR_SCRIPTS_XIL}/generate_xips.tcl
SCRIPT_BUILD_HW			:= ${DIR_SCRIPTS_XIL}/build_hw.tcl
ifneq (,$(wildcard ${DIR_XIP_CTRL}/${VIO_CTRL_TOP}_vio_ctrl.tcl))
SCRIPT_VIO_CTRL			:= ${DIR_XIP_CTRL}/${VIO_CTRL_TOP}_vio_ctrl.tcl
else
SCRIPT_VIO_CTRL			:= ${DIR_SCRIPTS_XIL}/vio_ctrl.tcl
endif

SRC_XDC					:= $(wildcard ${DIR_CONSTRAINTS}/*.xdc)

LIB_NAME_XIL_GLBL		:= xil_glbl
VSIM_LIB_XIL_GLBL		:= ${DIR_SIM}/${SIMULATOR}/${LIB_NAME_XIL_GLBL}

##############################
# IP SOURCES
##############################

# TODO: this way, LIST_XIPS will also contain old IPs which are not present in 
# the project anymore. I mean, in that case they also shouldn't really be in the 
# vivado directory anymore, so the fix is much more that at any update, you 
# remove the sources for the IPs that are not needed anymore
LIST_XIPS				:= $(shell ls ${DIR_XIL_PRJ_XIPS} 2>/dev/null)
LIST_XIPS_XCI			:= $(wildcard ${DIR_XIL_PRJ_XIPS}/*/*.xci)
DIR_XIPS_SIM_OUT		:= ${DIR_SIM}/${SIMULATOR}/xip_sim_export
# list of all xips with exported simulation scripts (this one is accurate as 
# opposed to LIST_XIPS, because the directories that are present actually origin 
# from the project (which gets cleaned before every export))
# TODO: come up with something that causes this thing not to complain if the 
# directory is not there, and instead just be empty
LIST_XIPS_SIM			= $(shell ls ${DIR_XIPS_SIM_OUT} 2> /dev/null)
DIR_XIL_IP_PRECOMPILE	:= $(call fun_get_prj_config_var,xil_ip_precompile_path)/${SIMULATOR}

##############################
# DEBUG CORES
##############################

XIL_DEBUG_CORE_FILES := $(addsuffix .tcl,                                   \
                            $(addprefix ${DIR_XIPS}/xips_debug_cores_,${SRC_MODULES}))

##############################
# OTHERS
##############################

# Vivado glbl.v module (simulation module that vivado IPs require - most 
# reliable if simply loaded from the installation directory)

FILE_VIVADO_GLBLV		:= ${VIVADO_INSTALL_PATH}/data/verilog/src/glbl.v

endif
