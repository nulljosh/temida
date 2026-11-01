#!/usr/bin/env bash
# Publish the Temida web app to Cloudflare Pages (project `temida`).
#
# This script used to copy files into `nulljosh.github.io/brief` — a GitHub Pages
# mirror from the old monorepo layout that no longer exists on disk, so every run
# died at `cd`. The real host is the direct-upload Pages project `themis`, which
# is NOT git-connected: `git push` deploys nothing.
#
# It used to scrape an API token out of ~/.wrangler/config/default.toml and pass it as
# CLOUDFLARE_API_TOKEN. That grep picked up the wrong value and every deploy died on
# "Invalid access token [9109]" — plain wrangler with the stored OAuth creds works fine
# (`npx wrangler whoami` confirms), so the scrape is gone. Re-auth with `wrangler login`.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# _headers must stay in this list. It carries the CSP and HSTS; Pages only applies it if
# it is actually uploaded, and for months it was not, so the site shipped with no CSP at all.
PUBLISH=(auth.js i18n.js i18n.json spark-client.js script.js style.css sw.js manifest.json _headers
         icon.svg favicon.svg apple-touch-icon.png privacy.html tokens.css og.png footer-shader.js webmcp.js author.js hero.css hero.js temida.svg th-head.webp th-scales.webp th-sword.webp)

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp "${PUBLISH[@]}" "$STAGE/"
mkdir -p "$STAGE/fonts" && cp fonts/*.woff2 fonts/OFL.txt "$STAGE/fonts/"
cp -R brand "$STAGE/brand"

cp index.html "$STAGE/index.html"

# Syntax gate — never ship JS that won't parse.
node --check "$STAGE/script.js"
node --check "$STAGE/auth.js"
node --check "$STAGE/spark-client.js"

npx wrangler pages deploy "$STAGE" --project-name themis --branch main
