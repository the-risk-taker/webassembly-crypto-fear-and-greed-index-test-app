# How to build

## Desktop

Configure:

```shell
cmake -S . -B build-linux -G Ninja \
  -DCMAKE_PREFIX_PATH=~/opt/qt/6.11.1/gcc_64 \
  -DCMAKE_BUILD_TYPE=Debug
```

Build:

```shell
ninja -C build-linux
```

Run

```shell
ninja -C build-linux run-app
```

## WebAssembly

Requires emsdk at `~/opt/wasm` with Emscripten 4.0.7 installed and activated.
See [getting-emscriptem.md](getting-emscriptem.md) for setup instructions.

### Configure

```shell
export EMSDK=~/opt/wasm
export PATH="$HOME/opt/wasm/upstream/emscripten:$HOME/opt/wasm/node/current/bin:$PATH"

cmake -S . -B build-wasm -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=~/opt/qt/6.11.1/wasm_multithread/lib/cmake/Qt6/qt.toolchain.cmake \
  -DQT_HOST_PATH=~/opt/qt/6.11.1/gcc_64 \
  -DCMAKE_BUILD_TYPE=Release
```

### Build

```shell
ninja -C build-wasm
```

### Deploy package

```shell
ninja -C build-wasm deploy
```

### Serve

```shell
ninja -C build-wasm serve
```

Output: `build-wasm/deploy/appwebassembly.tar.gz` + unpacked files in `build-wasm/deploy/sources/`.
