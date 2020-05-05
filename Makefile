LIBOPUS=./opus-native
BUILD = ./build

CC = em++
INCLUDES = -I $(LIBOPUS)/include/

FLAGS=\
 -Wall \
 -O3 \
 --bind \
 --llvm-lto 3 \
 -s ALLOW_MEMORY_GROWTH=1 \
 --memory-init-file 0 \
 -s NO_FILESYSTEM=1 \
 -s EXPORTED_RUNTIME_METHODS="['setValue', 'getValue']" \
 -s EXPORTED_FUNCTIONS="['_malloc', '_opus_strerror']" \
 -s MODULARIZE=1


CONFIGURATIONS=\
--disable-extra-programs\
--disable-doc\
--disable-intrinsics\


.PHONY: init build_dir wrapper link cleanmake cleanlib clean

all: init

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
.PHONY: config libopus
init: config libopus

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


# create build folder
build_dir: $(BUILD)/ # .PHONY target
$(BUILD)/:
	mkdir -p $@

# compile the wraper to bitcode object file (wasm bitcode)
wrapper: build $(BUILD)/wrapper.o			# PHONY target
$(BUILD)/wrapper.o: src/opusscript_encoder.cpp
	$(CC) ${FLAGS} $(INCLUDES) -c -o $@ $^

# statically link wrapper and library (wasm bitcode)
link: build $(BUILD)/libopus.js			# PHONY target
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

cleanlibopus:
	emmake make -C $(LIBOPUS) clean
	rm -rf $(LIBOPUS)/a.out $(LIBOPUS)/a.out.js $(LIBOPUS)/a.out.wasm

cleanconfig:
	make -C $(LIBOPUS) distclean



copy_licence:
	cp -f opus-native/COPYING $(BUILD)/COPYING.libopus;
