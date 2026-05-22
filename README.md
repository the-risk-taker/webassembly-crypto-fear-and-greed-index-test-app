# Fear & Greed Index Terminal

![Qt](https://img.shields.io/badge/Qt-6.11.1-41CD52?logo=qt&logoColor=white)
![WebAssembly](https://img.shields.io/badge/WebAssembly-multithreaded-654FF0?logo=webassembly&logoColor=white)
![Emscripten](https://img.shields.io/badge/Emscripten-4.0.7-8A2BE2)
![License](https://img.shields.io/badge/license-MIT-blue)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Browser-lightgrey)

A Qt Quick app served from a LAN server and accessed from a browser on any device on the network.

## Features

- Login page (hardcoded credentials: `admin` / `cyber`)
- Cyberpunk / terminal aesthetic - dark navy dashboard
- Crypto Fear & Greed index fetched from [alternative.me API](https://alternative.me/crypto/api/)
- Builds for Linux desktop and WebAssembly

## Prerequisites

- CMake, Ninja
- Qt 6.11.1 at `/home/$USER/opt/qt/` (`gcc_64` + `wasm_multithread`)
- Emscripten 4.0.7 via emsdk at `/home/$USER/opt/wasm` (WASM builds only) - see [docs/getting-emscriptem.md](docs/getting-emscriptem.md)
- Python 3 (for the dev server and deploy server)

## Quick start

See [docs/building.md](docs/building.md) for full build instructions.

## Project structure

```plaintext
.
├── app     Qt Quick app source (QML, C++, CMake)
├── docs    Build and deployment documentation
└── server  Python HTTP server with required COOP/COEP headers
```

## Deployment

See [docs/deploy.md](docs/deploy.md). In short:

On the server: extract the archive and run `serve.py`. No Qt libraries needed - everything is statically linked into the `.wasm` file.
