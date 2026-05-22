# Deployment

## Build the deploy package

On the build machine, run the `deploy` cmake target:

```shell
ninja -C build-wasm deploy
```

Output:

- `build-wasm/deploy/appwebassembly.tar.gz` - archive to ship
- `build-wasm/deploy/sources/` - unpacked files (for inspection)

## Copy to server

```shell
scp build-wasm/deploy/appwebassembly.tar.gz user@server:/srv/crypto-terminal/
```

## Extract and start on server

```shell
ssh user@server
cd /srv/crypto-terminal
tar xzf appwebassembly.tar.gz
python3 serve.py 8080 .
```

App available at `http://<server-ip>:8080/` from any device on the LAN.

## Accessing from a browser over LAN (HTTP)

Browsers block `SharedArrayBuffer` on non-`localhost` HTTP origins. If the app fails to load with a `crossOriginIsolated` error, whitelist the server address in Chrome/Edge:

1. Open `chrome://flags/#unsafely-treat-insecure-origin-as-secure`
2. Enable the flag and add `http://<server-ip>:8080`
3. Relaunch the browser

## Notes

- `serve.py` is bundled in the archive - it must be used instead of `python3 -m http.server` because multithreaded WASM requires `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers.
- The Fear & Greed API (`api.alternative.me`) is called from the browser, not the server - no outbound proxy needed on the server side.
- No Qt libraries are needed on the server - everything is statically linked into the `.wasm` file.
- For HTTPS (needed when accessing over an untrusted network), put nginx or caddy in front as a reverse proxy.

## Deploying to Netlify

Multithreaded WASM requires `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers. Add a `netlify.toml` at the repo root:

```toml
[[headers]]
  for = "/*"
  [headers.values]
    Cross-Origin-Opener-Policy = "same-origin"
    Cross-Origin-Embedder-Policy = "require-corp"
```

The `index.html` entry point is served automatically by Netlify.
