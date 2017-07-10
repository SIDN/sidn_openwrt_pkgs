include $(TOPDIR)/rules.mk

PKG_NAME:=sidn-valibox-all-mt300a
PKG_VERSION:=1.3.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/sidn-valibox-all-mt300a
  SECTION:=base
  CATEGORY:=SIDN
  TITLE:=SIDN Valibox metapackage
  SUBMENU:=Collections
  URL:=http://www.sidnlabs.nl
  DEPENDS:= +autonta +drill +dropbear +luci-ssl +nginx +sidn-unbound +sidn-unbound-anchor +sidn-unbound-control +sidn-unbound-control-setup +sidn-unbound-host +sidn-valibox-config-mt300a +spin +uhttpd

  MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
endef

define Package/sidn-valibox-all-mt300a/description
  This is a meta-package to select all the Valibox and SPIN components and dependencies. This collection is specific for the GL-Inet MT300A
endef

$(eval $(call BuildPackage,sidn-valibox-all-mt300a))

