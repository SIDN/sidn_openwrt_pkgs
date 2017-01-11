#!/usr/bin/python

import argparse

import shutil
import sys
import logging

from autonta import run_cmd, check_update

# figure out the ip address without using local dns server

#check_update_internal(True, False, hostname='')

class HostOverrider:
    def __init__(self, address, hostname):
        self.address = address
        self.hostname = hostname

    def __enter__(self):
        shutil.copy("/etc/hosts", "/tmp/hosts.backup")
        with open("/tmp/hosts.backup", "r") as inf:
            with open("/etc/hosts", "w") as outf:
                for line in inf.readlines():
                    outf.write(line)
                outf.write("%s\t%s\n" % (self.address, self.hostname))

    def __exit__(self, *args):
        shutil.copy("/tmp/hosts.backup", "/etc/hosts")

if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-b', '--beta', help='update to beta instead of release', action="store_true")
    parser.add_argument('-o', '--override-host', help='use fixed ip address (94.198.159.35)', action="store_true")
    parser.add_argument('-k', '--keep-settings', help='keep settings', action="store_true")
    parser.add_argument('-d', '--debug', help='print debug info', action="store_true")
    args = parser.parse_args()

    if args.debug:
        root = logging.getLogger()
        root.setLevel(logging.DEBUG)

        ch = logging.StreamHandler(sys.stdout)
        ch.setLevel(logging.DEBUG)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        ch.setFormatter(formatter)
        root.addHandler(ch)        

    if args.override_host:
        with HostOverrider("94.198.159.35", "valibox.sidnlabs.nl"):
            if check_update(args.beta, args.keep_settings):
                print("Install can go")
            else:
                print("Install no go")
    else:
        if check_update(args.beta, args.keep_settings):
            print("Install can go")
        else:
            print("Install no go")
