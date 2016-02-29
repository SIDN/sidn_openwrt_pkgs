#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sidn_dnsmasq
PKG_VERSION:=2.75_sidn1
PKG_RELEASE:=5

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=http://thekelleys.org.uk/dnsmasq
PKG_MD5SUM:=887236f1ddde6eb57cdb9d01916c9f72

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_CONFIG_DEPENDS:=CONFIG_PACKAGE_dnsmasq_$(BUILD_VARIANT)_dhcpv6 \
	CONFIG_PACKAGE_dnsmasq_$(BUILD_VARIANT)_dnssec \
	CONFIG_PACKAGE_dnsmasq_$(BUILD_VARIANT)_auth \
	CONFIG_PACKAGE_dnsmasq_$(BUILD_VARIANT)_ipset

include $(INCLUDE_DIR)/package.mk

define Package/sidn_dnsmasq/Default
  SECTION:=base
  CATEGORY:=Network
  SUBMENU:=SIDN
  TITLE:=DNS and DHCP server
  URL:=http://www.thekelleys.org.uk/dnsmasq/
endef

define Package/sidn_dnsmasq
$(call Package/sidn_dnsmasq/Default)
  VARIANT:=nodhcpv6
endef

define Package/sidn_dnsmasq-dhcpv6
$(call Package/sidn_dnsmasq/Default)
  TITLE += (with DHCPv6 support)
  DEPENDS:=@IPV6
  VARIANT:=dhcpv6
endef

define Package/sidn_dnsmasq-full
$(call Package/sidn_dnsmasq/Default)
  TITLE += (with DNSSEC, DHCPv6, Auth DNS, IPset enabled by default)
  DEPENDS:=+PACKAGE_sidn_dnsmasq_full_dnssec:libnettle \
	+PACKAGE_sidn_dnsmasq_full_ipset:kmod-ipt-ipset
  VARIANT:=full
endef

define Package/sidn_dnsmasq/description
  It is intended to provide coupled DNS and DHCP service to a LAN.
endef

define Package/sidn_dnsmasq-dhcpv6/description
$(call Package/sidn_dnsmasq/description)

This is a variant with DHCPv6 support
endef

define Package/sidn_dnsmasq-full/description
$(call Package/sidn_dnsmasq/description)

This is a fully configurable variant with DHCPv6, DNSSEC, Authroitative DNS and
IPset support enabled by default.
endef

define Package/sidn_dnsmasq/conffiles
/etc/config/dhcp
/etc/dnsmasq.conf
endef

define Package/sidn_dnsmasq-full/config
	if PACKAGE_sidn_dnsmasq-full
	config PACKAGE_sidn_dnsmasq_full_dhcpv6
		bool "Build with DHCPv6 support."
		depends on IPV6
		default y
	config PACKAGE_sidn_dnsmasq_full_dnssec
		bool "Build with DNSSEC support."
		default y
	config PACKAGE_sidn_dnsmasq_full_auth
		bool "Build with the facility to act as an authoritative DNS server."
		default y
	config PACKAGE_sidn_dnsmasq_full_ipset
		bool "Build with IPset support."
		default y
	endif
endef

Package/sidn_dnsmasq-dhcpv6/conffiles = $(Package/sidn_dnsmasq/conffiles)
Package/sidn_dnsmasq-full/conffiles = $(Package/sidn_dnsmasq/conffiles)

TARGET_CFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

COPTS = $(if $(CONFIG_IPV6),,-DNO_IPV6)

ifeq ($(BUILD_VARIANT),nodhcpv6)
	COPTS += -DNO_DHCP6
endif

ifeq ($(BUILD_VARIANT),full)
	COPTS += $(if $(CONFIG_PACKAGE_sidn_dnsmasq_$(BUILD_VARIANT)_dhcpv6),,-DNO_DHCP6) \
		$(if $(CONFIG_PACKAGE_sidn_dnsmasq_$(BUILD_VARIANT)_dnssec),-DHAVE_DNSSEC) \
		$(if $(CONFIG_PACKAGE_sidn_dnsmasq_$(BUILD_VARIANT)_auth),,-DNO_AUTH) \
		$(if $(CONFIG_PACKAGE_sidn_dnsmasq_$(BUILD_VARIANT)_ipset),,-DNO_IPSET)
	COPTS += $(if $(CONFIG_LIBNETTLE_MINI),-DNO_GMP,)
else
	COPTS += -DNO_AUTH -DNO_IPSET
endif

MAKE_FLAGS := \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)" \
	COPTS="$(COPTS)" \
	PREFIX="/usr"

define Package/sidn_dnsmasq/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/dnsmasq $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/dhcp.conf $(1)/etc/config/dhcp
	$(INSTALL_DATA) ./files/dnsmasq.conf $(1)/etc/dnsmasq.conf
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/dnsmasq.init $(1)/etc/init.d/dnsmasq
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) ./files/dnsmasq.hotplug $(1)/etc/hotplug.d/iface/25-dnsmasq
endef

Package/sidn_dnsmasq-dhcpv6/install = $(Package/sidn_dnsmasq/install)

define Package/sidn_dnsmasq-full/install
$(call Package/sidn_dnsmasq/install,$(1))
ifneq ($(CONFIG_PACKAGE_sidn_dnsmasq_full_dnssec),)
	$(INSTALL_DIR) $(1)/usr/share/dnsmasq
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/trust-anchors.conf $(1)/usr/share/dnsmasq
endif
endef

$(eval $(call BuildPackage,sidn_dnsmasq))
$(eval $(call BuildPackage,sidn_dnsmasq-dhcpv6))
$(eval $(call BuildPackage,sidn_dnsmasq-full))
