include $(TOPDIR)/rules.mk

PKG_NAME:=spin

# Settings for latest master (dev) build
# This will create a snapshot package with the current date and the latest
# commit hash
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=https://github.com/sidn/spin
#LATEST_COMMIT:=$(shell git ls-remote ${PKG_SOURCE_URL} master | head -c 8)
#BUILD_DATE:=$(shell date +%Y-%m-%d)
#PKG_SOURCE_VERSION:=$(LATEST_COMMIT)
#PKG_SOURCE_DATE:=$(BUILD_DATE)
#PKG_FIXUP:=autoreconf

# Settings for latest release build, use (updated version) of this
PKG_VERSION:=1.0,0
PKG_RELEASE:=1
# when creating release tags, and remove the git settings
PKG_SOURCE:=spin-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://valibox.sidnlabs.nl/downloads/src/spin/
PKG_HASH:=893867b7c9588bac41c124f8f25ef5c8313c6116cc13503ec5142f85117ff0b2

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += -ggdb3 -Wno-error=format
CONFIGURE_PATH:=src
MAKE_PATH:=src

define Package/spin
  SECTION:=base
  CATEGORY:=SIDN
  TITLE:=Experimental tools for SPIN
  URL:=https://github.com/SIDN/spin
  DEPENDS:=+ipset\
           +mosquitto-ssl\
           +libmosquitto-ssl\
           +libnfnetlink\
           +libmnl\
           +libnetfilter-conntrack\
           +kmod-nf-conntrack\
           +kmod-nf-conntrack-netlink\
           +libnetfilter-queue\
           +kmod-nfnetlink-queue\
           +libnetfilter-log\
           +kmod-nfnetlink-log\
           +libldns\
           +iptables-mod-nflog\
           +iptables-mod-nfqueue\
           +libuci\
           +libubus\
           +libblobmsg-json\
           +libmicrohttpd-ssl\
           +luci-compat
  MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
endef

PKG_BUILD_DEPENDS:=libnfnetlink

define Package/spin/description
  Experiment with SPIN tools
endef

define Package/spin/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/rc.d
	cp -r ./files/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/spin
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/spind/spind $(1)/usr/bin/spind
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/spinweb/spinweb $(1)/usr/bin/spinweb
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/scripts/spin_list_ips $(1)/usr/bin/spin_list_ips
	$(INSTALL_DIR) $(1)/usr/share/spin/spinweb/templates
	cp -r ${PKG_BUILD_DIR}/src/spinweb/static $(1)/usr/share/spin/spinweb/
	cp -r ${PKG_BUILD_DIR}/src/spinweb/templates $(1)/usr/share/spin/spinweb/

	$(INSTALL_DIR) $(1)/etc/spin
endef

$(eval $(call BuildPackage,spin))
