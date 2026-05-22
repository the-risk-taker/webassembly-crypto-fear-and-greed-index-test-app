# Getting Emscripten

Qt 6.11.1 WASM requires exactly `Emscripten 4.0.7` via emsdk.

## Install emsdk

```shell
git clone https://github.com/emscripten-core/emsdk.git ~/opt/wasm
cd ~/opt/wasm
./emsdk install 4.0.7
./emsdk activate 4.0.7
```

No need to source `emsdk_env.sh` - the build commands in [building.md](building.md) pass `EMSDK` and `PATH` inline.

## Verify

```shell
~/opt/wasm/upstream/emscripten/emcc --version
```

## Notes

- Do not use a different Emscripten version - Qt's toolchain is tested against a specific release and mismatches cause build errors.
- emsdk also installs a bundled Node.js under `node/current/bin/` which is required during the WASM build.
