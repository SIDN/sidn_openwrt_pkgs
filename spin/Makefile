include $(TOPDIR)/rules.mk

PKG_NAME:=spin
PKG_VERSION:=0.3
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/spin-$(PKG_VERSION)
PKG_SOURCE:=spin-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://tjeb.nl
PKG_MD5SUM:=54ac0fc361501651f8f9106ad799b821

include $(INCLUDE_DIR)/package.mk

define Package/spin
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Experimental tools for SPIN
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=http://www.sidnlabs.nl
  DEPENDS:=+ip +luaposix +luasec +luabitop +luasocket +libnetfilter-log +mosquitto-ssl +libmosquitto +lua-mosquitto +libldns +iptables +iptables-mod-nflog +kmod-ipt-nflog +SSP_SUPPORT:libssp
endef

PKG_BUILD_DEPENDS:=libnetfilter-log libmosquitto libldns

define Package/spin/description
  Experiment with SPIN tools
endef

#define Build/Configure
#endef

define Package/spin/install
	$(INSTALL_DIR) $(1)/etc/init.d
	cp -r ./files/* $(1)/
	$(INSTALL_DIR) $(1)/www/spin
	cp -r ${PKG_BUILD_DIR}/html/* $(1)/www/spin/
	$(INSTALL_DIR) $(1)/usr/lib/spin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/lua/* $(1)/usr/lib/spin/

	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) ${PKG_BUILD_DIR}/src/.libs/lua-spin_nflog.so.0.0.0 $(1)/usr/lib/lua/lua-spin_nflog.so
endef

$(eval $(call BuildPackage,spin))
