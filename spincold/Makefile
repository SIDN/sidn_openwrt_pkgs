include $(TOPDIR)/rules.mk

PKG_NAME:=spincold
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/spincold-$(PKG_VERSION)
PKG_SOURCE:=spincold-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://tjeb.nl
PKG_MD5SUM:=8fc24f78ae2df702350e5290c6000cf4

include $(INCLUDE_DIR)/package.mk

define Package/spincold
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Collector tools for SPIN
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=http://www.sidnlabs.nl
  #DEPENDS:=+conntrack +libnetfilter-conntrack +libwebsockets-full
  DEPENDS:=+libwebsockets-full
endef

define Package/spincold/description
 Collector tools for SPIN
endef

#define Build/Configure
#endef

define Package/spincold/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/webfoot $(1)/usr/sbin/sc-webfoot
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/conntrack $(1)/usr/sbin/sc-conntrack
endef

$(eval $(call BuildPackage,spincold))
