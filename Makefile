LIBOPUS=./opus-native
BUILD = ./build
SRC = ./src
DIST = ./dist

CC = em++
INCLUDES = -I $(LIBOPUS)/include/

# Set Flags as proposed by:
# https://developers.google.com/web/updates/2019/01/emscripten-npm
FLAGS=\
 -Wall \
 -O3 \
 --bind \
 -flto \
 --closure 1 \
 -s ALLOW_MEMORY_GROWTH=1 \
 -s FILESYSTEM=0 \
 -s MODULARIZE=1 \
 -s EXPORT_ES6=1 \
 -s EXPORTED_RUNTIME_METHODS="['setValue', 'getValue']" \
 -s EXPORTED_FUNCTIONS="['_malloc', '_opus_strerror']" \

define UNUSED_FLAGS
 -s STRICT=1 \

endef

CONFIGURATIONS=\
--disable-extra-programs\
--disable-doc\
--disable-intrinsics\
--disable-stack-protector 	# https://github.com/xiph/opus/issues/138


.PHONY: init build clean
all: init build

############################################################
# make init: Compiling libopus to WebAssembly
#
# 1. To configure the libopus build system, use:
# make config 
#
# 2. To compile libopus with those configurations, use:
# make libopus
#
############################################################
.PHONY: config libopus cleantemps
init: config libopus cleantemps

# configure Makefile for libopus
config: $(LIBOPUS)/Makefile # .PHONY target
$(LIBOPUS)/Makefile:
	cd $(LIBOPUS); \
	./autogen.sh; \
	emconfigure ./configure $(CONFIGURATIONS)

# compile libopus to shared object file (wasm bitcode)
libopus: ${LIBOPUS}/.libs/libopus.so 	# PHONY target
${LIBOPUS}/.libs/libopus.so: $(LIBOPUS)/Makefile
	cd $(LIBOPUS); \
	emmake make

cleantemps:
	rm -rf $(LIBOPUS)/a.out $(LIBOPUS)/a.out.js $(LIBOPUS)/a.out.wasm


############################################################
# make build: Compiling the libopus wrapper to JavaScript
#
# 1. To compile the wrapper, use:
# make wrapper
#
# 2. To link wrapper and library, use:
# make link
#
############################################################
.PHONY: wrapper link
build: wrapper link

# create build directory
$(BUILD)/:
	mkdir -p $@

# compile the wrapper to bitcode object file (wasm bitcode)
wrapper: $(BUILD)/ $(BUILD)/wrapper.o			# PHONY target
$(BUILD)/wrapper.o: $(SRC)/opusscript_encoder.cpp
	$(CC) ${FLAGS} $(INCLUDES) -c -o $@ $^

# statically link wrapper and libopus (wasm bitcode)
link: $(BUILD)/ $(BUILD)/libopus.js			# PHONY target
$(BUILD)/libopus.js: ${LIBOPUS}/.libs/libopus.so $(BUILD)/wrapper.o
	$(CC) $(FLAGS) $(INCLUDES) -o $@ $^ 


############################################################
# make clean: Cleanup Compilation Steps
#
# 1. To cleanup results of 'make build', use:
# make cleanbuild
#
# 2. To cleanup results of 'make libopus', use:
# make cleanlibopus
#
# 3. To cleanup results of 'make config', use:
# make cleanconfig
#
############################################################
.PHONY: cleanbuild cleanlibopus cleanconfig
clean: cleanbuild cleanlibopus cleanconfig

cleanbuild:
	rm -rf $(BUILD)

cleanlibopus: cleantemps
	emmake make -C $(LIBOPUS) clean

cleanconfig:
	make -C $(LIBOPUS) distclean

############################################################
# make install: Install Required Files into DIST Directory
# 
############################################################
.PHONY: copy_libopus.js copy_licence
install: copy_libopus.js copy_licence

# create distribution directory
$(DIST)/:
	mkdir -p $(DIST)/

copy_libopus.js: $(DIST)/ $(BUILD)/libopus.js
	cp -f $(BUILD)/libopus.js $(DIST)/libopus.js; \
	cp -f $(BUILD)/libopus.wasm $(DIST)/libopus.wasm

copy_licence: $(DIST)/
	cp -f opus-native/COPYING $(DIST)/COPYING.libopus;
