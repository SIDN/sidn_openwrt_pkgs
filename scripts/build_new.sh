#!/bin/sh

#
# Rather than using the environment setup, we simply
# use copies of .config files (the only difference should
# be the target platform)
# 
# Currently, this script builds OpenWRT from the files
# * dotconfig-gl-inet
# * dotconfig-gl_ar150
# 
# Note that changes through make oldconfig or make menuconfig
# are overwritten unless it is first copied to the files above

# to rebuild all package feeds, uncomment next 2 lines
#./scripts/feeds update -a
#./scripts/feeds install -a

# next 2 lines only update sidn packages
./scripts/feeds update sidn
if [ $? != 0 ]; then
    echo "Error! Aborting";
    exit;
fi
./scripts/feeds install -a sidn
if [ $? != 0 ]; then
    echo "Error! Aborting";
    exit;
fi

# just clean bin/ rather than rebuilding all packages
rm -rf bin/ar71xx

# Ok now build
#./scripts/env switch gl-inet
cp dotconfig-gl-inet .config
make -j4
if [ $? != 0 ]; then
    echo "Error! Aborting";
    exit;
fi
#./scripts/env switch gl_ar150
cp dotconfig-gl_ar150 .config
make -j4
if [ $? != 0 ]; then
    echo "Error! Aborting";
    exit;
fi

echo "Build done!"
echo "Please run create_release.py to create the update file structure for check.sidnlabs.nl"


