#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=coreutils
PKG_CPE_ID:=cpe:/a:gnu:coreutils
PKG_VERSION:=9.0

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=@GNU/coreutils
PKG_HASH:=ce30acdf4a41bc5bb30dd955e9eaa75fa216b4e3deb08889ed32433c7b3b97ce

HOST_BUILD_PARALLEL := 1
PKG_FIXUP:=autoreconf

BUILD_PROGRAMS := chown cp date ginstall ln readlink seq stat touch

include $(INCLUDE_DIR)/host-build.mk

BUILD_BINS = $(BUILD_PROGRAMS:%=src/%)

HOST_CONFIGURE_ARGS += \
	 --enable-install-program=$(subst $(space),$(comma),$(strip $(BUILD_PROGRAMS)))

HOST_MAKE_FLAGS += \
	bin_PROGRAMS="$(BUILD_BINS)" noinst_PROGRAMS= pkglibexec_PROGRAMS= \
	LIBRARIES= MANS= SUBDIRS=.

define Host/Install
	$(call Host/Compile/Default,install-binPROGRAMS)
endef

$(eval $(call HostBuild))
