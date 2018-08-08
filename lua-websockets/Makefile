#
# Copyright (C) 2018 Jelte Jansen
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lua-websockets
PKG_VERSION:=2.2
PKG_RELEASE:=1
PKG_MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
PKG_LICENSE:=MIT

PKG_SOURCE_URL:=https://github.com/lipp/lua-websockets
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=v2.2
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/lua-websockets
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=lua-websockets
  URL:=https://github.com/tjeb/lua-websockets
  DEPENDS:=+lua +lua-copas +luabitop +luasocket
endef

define Package/lua-websockets/description
  Minimalistic web framework
endef

define Build/Configure
endef

define Build/Compile
endef

define Build/Install
endef

define Package/lua-websockets/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/*.lua $(1)/usr/lib/lua
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/* $(1)/usr/bin
endef

$(eval $(call BuildPackage,lua-websockets))

