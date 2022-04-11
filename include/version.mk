# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2012-2015 OpenWrt.org
# Copyright (C) 2016 LEDE Project

# Substituted by SDK, do not remove
# REVISION:=x
# SOURCE_DATE_EPOCH:=x

PKG_CONFIG_DEPENDS += \
	CONFIG_VERSION_HOME_URL \
	CONFIG_VERSION_BUG_URL \
	CONFIG_VERSION_NUMBER \
	CONFIG_VERSION_CODE \
	CONFIG_VERSION_REPO \
	CONFIG_VERSION_DIST \
	CONFIG_VERSION_MANUFACTURER \
	CONFIG_VERSION_MANUFACTURER_URL \
	CONFIG_VERSION_PRODUCT \
	CONFIG_VERSION_SUPPORT_URL \
	CONFIG_VERSION_HWREV \

sanitize = $(call tolower,$(subst _,-,$(subst $(space),-,$(1))))

VERSION_NUMBER:=$(or $(call qstrip,$(CONFIG_VERSION_NUMBER)),23.05-SNAPSHOT)
VERSION_CODE:=$(or $(call qstrip,$(CONFIG_VERSION_CODE)),$(REVISION))
VERSION_REPO:=$(or $(call qstrip,$(CONFIG_VERSION_REPO)),https://downloads.openwrt.org/releases/23.05-SNAPSHOT)
VERSION_DIST:=$(or $(call qstrip,$(CONFIG_VERSION_DIST)),OpenWrt)
VERSION_MANUFACTURER:=$(or $(call qstrip,$(CONFIG_VERSION_MANUFACTURER)),OpenWrt)
VERSION_MANUFACTURER_URL:=$(or $(call qstrip,$(CONFIG_VERSION_MANUFACTURER_URL)),https://openwrt.org/)
VERSION_BUG_URL:=$(or $(call qstrip,$(CONFIG_VERSION_BUG_URL)),https://bugs.openwrt.org/)
VERSION_HOME_URL:=$(or $(call qstrip,$(CONFIG_VERSION_HOME_URL)),https://openwrt.org/)
VERSION_SUPPORT_URL:=$(or $(call qstrip,$(CONFIG_VERSION_SUPPORT_URL)),https://forum.openwrt.org/)
VERSION_PRODUCT:=$(or $(call qstrip,$(CONFIG_VERSION_PRODUCT)),Generic)
VERSION_HWREV:=$(or $(call qstrip,$(CONFIG_VERSION_HWREV)),v0)

VERSION_DIST_SANITIZED:=$(call sanitize,$(VERSION_DIST))

taint2sym=$(CONFIG_$(firstword $(subst :, ,$(subst +,,$(subst -,,$(1))))))
taint2name=$(lastword $(subst :, ,$(1)))

VERSION_TAINT_SPECS := \
	-ALL_KMODS:no-all \
	-IPV6:no-ipv6 \
	+USE_GLIBC:glibc \
	+USE_MKLIBS:mklibs \
	+BUSYBOX_CUSTOM:busybox \
	+OVERRIDE_PKGS:override \

VERSION_TAINTS := $(strip $(foreach taint,$(VERSION_TAINT_SPECS), \
	$(if $(findstring +,$(taint)), \
		$(if $(call taint2sym,$(taint)),$(call taint2name,$(taint))), \
		$(if $(call taint2sym,$(taint)),,$(call taint2name,$(taint))) \
	)))

PKG_CONFIG_DEPENDS += $(foreach taint,$(VERSION_TAINT_SPECS),$(call taint2sym,$(taint)))

# escape commas, backslashes, quotes, and ampersands for sed
sed_escape=$(subst &,\&,$(subst $(comma),\$(comma),$(subst ','\'',$(subst \,\\,$(1)))))#'))#)

VERSION_SED_SCRIPT:=$(SED) 's,%U,$(call sed_escape,$(VERSION_REPO)),g' \
	-e 's,%V,$(call sed_escape,$(VERSION_NUMBER)),g' \
	-e 's,%v,\L$(call sed_escape,$(subst $(space),_,$(VERSION_NUMBER))),g' \
	-e 's,%C,$(call sed_escape,$(VERSION_CODE)),g' \
	-e 's,%c,\L$(call sed_escape,$(subst $(space),_,$(VERSION_CODE))),g' \
	-e 's,%D,$(call sed_escape,$(VERSION_DIST)),g' \
	-e 's,%d,\L$(call sed_escape,$(subst $(space),_,$(VERSION_DIST))),g' \
	-e 's,%R,$(call sed_escape,$(REVISION)),g' \
	-e 's,%T,$(call sed_escape,$(BOARD)),g' \
	-e 's,%S,$(call sed_escape,$(BOARD)/$(or $(SUBTARGET),generic)),g' \
	-e 's,%A,$(call sed_escape,$(ARCH_PACKAGES)),g' \
	-e 's,%t,$(call sed_escape,$(VERSION_TAINTS)),g' \
	-e 's,%M,$(call sed_escape,$(VERSION_MANUFACTURER)),g' \
	-e 's,%m,$(call sed_escape,$(VERSION_MANUFACTURER_URL)),g' \
	-e 's,%b,$(call sed_escape,$(VERSION_BUG_URL)),g' \
	-e 's,%u,$(call sed_escape,$(VERSION_HOME_URL)),g' \
	-e 's,%s,$(call sed_escape,$(VERSION_SUPPORT_URL)),g' \
	-e 's,%P,$(call sed_escape,$(VERSION_PRODUCT)),g' \
	-e 's,%h,$(call sed_escape,$(VERSION_HWREV)),g'

