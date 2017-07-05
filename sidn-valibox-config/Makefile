include $(TOPDIR)/rules.mk

PKG_NAME:=sidn-valibox-config
PKG_VERSION:=1.2.9
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/sidn-valibox-config
PKG_SOURCE:=sidn-valibox-config.tar.gz
PKG_SOURCE_URL:=https://valibox.sidnlabs.nl/downloads/
PKG_MD5SUM:=9cc998dd3631ab685e02d43e7b59b9cf

include $(INCLUDE_DIR)/package.mk

define Package/sidn-valibox-config
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Extra files for SIDN ValiBox
  URL:=http://www.sidnlabs.nl
  DEPENDS:=+sidn-unbound +uhttpd +nginx +luci-ssl +dropbear +drill +spin +autonta
endef

define Package/sidn-extra-files/description
  This is a meta-package for the Valibox; it contains configuration files and dependencies to get all the Valibox-specific elements in place. This version is the 'general' package, tested with the GL-Inet 6461 and the GL-Inet AR-150.
endef

define Build/Configure
endef

define Package/sidn-valibox-config/install
  $(CP) -r ./files/* $(1)/
endef

$(eval $(call BuildPackage,sidn-valibox-config))
