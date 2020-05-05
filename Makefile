LIBOPUS=./opus-native
BUILD = ./build

EMCC_OPTS=-Wall -O3 --llvm-lto 3 -s ALLOW_MEMORY_GROWTH=1 --memory-init-file 0 -s NO_FILESYSTEM=1 -s EXPORTED_RUNTIME_METHODS="['setValue', 'getValue']" -s EXPORTED_FUNCTIONS="['_malloc', '_opus_strerror']" -s MODULARIZE=1

EMCC_NASM_OPTS=-s WASM=0
EMCC_WASM_OPTS=-s WASM=1 -s WASM_ASYNC_COMPILATION=0

all: init compile
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
compile:
	mkdir -p $(BUILD); \
	em++ ${EMCC_OPTS} ${EMCC_NASM_OPTS} --bind -o $(BUILD)/opusscript_native_nasm.js src/opusscript_encoder.cpp ${LIBOPUS}/.libs/libopus.a; \
	em++ ${EMCC_OPTS} ${EMCC_WASM_OPTS} --bind -o $(BUILD)/opusscript_native_wasm.js src/opusscript_encoder.cpp ${LIBOPUS}/.libs/libopus.a; \
	cp -f opus-native/COPYING $(BUILD)/COPYING.libopus;

clean:
	rm -rf $(BUILD) $(LIBOPUS)/a.out $(LIBOPUS)/a.out.js $(LIBOPUS)/a.out.wasm