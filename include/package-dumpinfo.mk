# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2020 OpenWrt.org

ifneq ($(DUMP),)


define SOURCE_INFO
$(call addfield,Build-Depends,$(PKG_BUILD_DEPENDS))$\
$(call addfield,Build-Depends/host,$(HOST_BUILD_DEPENDS))$\
$(call addfield,Build-Types,$(BUILD_TYPES))$\
$(newline)
endef

define Dumpinfo/Package
$(info $(SOURCE_INFO)$\
$(call addfield,Package,$(1))$\
$(call addfield,Menu,$(MENU))$\
$(call addfield,Submenu,$(SUBMENU))$\
$(call addfield,Submenu-Depends,$(SUBMENUDEP))$\
$(call addfield,Default,$(DEFAULT))$\
$(call addfield,Prereq-Check,$(findstring $(PREREQ_CHECK),1))$\
$(call addfield,Version,$(VERSION))$\
$(call addfield,Depends,$(call PKG_FIXUP_DEPENDS,$(1),$(DEPENDS)))$\
$(call addfield,Conflicts,$(CONFLICTS))$\
$(call addfield,Menu-Depends,$(MDEPENDS))$\
$(call addfield,Provides,$(PROVIDES))$\
$(call addfield,Build-Variant,$(VARIANT))$\
$(call addfield,Default-Variant,$(if $(DEFAULT_VARIANT),$(VARIANT)))$\
$(call addfield,Section,$(SECTION))$\
$(call addfield,Category,$(CATEGORY))$\
$(call addfield,Repository,$(if $(filter nonshared,$(PKGFLAGS)),,$(or $(FEED),base)))$\
$(call addfield,Title,$(TITLE))$\
$(call addfield,Maintainer,$(MAINTAINER))$\
$(call addfield,Require-User,$(USERID))$\
$(call addfield,Source,$(PKG_SOURCE))$\
$(call addfield,License,$(LICENSE))$\
$(call addfield,LicenseFiles,$(LICENSE_FILES))$\
$(call addfield,PKG_CPE_ID,$(PKG_CPE_ID))$\
$(call addfield,ABI-Version,$(ABI_VERSION))$\
$(call addfield,Type,$(or $(Package/$(1)/targets),$(PKG_TARGETS),ipkg))$\
$(call addfield,Kernel-Config,$(KCONFIG))$\
$(call addfield,Build-Only,$(BUILDONLY))$\
$(call addfield,Hidden,$(HIDDEN))$\
Description: $(or $(Package/$(1)/description),$(TITLE))
$(if $(URL),$(URL)$(newline))$\
$(if $(MAINTAINER),$(MAINTAINER)$(newline))$\
@@
$(if $(Package/$(1)/config),Config:$(newline)$(Package/$(1)/config)$(newline)@@$(newline)))
SOURCE_INFO :=
endef

dumpinfo: FORCE
	$(if $(SOURCE_INFO),$(info $(SOURCE_INFO)))

endif
