#
# Copyright (C) 2010-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=missing-macros
PKG_RELEASE:=11

include $(INCLUDE_DIR)/host-build.mk

define Host/Configure
endef

define Host/Compile
endef

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/aclocal
	$(INSTALL_DATA) ./src/m4/*.m4 $(STAGING_DIR_HOST)/share/aclocal/
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/bin
	$(INSTALL_BIN) ./src/bin/* $(STAGING_DIR_HOST)/bin/
endef

define Host/Clean
	$(RM) \
		$(patsubst %,$(STAGING_DIR_HOST)/bin/%,$(notdir $(wildcard src/bin/*))) \
		$(patsubst %,$(STAGING_DIR_HOST)/share/aclocal/%,$(notdir $(wildcard src/m4/*.m4)))
endef

$(eval $(call HostBuild))
