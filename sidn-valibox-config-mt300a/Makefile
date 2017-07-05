include $(TOPDIR)/rules.mk

PKG_NAME:=sidn-valibox-config-mt300a
PKG_VERSION:=1.2.9
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/sidn-valibox-config-mt300a
PKG_SOURCE:=sidn-valibox-config-mt300a.tar.gz
PKG_SOURCE_URL:=https://valibox.sidnlabs.nl/downloads/src/sidn-extra-files/
PKG_MD5SUM:=fc0960393a32ee22fdc73aa14c53ceda

include $(INCLUDE_DIR)/package.mk

define Package/sidn-valibox-config-mt300a
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Extra files for SIDN ValiBox (mt300a specifics)
  URL:=http://www.sidnlabs.nl
  DEPENDS:=+sidn-unbound +uhttpd +nginx +luci-ssl +dropbear +drill +autonta +spin
endef

define Package/sidn-valibox-config-mt300a/description
  This is a meta-package for the Valibox; it contains configuration files and dependencies to get all the Valibox-specific elements in place. This ve
rsion is specific for the GL-Inet mt300a.
endef

define Build/Configure
endef

define Package/sidn-valibox-config-mt300a/install
  $(CP) -r ./files/* $(1)/
endef

$(eval $(call BuildPackage,sidn-valibox-config-mt300a))
