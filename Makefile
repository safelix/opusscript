LIBOPUS=./opus-native
BUILD = ./build

EMCC_OPTS=-Wall -O3 --llvm-lto 3 -s ALLOW_MEMORY_GROWTH=1 --memory-init-file 0 -s NO_FILESYSTEM=1 -s EXPORTED_RUNTIME_METHODS="['setValue', 'getValue']" -s EXPORTED_FUNCTIONS="['_malloc', '_opus_strerror']" -s MODULARIZE=1


.PHONY: build_dir

all: init compile

# create build folder
build_dir: $(BUILD)/ # .PHONY target
$(BUILD)/:
	mkdir -p $@

autogen:
	cd $(LIBOPUS); \
	./autogen.sh
configure:
	cd $(LIBOPUS); \
	emconfigure ./configure --disable-extra-programs --disable-doc --disable-intrinsics
bind:
	cd $(LIBOPUS); \
	emmake make; \

init: autogen configure bind
compile: build_dir
	em++ ${EMCC_OPTS} --bind -o $(BUILD)/opusscript_native_wasm.js src/opusscript_encoder.cpp ${LIBOPUS}/.libs/libopus.a; \
	cp -f opus-native/COPYING $(BUILD)/COPYING.libopus;

clean:
	rm -rf $(BUILD) $(LIBOPUS)/a.out $(LIBOPUS)/a.out.js $(LIBOPUS)/a.out.wasm