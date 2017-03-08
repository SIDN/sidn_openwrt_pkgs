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
  DEPENDS:=+luajit +libcrypto
endef

define Package/lua-turbo/description
  Lua Turbo web framework
endef

define Build/Configure
endef

define Package/lua-turbo/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/turbo.lua $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/turbovisor.lua $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libtffi_wrap.so $(1)/usr/lib/lua
	cp -r $(PKG_BUILD_DIR)/turbo $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,lua-turbo))
