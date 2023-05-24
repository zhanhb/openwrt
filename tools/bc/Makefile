# 
# Copyright (C) 2013-2022 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=bc
PKG_VERSION:=6.6.0

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=https://github.com/gavinhoward/bc/releases/download/$(PKG_VERSION)
PKG_HASH:=309ef0faebf149376aa69446a496fac13c3ff483a100a51d9c67cea1a73b2906

PKG_FIXUP := autoreconf

HOSTCC := $(HOSTCC_NOCACHE)
HOSTCXX := $(HOSTCXX_NOCACHE)

include $(INCLUDE_DIR)/host-build.mk

HOST_CONFIGURE_ARGS := \
	--disable-nls \
	--disable-man-pages \
	--prefix=$(HOST_BUILD_PREFIX)

define Host/Uninstall
	-$(call Host/Compile/Default,uninstall)
endef

$(eval $(call HostBuild))
