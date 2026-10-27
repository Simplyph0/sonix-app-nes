# NES for Sonix Plus: FCEUmm, the libretro core, linked into the SDK's libretro
# frontend as one static program.
#
#   make fetch    clones the SDK frontend and the core into ./sdk and ./core
#   make          builds build/nes for the player (needs the MIPS toolchain,
#                 see "Building" in README.md)
#   make host     builds a program for this computer, to try it off the player
#   make package  makes dist/NES/ ready to copy to <card>/Apps/
#
# Variables worth knowing: CROSS (the toolchain prefix), SDK (a checkout of
# sonix-app-sdk, default ./sdk), CORE (a checkout of libretro-fceumm).

CORE_URL := https://github.com/libretro/libretro-fceumm
CORE_REV := ac0d00a7fc01166f84c7bac01d1084ebfd2b865e
SDK_URL  := https://github.com/Simplyph0/sonix-app-sdk

SDK   ?= sdk
CORE  ?= core
CROSS ?= mipsel-rockbox-linux-gnu-
OUT   ?= build

COMMON := $(CORE)/src/drivers/libretro/libretro-common

# The cross build: the player's CPU is a 1.1 GHz MIPS32r2.
CROSS_CFLAGS := -O2 -march=mips32r2 -mno-madd4
HOST_CFLAGS  := -O2

# The pieces of libretro-common that the core expects its frontend to bring when it
# is built as a static archive.
COMMON_SRCS := \
	$(COMMON)/compat/compat_posix_string.c \
	$(COMMON)/compat/compat_snprintf.c \
	$(COMMON)/compat/compat_strcasestr.c \
	$(COMMON)/compat/compat_strl.c \
	$(COMMON)/compat/fopen_utf8.c \
	$(COMMON)/encodings/encoding_utf.c \
	$(COMMON)/file/file_path.c \
	$(COMMON)/file/file_path_io.c \
	$(COMMON)/streams/file_stream.c \
	$(COMMON)/streams/file_stream_transforms.c \
	$(COMMON)/string/stdstring.c \
	$(COMMON)/time/rtime.c \
	$(COMMON)/vfs/vfs_implementation.c

.PHONY: all host fetch package clean

all:
	$(MAKE) build-for CC=$(CROSS)gcc AR=$(CROSS)ar CFLAGS_ARCH="$(CROSS_CFLAGS)" LDFLAGS_EXTRA="-static -s" OUTDIR=$(OUT)

host:
	$(MAKE) build-for CC=gcc AR=ar CFLAGS_ARCH="$(HOST_CFLAGS)" LDFLAGS_EXTRA= OUTDIR=$(OUT)-host

fetch:
	test -d $(SDK) || git clone --depth 1 $(SDK_URL) $(SDK)
	test -d $(CORE) || (git clone $(CORE_URL) $(CORE) && git -C $(CORE) checkout $(CORE_REV))

# ---- the real build, run with CC, AR, CFLAGS_ARCH, LDFLAGS_EXTRA and OUTDIR set ----

build-for: $(OUTDIR)/nes

CORE_LIB := $(OUTDIR)/libfceumm.a

# CFLAGS goes in through the environment, not the command line: the core's Makefile adds its
# own definitions with +=, which a value given on the command line would silence.
$(CORE_LIB):
	mkdir -p $(OUTDIR)
	CFLAGS="$(CFLAGS_ARCH)" $(MAKE) -C $(CORE) -f Makefile.libretro platform=unix STATIC_LINKING=1 		WANT_32BPP=0 HAVE_HDPACK=0 HAVE_NTSC=0 fpic= CC="$(CC)" AR="$(AR)" clean-objs
	CFLAGS="$(CFLAGS_ARCH)" $(MAKE) -C $(CORE) -f Makefile.libretro platform=unix STATIC_LINKING=1 		WANT_32BPP=0 HAVE_HDPACK=0 HAVE_NTSC=0 fpic= CC="$(CC)" AR="$(AR)" -j$$(nproc)
	cp $(CORE)/fceumm_libretro.so $@

$(OUTDIR)/nes: $(CORE_LIB) $(SDK)/frontend/sonix_libretro.c $(SDK)/include/sonixapp.h
	$(CC) $(CFLAGS_ARCH) -Wall -I$(SDK)/include -I$(COMMON)/include \
		-DSONIX_SYSTEM='"NES"' -DSONIX_LAYOUT=LAYOUT_NES \
		-D__LIBRETRO__ -DPATH_MAX=1024 \
		-o $@ $(SDK)/frontend/sonix_libretro.c $(COMMON_SRCS) $(CORE_LIB) -lm $(LDFLAGS_EXTRA)

package: all
	rm -rf dist/NES && mkdir -p dist/NES
	cp $(OUT)/nes dist/NES/nes
	cp manifest.ini icon.png dist/NES/
	@echo "dist/NES is ready: copy it to <card>/Apps/"

clean:
	rm -rf $(OUT) $(OUT)-host dist
