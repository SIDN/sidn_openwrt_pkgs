#!/bin/sh

# To create the environment for this script, use the following commands:
#
# ./scripts/env new gl-inet
# make menuconfig
# select GL.inet as profile (and any other necessary changes)
# ./scripts/env save
# ./scripts/env new gl_ar150
# make menuconfig
# ./scripts/env save
# select GL_ar150 as profile (and any other necessary changes)
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: IF WE MAKE MENUCONFIG CHANGES THESE NEED TO BE APPLIED TWICE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

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
./scripts/env switch gl-inet
make -j4
if [ $? != 0 ]; then
    echo "Error! Aborting";
    exit;
fi
./scripts/env switch gl_ar150
make -j4
if [ $? != 0 ]; then
    echo "Error! Aborting";
    exit;
fi

echo "Build done!"
echo "Please run create_release.py to create the update file structure for check.sidnlabs.nl"


