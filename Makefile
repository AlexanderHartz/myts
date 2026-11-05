# myts - Kindle terminal, KUAL build
#
# K3 cross build (downloads the musl toolchain on first use):
#   make k3
#
# Native build on an ARM Linux host with musl-gcc:
#   make
#
# Package the KUAL extension:
#   make zip

CROSS_COMPILE ?=

ifeq ($(CROSS_COMPILE),)
CC = musl-gcc
STRIP = strip
CFLAGS = -static -Os -Wall -Werror
CFLAGS += -isystem /usr/lib/musl/include -isystem /usr/include
else
CC = $(CROSS_COMPILE)gcc
STRIP = $(CROSS_COMPILE)strip
CFLAGS = -static -no-pie -fno-pie -Os -Wall -Werror
endif

SRC_DIR = src
BUILD_DIR = build
DIST_DIR = dist
KUAL_DIR = kual/extensions/myts
KUAL_BIN = $(KUAL_DIR)/bin/myts

TOOLCHAIN_DIR = toolchain/armv6-linux-musleabi-cross
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/bin/armv6-linux-musleabi-
TOOLCHAIN_GCC = $(TOOLCHAIN_PREFIX)gcc
TOOLCHAIN_URL = https://musl.cc/armv6-linux-musleabi-cross.tgz

SOURCES = myts.c terminal.c dynstring.c config.c myts_app.c screen.c pixop.c font.c
SRCS = $(addprefix $(SRC_DIR)/,$(SOURCES))
OBJS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))
HEADERS = $(wildcard $(SRC_DIR)/*.h) $(wildcard $(SRC_DIR)/linux/*.h)

CFLAGS += -I$(SRC_DIR) -DNODEBUG

.PHONY: all kual zip k3 toolchain clean

all: $(BUILD_DIR)/myts

kual: $(BUILD_DIR)/myts
	@mkdir -p $(KUAL_DIR)/bin
	cp $(BUILD_DIR)/myts $(KUAL_BIN)

$(BUILD_DIR)/myts: $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)
	$(STRIP) $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

k3: $(TOOLCHAIN_GCC)
	$(MAKE) kual CROSS_COMPILE=$(TOOLCHAIN_PREFIX)

$(TOOLCHAIN_GCC):
	@mkdir -p toolchain
	curl -fL $(TOOLCHAIN_URL) -o toolchain/toolchain.tgz
	tar xzf toolchain/toolchain.tgz -C toolchain
	rm -f toolchain/toolchain.tgz

toolchain: $(TOOLCHAIN_GCC)

zip:
	@test -f $(KUAL_BIN) || { echo "Missing $(KUAL_BIN); run make k3 first"; exit 1; }
	@mkdir -p $(DIST_DIR)
	rm -f $(DIST_DIR)/myts-kual.zip
	cd kual && zip -r ../$(DIST_DIR)/myts-kual.zip extensions
	@echo "Created $(DIST_DIR)/myts-kual.zip"

clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	rm -f *.o
