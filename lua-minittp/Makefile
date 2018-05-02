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

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_MIRROR_HASH:=89a186d9e8bb43a6d45207eeba2883600854ea05befda55b38f7ac215b0d5615
PKG_SOURCE_URL:=https://github.com/tjeb/lua-minittp.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=024b65738b4434860777fc43d7cacaefea29ec60
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/lua-minittp
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Lua-MD5
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

