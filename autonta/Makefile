#
# Copyright (C) 2016 SIDN
#

include $(TOPDIR)/rules.mk

PKG_NAME:=autonta
PKG_VERSION:=1.7.0
PKG_RELEASE:=1

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>

PKG_BUILD_DIR:=$(BUILD_DIR)/autonta-$(PKG_VERSION)
PKG_SOURCE:=autonta-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://valibox.sidnlabs.nl/downloads/src/autonta
PKG_HASH:=a020e028e7cc3845b7fe02f71c8008fb8a0595f0583874bf7abc05e6b343d1b9

include $(INCLUDE_DIR)/package.mk

define Package/autonta
  SECTION:=net
  CATEGORY:=SIDN
  TITLE:=Negative Trust Anchor Management system
  URL:=http://www.sidnlabs.nl
  MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
  DEPENDS:=+@UHTTPD_MOD_LUA +uhttpd +uhttpd-mod-lua +curl +ca-certificates +coreutils +coreutils-stat +nginx +@NGINX_SSL +@NGINX_HTTP_UWSGI +@BUSYBOX_CUSTOM +@BUSYBOX_CONFIG_SHA256SUM
endef

define Package/autonta/description
 This package contains the web-interface for negative trust anchors
endef

define Build/Configure
endef

define Package/autonta/install
  $(CP) -r ./files/* $(1)/
endef

$(eval $(call BuildPackage,autonta))

