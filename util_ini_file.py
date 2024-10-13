#!/usr/bin/env python3

# utility to process (and extend) the xrt.ini file for the vitis (alveo) hw 
# emulation flow.
# The point is: the make flow has to alter that file, depending on which type 
# for example of emulation execution you want to have (dump wave file, run live 
# waveform, no waveform at all). But the user might also do things in the same 
# file, may it be for setting up a certain application tracing which needs to be 
# persistent. That's what this utility is for, work on the fields in the file 
# that you have to work on, no matter if they are present or not, and preserve 
# the remainder of the config.
# TODO: it would be nice if the ini file was only written if actually something 
# changed, but we'll leave that either to the future, or to never, or if we're 
# lucky make dependencies can do the trick as well

import configparser
import os
import sys


VALID_FILE_TYPES = ["xrt_ini", "vpp_config"]


class IniFile (object):
    """
    The class tracks if a config file has been altered by its actions, by means 
    of self.dirty. That can be used for only rewriting the file if anything has 
    changed, and leaving it untouched otherwise.
    """

    VALID_SECTIONS = []

    def __init__(self, path_ini_file: str):
        self.config = configparser.ConfigParser()
        self.path = path_ini_file
        if os.path.isfile(path_ini_file):
            self.dirty = False
            self.config.read(path_ini_file)
        else:
            self.dirty = True

    def __str__(self):
        return self.config.__str__()

    def get_config(self):
        return self.config

    def set(self, group, key, value):
        """
        set a config field value
        [group]
        key = value
        """
#         print(f"{group} {key} {value}")

        if not group in self.VALID_SECTIONS:
            raise ValueError(f"'group' needs to be in {self.VALID_SECTIONS}")

        if not group in self.config.sections():
            self.dirty = True
            self.config.add_section(group)
            self.config[group][key] = value

        if not self.config[group].get(key) == value:
            self.dirty = True
            self.config[group][key] = value

    def write(self, only_if_changed=True):
        """
        :only_if_changed: only write the file if anything has changed in the 
        config (or if the file previously was not there) - helpful for some make 
        flows, such that this tool can smoothly manage config files (instead of 
        ugly bash pseudo-conditionals in make targets), but that still 
        a depending target will not be triggered if there is nothing to be done 
        on the file.
        """
        if self.dirty or not only_if_changed:
            with open(self.path, 'w') as f_out:
                self.config.write(f_out, space_around_delimiters=False)
            self.dirty = False


class XrtIniFile (IniFile):
    
    VALID_SECTIONS = ["Debug", "Emulation", "Runtime"]


class VppConfigFile (IniFile):

    VALID_SECTIONS = [
            "advanced", "clock", "connectivity", "debug", "hls",
            "linkhook", "package", "profile", "vivado",
            ]

# *args is in the form of (virtual) triplets of <group key value> -> see 
# arguments to XrtIniFile.set
# - open an ini file it is present (otherwise will be created)
# - set all the fields as passed by *args (existing fields are overwritten, 
# non-existing fields are created)
# - write back the ini file
def main(path_ini_file, file_type, *args):
    """
    :file_type: "xrt_ini" or "vpp_config"
    """
    if not file_type in VALID_FILE_TYPES:
        raise ValueError(f"'file_type' needs to be in {VALID_FILE_TYPES}")

    if file_type == "xrt_ini":
        ini_file = XrtIniFile(path_ini_file)
    if file_type == "vpp_config":
        ini_file = VppConfigFile(path_ini_file)

#     print(args)
    for arg_triplet_idx in range(0, len(args), 3):
        ini_file.set(*args[arg_triplet_idx:arg_triplet_idx+3])
    ini_file.write()

if __name__ == "__main__":
    main(*sys.argv[1:])
