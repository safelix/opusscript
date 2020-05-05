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


.PHONY: build_dir opusmakefile lib wrapper link cleanmake cleanlib clean

all: init compile

# create build folder
build_dir: $(BUILD)/ # .PHONY target
$(BUILD)/:
	mkdir -p $@

# generate Makefile for libopus
opusmakefile: $(LIBOPUS)/Makefile # .PHONY target
$(LIBOPUS)/Makefile:
	cd $(LIBOPUS); \
	./autogen.sh
	emconfigure ./configure $(CONFIGURATIONS)

# compile the library to shared object file (wasm bitcode)
lib: ${LIBOPUS}/.libs/libopus.so 	# PHONY target
${LIBOPUS}/.libs/libopus.so: $(LIBOPUS)/Makefile
	cd $(LIBOPUS); \
	emmake make;

init: opusmakefile lib

# compile the wraper to bitcode object file (wasm bitcode)
wrapper: build $(BUILD)/wrapper.o			# PHONY target
$(BUILD)/wrapper.o: src/opusscript_encoder.cpp
	$(CC) ${FLAGS} $(INCLUDES) -c -o $@ $^

# statically link wrapper and library (wasm bitcode)
link: build $(BUILD)/libopus.js			# PHONY target
$(BUILD)/libopus.js: ${LIBOPUS}/.libs/libopus.so $(BUILD)/wrapper.o
	$(CC) $(FLAGS) $(INCLUDES) -o $@ $^ 

clean:
	rm -rf $(BUILD) $(LIBOPUS)/a.out $(LIBOPUS)/a.out.js $(LIBOPUS)/a.out.wasm

cleanlib:
	emmake make -C $(LIBOPUS) clean; \

cleanmake:
	make -C $(LIBOPUS) distclean

copy_licence:
	cp -f opus-native/COPYING $(BUILD)/COPYING.libopus;
