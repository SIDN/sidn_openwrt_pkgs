include $(TOPDIR)/rules.mk

PKG_NAME:=sidn-extra-files
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/sidn-extra-files-$(PKG_VERSION)
PKG_SOURCE:=sidn-extra-files-utils-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=@SF/sidn-extra-files
PKG_MD5SUM:=9b7dc52656f5cbec846a7ba3299f73bd

include $(INCLUDE_DIR)/package.mk

define Package/sidn-extra-files
  SECTION:=base
  CATEGORY:=Network
  TITLE:=Extra files for SIDN ValiBox
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=http://www.sidnlabs.nl
endef

define Package/sidn-extra-files/description
 Extra files for the SIDN ValiBox
endef

define Build/Configure
endef

define Package/sidn-extra-files/install
	$(CP) -r ./files/* $(1)/

endef

$(eval $(call BuildPackage,sidn-extra-files))
