ifeq ($(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init --recursive
	$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

LIBRARY_NAME = CycriptLoader
CycriptLoader_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
CycriptLoader_OBJCC_FILES = CycriptLoader.mm

include framework/makefiles/common.mk
include framework/makefiles/library.mk

endif
