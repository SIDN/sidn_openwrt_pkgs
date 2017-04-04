include $(TOPDIR)/rules.mk

PKG_NAME:=spin
PKG_VERSION:=0.2
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/spin-$(PKG_VERSION)
PKG_SOURCE:=spin-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://tjeb.nl
PKG_MD5SUM:=fe143b1b5fd6149bc3801e630685524c

include $(INCLUDE_DIR)/package.mk

define Package/spin
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Experimental tools for SPIN
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=http://www.sidnlabs.nl
  DEPENDS:=+ip +luaposix +luasec +luabitop +luasocket +lua-coxpcall +lua-copas +libnetfilter-log +mosquitto-ssl
endef

PKG_BUILD_DEPENDS:=libnetfilter-log

define Package/spin/description
  Experiment with SPIN tools
endef

#define Build/Configure
#endef

define Package/spin/install
	$(INSTALL_DIR) $(1)/etc/init.d
	cp -r ./files/* $(1)/
	$(INSTALL_DIR) $(1)/www/spin
	cat ${PKG_BUILD_DIR}/html/graph.html | sed s/localhost/192.168.8.1/g > $(1)/www/spin/graph.html
	cat ${PKG_BUILD_DIR}/html/print.html | sed s/localhost/192.168.8.1/g > $(1)/www/spin/print.html
	cp -r ${PKG_BUILD_DIR}/html/* $(1)/www/spin/
	$(INSTALL_DIR) $(1)/usr/lib/spin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/lua/* $(1)/usr/lib/spin/

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/spin_nflog $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,spin))
