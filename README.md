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
- 3 year history chart of the index overlaid with BTC/USD price from [Binance API](https://developers.binance.com/docs/binance-spot-api-docs/rest-api/market-data-endpoints), ranges 1M / 3M / 6M / 1Y / 3Y, log or linear price scale, tooltip on hover or tap
- Builds for Linux desktop and WebAssembly

## Prerequisites

- CMake, Ninja
- Qt 6.11.1 at `/home/$USER/opt/qt/` (`gcc_64` + `wasm_multithread`)
- Emscripten 4.0.7 via emsdk at `/home/$USER/opt/wasm` (WASM builds only) - see [docs/getting-emscriptem.md](docs/getting-emscriptem.md)
- Python 3 (for the dev server and deploy server)

## Mobile keyboard pops up on every tap

> [!TIP]
> **Problem:** on phones the on-screen keyboard opened on every tap anywhere in the app, not only in text fields. Qt for WebAssembly keeps a hidden `<div class="qt-window-focus-helper" contenteditable="true">` inside its shadow DOM and focuses it on every pointer event (it is used for clipboard and desktop key handling). Qt sets `inputmode="none"` on it, but mobile browsers ignore that for `contenteditable` elements and show the keyboard anyway. A second cause was in QML: calling `forceActiveFocus()` on `Window.contentItem` does not clear focus, because it is a FocusScope and gives focus back to the last focused child, so the hidden password field kept focus after login.
>
> **Fix:**
> - `app/loading.html` - `disableTouchFocusKeyboard()` runs only on touch devices (`pointer: coarse`), waits for Qt's shadow root (it can be created after `onLoaded`) and sets `contenteditable="false"` on every focus helper, a `MutationObserver` covers windows created later. Real text fields use a separate `<input>` element, so they still open the keyboard.
> - `app/Main.qml` - after login set `focus = false` directly on the text fields instead of moving focus to `contentItem`.
>
> **How to debug it:** run the app in Playwright Chromium with mobile emulation (`isMobile: true, hasTouch: true`), tap with `page.touchscreen.tap()` and inspect the deepest active element by walking `document.activeElement.shadowRoot.activeElement`. If it is editable (`isContentEditable` or `INPUT`) and its `inputMode` is not `none`, the keyboard will show on a real phone.

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
