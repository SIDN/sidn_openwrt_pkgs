#
# Copyright (C) 2016 SIDN
#

include $(TOPDIR)/rules.mk

PKG_NAME:=autonta
PKG_VERSION:=1.7.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://valibox.sidnlabs.nl/downloads/src/autonta
PKG_HASH:=5da1641521f2eef5876b64e36f9dedb11091a80db88cdc909171afd411f0f4b1

include $(INCLUDE_DIR)/package.mk

define Package/autonta
  SECTION:=net
  CATEGORY:=SIDN
  TITLE:=Negative Trust Anchor Management system
  URL:=https://www.sidnlabs.nl/
  MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
  DEPENDS:=+curl\
           +ca-certificates\
           +coreutils\
           +coreutils-stat\
           +luabitop\
           +luaposix\
           +nginx\
           +uhttpd\
           +uhttpd-mod-lua\
           +@UHTTPD_MOD_LUA\
           +@NGINX_SSL\
           +@NGINX_HTTP_UWSGI\
           +@BUSYBOX_CUSTOM\
           +@BUSYBOX_CONFIG_SHA256SUM
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

