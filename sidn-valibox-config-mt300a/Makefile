include $(TOPDIR)/rules.mk

PKG_NAME:=sidn-valibox-config-mt300a
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/sidn-valibox-config-mt300a
PKG_SOURCE:=sidn-valibox-config-mt300a.tar.gz
PKG_SOURCE_URL:=https://tjeb.nl
PKG_MD5SUM:=fc0960393a32ee22fdc73aa14c53ceda

include $(INCLUDE_DIR)/package.mk

define Package/sidn-valibox-config-mt300a
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Extra files for SIDN ValiBox (mt300a specifics)
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=http://www.sidnlabs.nl
  DEPENDS:=+sidn-unbound +uhttpd +nginx +python-webpy +luci-ssl +dropbear +drill
endef

define Package/sidn-valibox-config-mt300a/description
 Extra files for the SIDN ValiBox
endef

define Build/Configure
endef

define Package/sidn-valibox-config-mt300a/install
  $(CP) -r ./files/* $(1)/
endef

$(eval $(call BuildPackage,sidn-valibox-config-mt300a))
