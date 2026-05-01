
# m_code_manager AMD/Xilinx-specifc HDL scripts

This repo contains a collection of scripts for maintaining, simulating, and 
building HDL projects with xilinx hardware. It is the amd/xilinx-specific 
supplementary script repo to the non vendor-specific [hdl 
scripts](https://github.com/marwinkirchhofs/m_code_manager-sub-hdl-scripts).


## Relation with top-level generic code manager project

See the generic hdl scripts 
[repo](https://github.com/marwinkirchhofs/m_code_manager-sub-hdl-scripts). The 
information there applies to the scripts here as well.


## Features

### Standard FPGA flow

* vivado project generation/setup
* automated hardware build and run from command line
* xilinx IP generation for integration in RTL code, via simple tcl dictionaries
* automated generation and integration of xilinx debug cores (ILA/VIO) based on 
  specific signal naming in modules (SystemVerilog only)
    * scripting environment for easy connecting and interfacing with 
      auto-generated VIO cores
* custom vivado tcl commands for all functionalities (e.g. re-generating xilinx 
  IPs, add source file tree, connect to auto-generated debug core)
* define and load/flash different hardware build versions
* json configuration file to set build parameters
    * device/part/board
    * top module

#### Roadmap

* support defining custom/multiple vivado runs (currently `synth_1`, `impl_1` 
  etc are hard-coded).
* embedded cores/software (zynq devices, hard-IP CPU, soft core, maybe some day 
  petalinux)
* module instantiation (generating and updating), ideally based on ctags
* VHDL support for currently SystemVerilog-only features (like auto-generated 
  debug cores)
* label hardware artifacts with respective git commit/status, for 
  reproducibility
* hooks for pre-/post-synth etc
* support for distinguishing multiple connected FPGAs
* support for flashing to non-volatile on-board storage
* support for remote FPGA targets

### Alveo devices flow

The repo contains a full-fledged development and build flow for Alveo devices, 
which is completely separate from the standard FPGA flow. Since this only 
targets a niche audience, the associated make commands and information are all 
in the wiki (TODO link), instead of describing the user-side API in this readme.

* Automated alveo kernel export, hardware emulation (with and without 
  gui/software debug, live or post-simulation waveform view), hardware build, 
  and hardware running (with and without debugger)
* extensive parameterization via json build configuration file, and "native" 
  Alveo flow configuration files (kernel configuration, `v++` configuration, 
  "native" meaning directly supplied to the amd/xilinx toolchain)
* inspect build results (timing report, graphical resource usage/chip view)


## (Where to find) Documentation

See the generic hdl scripts 
[repo](https://github.com/marwinkirchhofs/m_code_manager-sub-hdl-scripts). The 
information there applies to this repo as well.


## How to use

The workflow is `make` based. In addition, a number of tcl commands is set up 
that can be invoked from within vivado (tcl or gui mode). They sometimes have an 
exactly equivalent make command, more information below. Remember that anything 
related to Alveo devices is not documented here, but in the TODO link wiki.

### Make targets

* project management
    * `make project` to create (or update) a vivado project. In an existing 
      project, still adds all sources/constraints, updates top module, part and 
      board_port from `project_config.json`, and generates/updates described 
      xips (in other words, invokes all of `mcm_prj_read_hdl_sources`, 
      `mcm_prj_read_constraints`, `mcm_prj_update`, and 
      `mcm_xips_generate_xips`, which are explained below)
    * `make open[_gui]` to open the vivado project in tcl shell or gui, **and** load 
      all custom tcl commands listed below
    * `make xip_ctrl` (**relies on 
      [m_code_manager](https://github.com/marwinkirchhofs/m_code_manager) and the 
      [hdl](https://github.com/marwinkirchhofs/m_code_manager-codemanagers-hdl) code 
      manager to be installed, and available in the PATH)** generates xilinx debug 
      cores from specifically named signals (see TODO link wiki)
    * `make xips` (**FIX: depends on xip_ctrl**)
* coding
    * `make lint` invokes verilator as RTL code linter (potentially broken)
* build
    * `make build` to run hardware build (FIX: inconsistencies with 
      re-generating IPs if changed, if necessary run from within the open 
      project)
    * `manage_hw_builds` to invoke an interactive script that organizes hardware 
      build artifacts
* run
    * `make program_fpga` to flash a locally connected FPGA (JTAG) with the 
      bitstream corresponding to `hw_version` in `project_config.json` (see TODO 
      wiki section on directory structure/build artifacts management)
    * `make run` (alias to `make run_hw_ctrl`) to connect to an auto-generated 
      VIO core on a **programmed** FPGA

### Vivado tcl commands

(some of these commands may seem unnecessary at first glance, and probably are, 
but they are occasionally used by functionalities of the [hdl code 
manager](https://github.com/marwinkirchhofs/m_code_manager-codemanagers-hdl), 
and since they are implemented anyways, might as well document them here)

* source file/project management
    * `mcm_prj_read_hdl_sources` to add all sources to the project (build and 
      simulation) (TODO link directory structure)
    * `mcm_prj_read_constraints` to add all constraints files to the project 
      (TODO link directory structure)
    * `mcm_prj_set_hw_platform {part {board_part ""}}` to set board and, 
      optionally, board_part project properties. Valid arguments are either the 
      `part` and `board_part` properties you would usually pass, or some 
      pre-configured boards, which are documented in the TODO link wiki (this 
      repo).
    * `mcm_prj_update` to update the project properties (top module, part, 
      board_part) from `project_config.json`. Doesn't add any sources.
* xilinx IPs
    * `mcm_xips_generate_xips` (part of `make xips`) to process all xip 
      description files (see TODO link wiki), and generate the described IPs in 
      the project
* build
    * `mcm_build_run_synthesis` to run synthesis (part of `make build`), **and** 
      write any reports to the project's build artifacts directory (see TODO 
      link wiki)
    * `mcm_build_run_implementation` (part of `make build`) functions analogous 
      to the synthesis command (invokes both P&R and bitstream generation)
* run
    * `mcm_run_program_fpga` to flash a locally connected FPGA (see `make run`), 
      and set up debug probe files for connecting via the vivado gui.

### VIO tcl commands

For the sake of compactness, the command line interface for interacting with an 
auto-generated VIO is explained in the TODO link wiki.
