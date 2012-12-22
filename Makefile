
# Makefile to build the steam-root chroot environments
#
# In order to build the amd64 environment you must be running amd64

VERSION := 1.0.0

ifeq ($(shell dpkg --print-architecture), amd64)
ARCHES := i386 amd64
else
ARCHES := i386
endif

all:
	@if [ "$(ARCH)" ]; then \
		./create.sh $(ARCH) $(VERSION); \
	else \
		for arch in $(ARCHES); do make ARCH=$$arch; done; \
	fi

create update archive shell:
	@if [ "$(ARCH)" ]; then \
		./create.sh $(ARCH) $(VERSION) --$@; \
	else \
		for arch in $(ARCHES); do make $@ ARCH=$$arch; done; \
	fi

clean:
	@if [ "$(ARCH)" ]; then \
		rm -rf $(ARCH)/steam-root; \
	else \
		for arch in $(ARCHES); do make clean ARCH=$$arch; done; \
	fi

distclean:
	rm -rf $(ARCHES)
	rm -vf steam-root*.tgz
