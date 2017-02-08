include $(TOPDIR)/rules.mk

PKG_NAME:=spincold
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/spincold-$(PKG_VERSION)
PKG_SOURCE:=spincold-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://tjeb.nl
PKG_MD5SUM:=850c285a7ae73e6488c0d53bf129cf0a

include $(INCLUDE_DIR)/package.mk

define Package/spincold
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=Collector tools for SPIN
  #DESCRIPTION:=This variable is obsolete. use the Package/name/description define instead!
  URL:=http://www.sidnlabs.nl
  DEPENDS:=+conntrack +libnetfilter-conntrack
endef

define Package/spincold/description
 Collector tools for SPIN
endef

define Build/Configure
endef

define Package/spincold/install
  $(CP) -r ./files/* $(1)/
endef

$(eval $(call BuildPackage,spincold))
