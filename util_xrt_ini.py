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

XRT_INI_GROUPS = ["Debug", "Emulation", "Runtime"]

class XrtIniFile (object):

    def __init__(self, path_ini_file: str):
        self.config = configparser.ConfigParser()
        self.path = path_ini_file
        if os.path.isfile(path_ini_file):
            self.config.read(path_ini_file)

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
        print(f"{group} {key} {value}")

        if not group in XRT_INI_GROUPS:
            raise ValueError(f"'group' needs to be in {XRT_INI_GROUPS}")

        if not group in self.config.sections():
            self.config.add_section(group)
        self.config[group][key] = value

    def write(self):
        with open(self.path, 'w') as f_out:
            self.config.write(f_out, space_around_delimiters=False)

# *args is in the form of (virtual) triplets of <group key value> -> see 
# arguments to XrtIniFile.set
# - open an ini file it is present (otherwise will be created)
# - set all the fields as passed by *args (existing fields are overwritten, 
# non-existing fields are created)
# - write back the ini file
def main(path_ini_file, *args):
    xrt_ini_file = XrtIniFile(path_ini_file)
    print(args)
    for arg_triplet_idx in range(0, len(args), 3):
        xrt_ini_file.set(*args[arg_triplet_idx:arg_triplet_idx+3])
    xrt_ini_file.write()

if __name__ == "__main__":
    main(*sys.argv[1:])
