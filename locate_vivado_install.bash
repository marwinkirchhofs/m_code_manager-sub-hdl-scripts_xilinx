#!/usr/bin/env bash

# The purpose of this script is to do its best to locate the system vivado 
# installation directory because the xilinx make flow needs it (actually only in 
# order to locate the glbl.v for simulation with xilinx IPs...). I envisioned 
# that to become too cumbersome to do it directly in the makefile, hence 
# a separate script. The script supports looking for a specific version.
# In every path (no the env variables), the script looks for a directories 
# called "Xilinx", "xilinx", "Vivado" or "vivado" (in that order). If a version 
# is passed (see arguments), then there also needs to be a subdirectory to "[Vv]
# ivado" that is named exactly like the version.
#
# Arguments:
# $1 - (optional) version (e.g. "2019.1"). If you don't want to specify 
# a version, but need to use $2, setting to "all" is the same as not setting.  
# In that case the script returns the first version it finds in the first vivado 
# directory hit (and goes on if there is no version in that directory)
# $2 - (optional) user-defined search path -> see below ot Order of Looking
#
# Order of looking:
# 1. $2 (optional) - you can pass a path as argument, thus this check is skipped 
# if no argument is passed. If there is no installation found, an error is 
# issued, instead of proceeding. (The script could've simply went on with 
# checking the other options, but I think it's better to hard-notify the user if 
# they actually have specified a directory, and it turns out to be invalid.  
# A warning you'll overlook in the make output)
# 2. env variables "VIVADO", "XILINX_VIVADO" - in that order - ATTENTION: These 
# are expected to be full paths to vivado installations, including version (e.g.  
# .../Vivado/2019.1) instead of general installation directories
# 3. /opt - typical installation location for xilinx tools
# 4. /opt/apps - seen every now and then on servers

version=$1
user_path="$2"

# important: pass directory without trailing '/'
check_path () {
    dir=$1

    xilinx_path="$dir"
    if [[ -d "$dir/Xilinx" ]]; then
        xilinx_path="$dir/Xilinx"
    elif [[ -d "$dir/xilinx" ]]; then
        xilinx_path="$dir/xilinx"
    fi

    vivado_path=""
    if [[ -d "$xilinx_path/Vivado" ]]; then
        vivado_path="$xilinx_path/Vivado"
    elif [[ -d "$xilinx_path/vivado" ]]; then
        vivado_path="$xilinx_path/vivado"
    fi
    
    # [Vv]ivado directory found -> check for version(s)
    if [[ ! -z "$vivado_path" ]]; then
        if [[ (-z $version) || ($version == "all") ]]; then
            # look for arbitrary version (the newest one you find in that 
            # directory, effectively hoping/assuming that there is only one)
            vivado_version=$(ls $vivado_path | sed -n -e '/[0-9]\{4\}\.[0-9]/p' | tail -n 1)
            if [[ ! -z "$vivado_version" ]]; then
                echo "$vivado_path/$vivado_version"
                return 0
            fi
        else
            # look for specific version
            if [[ -d "$vivado_path/$version" ]]; then
                echo "$vivado_path/$version"
                return 0
            fi
        fi
    fi
    return 1

    # note: (just for the sake of completeness) the one case this function does 
    # not catch is if there are both "Vivado" and "vivado" existing directories, 
    # and there is no vivado version in "Vivado", but there is in "vivado" (and 
    # similar shenanigans with "[Xx]ilinx"). I feel like it's acceptable if 
    # I blame that case on the sys admin should it happen. Please let me know if 
    # you encounter a case that proves me wrong.
}

vivado_path=""

# USER-SPECIFIED PATH
if [[ ! -z "$user_path" ]]; then
    check_path "$user_path"
    vivado_path=$(check_path "$user_path")
    if [[ -z "$vivado_path" ]]; then
        if [[ ! -z $version ]]; then
            echo "ERROR: Vivado version $version not found at user-specified path $user_path" 1>&2
            exit 1
        else
            echo "ERROR: There was no vivado version found at user-specified path $user_path" 1>&2
            exit 1
        fi
    else
        echo "$vivado_path"
        exit 0
    fi
fi

# DEFAULT OPTIONS
# env variables
vivado_path=$(printenv VIVADO)
if [[ ! -z "$vivado_path" ]]; then
    echo "$vivado_path"
    exit 0
fi
vivado_path=$(printenv XILINX_VIVADO)
if [[ ! -z "$vivado_path" ]]; then
    echo "$vivado_path"
    exit 0
fi
# /opt
vivado_path=$(check_path /opt)
if [[ ! -z "$vivado_path" ]]; then
    echo "$vivado_path"
    exit 0
fi
# /opt/apps
vivado_path=$(check_path /opt/apps)
if [[ ! -z "$vivado_path" ]]; then
    echo "$vivado_path"
    exit 0
fi

echo "ERROR: No Vivado installation path could be found" 1>&2
exit 1

