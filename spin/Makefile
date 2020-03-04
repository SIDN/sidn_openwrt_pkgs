include $(TOPDIR)/rules.mk

PKG_NAME:=spin
PKG_VERSION:=0.11
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/spin-$(PKG_VERSION)
PKG_SOURCE:=spin-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://valibox.sidnlabs.nl/downloads/src/spin/
PKG_HASH:=a43ed3704826e6e6d1108be0b4c082f46a9ce9e5ddca94ade579b6b991292f50

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += -ggdb3 -Wno-error=format
CONFIGURE_PATH:=src
MAKE_PATH:=src

define Package/spin
  SECTION:=base
  CATEGORY:=SIDN
  TITLE:=Experimental tools for SPIN
  URL:=https://github.com/SIDN/spin
  DEPENDS:=+ip\
           +ipset\
           +luaposix\
           +luasec\
           +luabitop\
           +lua-copas\
           +luasocket\
           +mosquitto-ssl\
           +libmosquitto-ssl\
           +lua-mosquitto\
           +libnfnetlink\
           +lua-minittp\
           +lua-websockets\
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
           +nginx\
           +libuci\
           +libubus\
           +libblobmsg-json
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
	$(INSTALL_DIR) $(1)/usr/lib/spin/web_ui
	cp -r ${PKG_BUILD_DIR}/src/web_ui/* $(1)/usr/lib/spin/web_ui
	$(INSTALL_DIR) $(1)/usr/lib/spin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/lua/*.lua $(1)/usr/lib/spin/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/spind/spind $(1)/usr/bin/spind
	$(INSTALL_DIR) $(1)/etc/spin
endef

$(eval $(call BuildPackage,spin))
