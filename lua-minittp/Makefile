#
# Copyright (C) 2018 Jelte Jansen
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lua-minittp
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKG_MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
PKG_LICENSE:=GPLv3

PKG_SOURCE_URL:=https://github.com/tjeb/lua-minittp.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=e81fd8c06e600b8f7ec5462f2c576b46b4efeebe
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/lua-minittp
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=lua-minittp
  URL:=https://github.com/tjeb/lua-minittp
  DEPENDS:=+lua +lua-copas +lua-coxpcall
endef

define Package/lua-minittp/description
  Minimalistic web framework
endef

define Build/Configure
endef

define Build/Compile
endef

define Build/Install
endef

define Package/lua-minittp/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/*.lua $(1)/usr/lib/lua
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/bin/* $(1)/usr/bin
endef

$(eval $(call BuildPackage,lua-minittp))

