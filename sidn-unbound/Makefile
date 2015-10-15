#
# Copyright (C) 2010-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sidn-unbound
PKG_VERSION:=1.5.5
PKG_RELEASE:=1

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>

PKG_BUILD_DIR:=$(BUILD_DIR)/unbound-$(PKG_VERSION)
PKG_SOURCE:=unbound-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://www.unbound.net/downloads
PKG_MD5SUM:=f85854baad15adc7ce8acefe6cda4cf8

PKG_BUILD_DEPENDS:=libexpat
PKG_BUILD_PARALLEL:=1
PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/sidn-unbound/Default
  TITLE:=A validating, recursive & caching DNS resolver (with SIDN patches)
  URL:=http://www.unbound.net/
  DEPENDS:=+libopenssl
endef

define Package/sidn-unbound
  $(call Package/sidn-unbound/Default)
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE+= (daemon)
  DEPENDS+= +sidn-libunbound
endef

define Package/sidn-unbound/description
  This package contains the Unbound daemon, with SIDN patches.
endef

define Package/sidn-unbound-anchor
  $(call Package/sidn-unbound/Default)
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE+= (anchor utility)
  DEPENDS+= +sidn-unbound +libexpat
endef

define Package/sidn-unbound-anchor/description
  This package contains the Unbound anchor utility.
endef

define Package/sidn-unbound-control
  $(call Package/sidn-unbound/Default)
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE+= (control utility)
  DEPENDS+= +sidn-unbound
endef

define Package/sidn-unbound-control/description
  This package contains the Unbound control utility.
endef

define Package/sidn-unbound-control-setup
  $(call Package/sidn-unbound/Default)
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE+= (control setup utility)
  DEPENDS+= +sidn-unbound-control +openssl-util
endef

define Package/sidn-unbound-control-setup/description
  This package contains the Unbound control setup utility.
endef

define Package/sidn-unbound-host
  $(call Package/sidn-unbound/Default)
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE+= (DNS lookup utility)
  DEPENDS+= +sidn-libunbound
endef

define Package/sidn-unbound-host/description
  This package contains the Unbound DNS lookup utility.
endef

define Package/sidn-libunbound
  $(call Package/sidn-unbound/Default)
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE+= (library)
endef

define Package/sidn-libunbound/description
  This package contains the Unbound shared library.
endef

CONFIGURE_ARGS += \
	--disable-gost \
	--enable-allsymbols \
	--with-libexpat="$(STAGING_DIR)/usr" \
	--with-ssl="$(STAGING_DIR)/usr" \
	--without-pthreads

define Package/sidn-unbound/conffiles
/etc/unbound/unbound.conf
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/unbound.h $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libunbound.{so*,a,la} $(1)/usr/lib/
endef

define Package/sidn-unbound/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/sbin/unbound \
		$(PKG_INSTALL_DIR)/usr/sbin/unbound-checkconf \
		$(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/unbound
	$(INSTALL_CONF) \
		$(PKG_INSTALL_DIR)/etc/unbound/unbound.conf \
		$(1)/etc/unbound/
	$(INSTALL_CONF) \
		./files/unbound.conf.in \
		$(1)/etc/unbound/
	$(INSTALL_CONF) ./files/root.key $(1)/etc/unbound/
	$(INSTALL_CONF) ./files/named.cache $(1)/etc/unbound/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/unbound.init $(1)/etc/init.d/unbound
endef

define Package/sidn-unbound-anchor/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/unbound-anchor $(1)/usr/sbin/
endef

define Package/sidn-unbound-control/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/unbound-control $(1)/usr/sbin/
endef

define Package/sidn-unbound-control-setup/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/unbound-control-setup $(1)/usr/sbin/
endef

define Package/sidn-unbound-host/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/unbound-host $(1)/usr/sbin/
endef

define Package/sidn-libunbound/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libunbound.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,sidn-unbound))
$(eval $(call BuildPackage,sidn-unbound-anchor))
$(eval $(call BuildPackage,sidn-unbound-control))
$(eval $(call BuildPackage,sidn-unbound-control-setup))
$(eval $(call BuildPackage,sidn-unbound-host))
$(eval $(call BuildPackage,sidn-libunbound))
