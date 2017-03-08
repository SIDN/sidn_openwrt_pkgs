include $(TOPDIR)/rules.mk

PKG_NAME:=lua-turbo
PKG_VERSION:=2.1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/turbo-$(PKG_VERSION)
PKG_SOURCE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/kernelsauce/turbo/archive/
PKG_MD5SUM:=e803654370293156e5ad1cd52e58aed1

include $(INCLUDE_DIR)/package.mk

define Package/lua-turbo
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Lua Turbo web framework
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=https://github.com/kernelsauce/turbo
  DEPENDS:=+luajit
endef

define Package/spin/description
  Lua Turbo web framework
endef

#define Build/Configure
#endef

#define Package/spin/install
#	$(INSTALL_DIR) $(1)/etc/init.d
#	cp -r ./files/* $(1)/
#	$(INSTALL_DIR) $(1)/www/spin
#	cat ${PKG_BUILD_DIR}/html/graph.html | sed s/localhost/192.168.8.1/g > $(1)/www/spin/graph.html
#	cat ${PKG_BUILD_DIR}/html/print.html | sed s/localhost/192.168.8.1/g > $(1)/www/spin/print.html
#	cp -r ${PKG_BUILD_DIR}/html/* $(1)/www/spin/
#	$(INSTALL_DIR) $(1)/usr/lib/spin
#	$(INSTALL_BIN) ${PKG_BUILD_DIR}/lua/* $(1)/usr/lib/spin/
#endef

$(eval $(call BuildPackage,spin))
