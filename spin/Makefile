include $(TOPDIR)/rules.mk

PKG_NAME:=spin
PKG_VERSION:=0.7-beta
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/spin-$(PKG_VERSION)
PKG_SOURCE:=spin-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://valibox.sidnlabs.nl/downloads/src/spin/
PKG_HASH:=9160d4cd28e46f92794e0302ac84e64501044b68effc2d991c1b9bf23e14bec0

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

TARGET_CFLAGS += -ggdb3 

define Package/spin
  SECTION:=base
  CATEGORY:=SIDN
  TITLE:=Experimental tools for SPIN
  URL:=https://github.com/SIDN/spin
  DEPENDS:=+ip +luaposix +luasec +luabitop +luasocket +mosquitto-ssl +libmosquitto +lua-mosquitto +libnfnetlink +lua-minittp +lua-websockets
  MAINTAINER:=Jelte Jansen <jelte.jansen@sidn.nl>
endef

PKG_BUILD_DEPENDS:=libmosquitto libnfnetlink

SPIN_MAKE_OPTS:= -C $(PKG_BUILD_DIR) \
        PATH="$(TARGET_PATH)" \
        ARCH="$(LINUX_KARCH)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        TARGET="$(HAL_TARGET)" \
        TOOLPREFIX="$(KERNEL_CROSS)" \
        TOOLPATH="$(KERNEL_CROSS)" \
        KERNELPATH="$(LINUX_DIR)" \
        LDOPTS=" "

define Package/spin/description
  Experiment with SPIN tools
endef

define Build/Configure
    $(call Build/Configure/Default,--with-linux-headers=$(LINUX_DIR))
endef

define Build/Compile
  $(MAKE) $(SPIN_MAKE_OPTS) M=$(PKG_BUILD_DIR)
endef

define Package/spin/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/rc.d
	cp -r ./files/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/spin/web_ui
	cp -r ${PKG_BUILD_DIR}/web_ui/* $(1)/usr/lib/spin/web_ui
	$(INSTALL_DIR) $(1)/usr/lib/spin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/lua/*.lua $(1)/usr/lib/spin/
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/kernelmod/spin.ko $(1)/usr/lib/spin/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/spin_config $(1)/usr/bin/spin_config
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/spin_print $(1)/usr/bin/spin_print
	$(INSTALL_BIN) ${PKG_BUILD_DIR}/src/spind $(1)/usr/bin/spind
	$(INSTALL_DIR) $(1)/etc/spin
endef

$(eval $(call BuildPackage,spin))
