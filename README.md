Introduction
------------

This repository contains the SIDN ValiBox packages; these are 
additional packages for OpenWRT to turn it into an SIDN ValiBox; for 
more information, see http://valibox.sidnlabs.nl

There are currently two packages; sidn-unbound, which is a modified 
version of the Unbound DNS resolver that can redirect DNS answers that 
fail DNSSEC validation. The user is redirected to a custom page on the 
ValiBox where a Negative Trust Anchor can be set, so that the DNSSEC 
validation is temporarily skipped (until the NTA is manually removed 
again, or until the ValiBox is rebooted).

The other package contains the web interface to enable NTA management, 
and ValiBox-specific configuration files.

These packages are not compiled by themselves; they are included in the 
build process of an OpenWRT image. See below for specific instructions.


Requirements
------------

The packages are aimed at OpenWRT Chaos Calmer; the source code of
OpenWRT can be retrieved from

https://dev.openwrt.org/wiki/GetSource

For some devices, like the GL-Inet AR-150, you will need some patches that are not in OpenWRT main yet; you can fetch a suitable clone of the OpenWRT sources here:

https://github.com/domino-team/openwrt-cc

Additional information about building OpenWRT itself can be found on

https://dev.openwrt.org/wiki




Building from scratch
---------------------

Before you start the build, you will need to add the SIDN feed to the current set of feeds. Go to the base directory of the openwrt source tree, and copy the feeds configuration example file. Uncheck the feeds ‘targets’ and ‘oldpackages’, and add the following line to the feeds configuration file: ‘src-git sidn git://git.tjeb.nl/sidn_openwrt_pkgs’. You can remove the other commented lines.

```
cd <openwrt-sources>
cp feeds.conf.sample feeds.conf
vi feeds.conf
```

The feeds.conf file should now look something like:

```
src-git packages https://github.com/openwrt/packages.git;for-15.05
src-git luci https://github.com/openwrt/luci.git;for-15.05
src-git routing https://github.com/openwrt-routing/packages.git;for-15.05
src-git telephony https://github.com/openwrt/telephony.git;for-15.05
src-git management https://github.com/openwrt-management/packages.git;for-15.05
src-git targets https://github.com/openwrt/targets.git
src-git oldpackages http://git.openwrt.org/packages.git
src-git sidn https://github.com/SIDN/sidn_openwrt_pkgs
```

Note: if you are editing the packages in a local clone of 
sidn_openwrt_pkgs (or any of the sources above), you can use src-link, 
so that you do not have to commit and push each change when testing. 
See http://wiki.openwrt.org/doc/devel/feeds for more information.

Now update and install the feeds sources:

```
./scripts/feeds update -a
./scripts/feeds install -a
```


The next step is to configure the build; if there is an existing .config file (from an external source, not from a previous build), it is probably a good idea to start anew, and delete it first. Then run make menuconfig

```
make menuconfig
```

Select the target system (ar71xx), target profile (in case of GL-inets: gl-inet for the old device, gl-ar150 for the new one).
Go to Network->SIDN and enable all packages features there. This will also automatically enable most of the dependencies, although one is currently not triggered yet; you need to also enable Network->Web Servers->Nginx->Configuration->Enable SSL Module.

Exit menuconfig and save the config, then start the build:
```
make
```

The very first time this can take quite some time, and with a fresh checkout there may be a failure if it has not been fixed yet (see below, section Fix for Python Module); subsequent builds should be significantly faster.


Build environments
------------------

You can create images for multiple devices with build environments.

There are two helper scripts in scripts/; to use them, copy them to 
your openwrt source base directory. The script build_new.sh assumes 
there are two environments (gl-inet and gl_ar150), and rebuilds the 
source. The create_release.py script builds a filetree and info file
we can publish, which works with the automatic update system.


Finding the images
------------------

Depending on the target platform and type, the image files can differ in names.

If the build succeeds you can find the final image in bin/<target system>/openwrt-<system>-generic-<profile>-squashfs-sysupgrade.bin

For example, the ar-150 image will be called openwrt-ar71xx-generic-gl_ar150-squashfs-sysupgrade.bin.

There might also be a -factory.bin, which can be used to upgrade a device that is not running openwrt yet. The sysupgrade should be fine in most cases.



Update the automatic update system
----------------------------------

We have a centralized update system in place; if we release a new version the ValiBox users can upgrade their systems with 2 clicks; they do not need to download specific images for their devices or muck around in administration systems.

