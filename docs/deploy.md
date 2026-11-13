# Deployment

- [Build the deploy package](#build-the-deploy-package)
- [Copy to server](#copy-to-server)
- [Extract and start on server](#extract-and-start-on-server)
- [Accessing from a browser over LAN (HTTP)](#accessing-from-a-browser-over-lan-http)
- [Notes](#notes)
- [Deploying to Netlify](#deploying-to-netlify)
- [Deploying to Cloudflare Pages](#deploying-to-cloudflare-pages)
  - [Cloudflare setup](#cloudflare-setup)

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

## Deploying to Cloudflare Pages

Requires a domain/subdomain on a Cloudflare-managed zone (root domain can be hosted elsewhere - only the zone's nameservers need to point at Cloudflare).

Multithreaded WASM requires `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers. A `_headers` file at the repo root provides these and is bundled into the deploy package by the `deploy` cmake target:

```text
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Cache-Control: no-cache
```

`Cache-Control: no-cache` makes browsers revalidate by ETag on every load, so `appwebassembly.js` and `appwebassembly.wasm` always come from the same build.

Deploy the built sources with wrangler:

```shell
wrangler pages deploy build-wasm/deploy/sources --project-name=crypto-terminal
```

First run creates the Pages project and prints a `*.pages.dev` URL - verify it loads (check `crossOriginIsolated` in devtools) before attaching a custom domain.

### Cloudflare setup

1. Add the domain as a zone in the Cloudflare dashboard (skip if already there) and point its nameservers at Cloudflare.
2. Dashboard -> Workers & Pages -> the project -> **Custom domains** -> add the desired subdomain (e.g. `app.example.com`). Cloudflare creates the CNAME and issues the certificate automatically.
3. Verify: `curl -I https://<subdomain>` and confirm `cross-origin-opener-policy` / `cross-origin-embedder-policy` headers are present.
4. Zone dashboard -> Caching -> Configuration -> **Browser Cache TTL** -> set to **Respect Existing Headers**. Otherwise the zone overrides `Cache-Control: no-cache` from `_headers` on `.js` files (e.g. `max-age=14400`), browsers keep a stale `appwebassembly.js` next to a fresh `appwebassembly.wasm` after a deploy and the app crashes with `TypeError: ASM_CONSTS[code] is not a function`.
