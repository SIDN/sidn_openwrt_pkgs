include $(TOPDIR)/rules.mk

PKG_NAME:=sidn_extra_files
PKG_VERSION:=1.0.6
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/sidn_extra_files-$(PKG_VERSION)
PKG_SOURCE:=sidn_extra_files-utils-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=@SF/sidn_extra_files
PKG_MD5SUM:=9b7dc52656f5cbec846a7ba3299f73bd

include $(INCLUDE_DIR)/package.mk

define Package/sidn_extra_files
  SECTION:=base
  CATEGORY:=Network
  TITLE:=Ethernet bridging configuration utility
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=http://sidn_extra_files.sourceforge.net/
endef

define Package/sidn_extra_files/description
 Extra files for the SIDN ValiBox
endef

define Build/Configure
endef

define Package/sidn_extra_files/install
endef

$(eval $(call BuildPackage,sidn_extra_files))
