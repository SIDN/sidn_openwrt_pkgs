#!/usr/bin/env python

import argparse
import datetime
import os
import shutil
import sys

# Structure:
# (board_name, binfile_name)
IMAGES = [
    ("gl-inet", "openwrt-ar71xx-generic-gl-inet-6416A-v1-squashfs-sysupgrade.bin"),
    ("gl-ar150", "openwrt-ar71xx-generic-gl-ar150-squashfs-sysupgrade.bin")
]

class ReleaseEnvironmentError(Exception):
    pass

class ReleaseCreator:
    def __init__(self, version, changelog_filename, target_dir):
        self.version = version
        self.changelog_filename = changelog_filename
        self.target_dir = target_dir
        self.sums = {}

    def check_environment(self):
        if not os.path.exists(self.changelog_filename):
            raise ReleaseEnvironmentError("Changelog file does not exist: %s" % self.changelog_filename)
        
        for image in IMAGES:
            image_file_path = "bin/ar71xx/%s" % image[1]
            if not os.path.exists(image_file_path):
                raise ReleaseEnvironmentError("Image file for %s does not exist (%s), please build it" % (image[0], image_file_path))

    def create_target_tree(self):
        if not os.path.exists(self.target_dir):
            os.mkdir(self.target_dir)
        for image in IMAGES:
            td = self.target_dir + os.sep + image[0]
            if not os.path.exists(td):
                os.mkdir(td)
    
    def copy_files(self):
        for image in IMAGES:
            shutil.copyfile("bin/ar71xx/%s" % image[1], "%s/%s/sidn_valibox_%s_%s.bin" % (self.target_dir, image[0], image[0], self.version))
            shutil.copyfile(self.changelog_filename, "%s/%s/%s.info.txt" % (self.target_dir, image[0], self.version))
    
    def read_sha256sums(self):
        with open("bin/ar71xx/sha256sums", "r") as sumsfile:
            for line in sumsfile.readlines():
                for image in IMAGES:
                    if image[1] in line:
                        parts = line.split(" ")
                        self.sums[image[0]] = parts[1]

    def create_versions_file(self):
        with open("%s/versions.txt" % self.target_dir, "w") as outputfile:
            for image in IMAGES:
                outputfile.write("%s %s %s/sidn_valibox_%s_%s.bin %s/%s.info.txt %s" %
                    (image[0], self.version, image[0], image[0], self.version, image[0], self.version, self.sums[image[0]]))
    
    def create_release(self):
        self.check_environment()
        self.read_sha256sums()
        self.create_target_tree()
        self.copy_files()
        self.create_versions_file()

parser = argparse.ArgumentParser(description="Create ValiBox release file structure")
parser.add_argument("-v", "--version", help="Version of the release (e.g. 1.0.2)")
parser.add_argument("-b", "--beta", help="Create a beta release version (version number will be beta-<datetime>)", action="store_true")
parser.add_argument("changelog", help="changelog file to put in the release")
parser.add_argument("targetdir", help="target directory to place files in")

args = parser.parse_args()

if args.version is None and not args.beta:
    print("Need either a version (-v) or beta (-b)")
    sys.exit(1)
if args.version is not None and args.beta:
    print("Can't specify both a version number and beta")
    sys.exit(1)

if args.version is not None:
    version_number = args.version
else:
    dt = datetime.datetime.now()
    version_number = "beta-%s" % dt.strftime("%Y%m%d%H%M")

#print(version_number)
rc = ReleaseCreator(version_number, args.changelog, args.targetdir)
rc.create_release()

