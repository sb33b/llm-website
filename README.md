# llm-website

Public marketing site for Last Last Mile. Built with [Astro](https://astro.build)
in static-output mode — the only thing that ever gets deployed is plain
HTML/CSS/JS in `dist/`. The host (cPanel) never runs Node, npm, or Astro.

## Before going live

**Replace the placeholder contact details.** None of the address/phone/email
values on this site are real — they were unknown at build time. Everything
lives in one file:

```
src/data/contact-info.ts
```

Every field that still needs a real value is wrapped in `[BRACKETS]`. Find
them all with:

```
grep -n "\[" src/data/contact-info.ts
```

Edit that file, then rebuild (`npm run build`) and re-upload `dist/` — nothing
else needs to change, every page imports from this one file.

Also confirm `site: 'https://lastlastmile.com'` in `astro.config.mjs` matches
the real domain (used for canonical URLs and social preview cards).

## Dev workflow

Requires Node.js (v20+) locally. Not required on the cPanel host.

```bash
npm install       # once
npm run dev       # local dev server with live reload, http://localhost:4321
npm run build     # compiles the site to dist/ — this is what you deploy
npm run preview   # serve the dist/ build locally, to sanity-check the final output
```

## Deploying to cPanel

### Scripted deploy (`npm run deploy`)

`scripts/deploy.sh` builds the site and mirrors `dist/` to the document root
over SSH with rsync, so you don't upload through File Manager.

One-time setup:
1. In cPanel, open **SSH Access**, then **Manage SSH Keys**. Import your public
   key (e.g. `~/.ssh/id_ed25519.pub`) and **Authorize** it. On Namecheap shared
   hosting SSH listens on port **21098**.
2. `cp .env.deploy.example .env.deploy` and fill in the host, cPanel username
   and `DEPLOY_PATH` (`public_html`). `.env.deploy` is gitignored.
3. `npm run deploy -- --dry-run`: this builds and lists exactly what would be
   uploaded and deleted, without changing anything. Check it before the first
   real deploy.

Each release:
```sh
npm run deploy            # npm run build, preview, confirm [y/N], upload
```
Options: `--dry-run` (preview only), `--skip-build` (reuse the current
`dist/`), `--yes` (skip the prompt).

How it stays safe:
- It mirrors exactly: files on the server that aren't in the new build are
  deleted. These are always kept: `.well-known`, `cgi-bin`, `.user.ini`,
  `php.ini` and `error_log`. Add more paths with `DEPLOY_PROTECT` in
  `.env.deploy`.
- It refuses to run if the remote folder doesn't exist, or if `DEPLOY_PATH`
  is `/`, the home directory, or contains `..`.
- Each deploy writes a `.deployed-by` marker (site name, commit, time). If the
  target folder was last deployed by the *other* site, it refuses to run. That
  catches swapped `DEPLOY_PATH`s before anything is deleted.
- Files are compared by checksum, so a rebuilt file of the same size is never
  skipped.

### Manual deploy (fallback)

1. `npm run build`
2. Open cPanel → **File Manager** (or connect via FTP/SFTP) and go to
   `public_html/` (or the subdomain's document root, if this site lives on a
   subdomain).
3. Upload **the contents of `dist/`** — not the `dist/` folder itself, its
   contents — so `index.html`, `.htaccess`, `img/`, etc. land directly in the
   document root.
4. `.htaccess` is included in that upload (File Manager may hide dotfiles by
   default — enable "Show Hidden Files" in Settings if you don't see it after
   upload, to confirm it's there).
5. Visit the live domain and click through every page once, then test
   `yourdomain.com/download` on an Android device to confirm it downloads the
   APK.

Re-deploying after a content change is the same three steps: edit → `npm run
build` → re-upload the contents of `dist/`.

## How `/download` works

The "Download the App" links across the site point at `/download.html` (an
actual content page). Its own download button — and the header's — point at
the bare route `/download`, which `.htaccess` 302-redirects straight to the
backend's public APK storage URL:

```
public/.htaccess
```

This keeps the public-facing link (`lastlastmile.com/download`) permanent
even if the underlying storage URL ever changes — you'd only ever need to
edit the one line in `.htaccess`, not hunt down every place the app is linked
from.

If a future APK build moves to a different URL, update the `RedirectMatch`
target in `public/.htaccess`, rebuild, and re-upload.

## Project structure

```
src/
  layouts/BaseLayout.astro   shared <head>, wraps every page in Header + Footer
  components/                Header, Footer, Button, icon set, section components
  data/contact-info.ts       ⚠️ placeholder contact details — see above
  pages/                     one .astro file per route
  styles/global.css          brand tokens (colors, type) as CSS custom properties
public/
  .htaccess                  /download redirect, HTTPS force, 404 handler
  img/, fonts/, favicon.svg  static assets copied as-is into dist/
```

## Brand system

- Colors are verbatim from `llm-flutter/lib/core/theme/app_theme.dart`: gold
  `#FBB807`, charcoal `#2E3235`. Don't change these without checking the app
  theme stays in sync, or vice versa.
- Headings use Sora (self-hosted variable woff2 in `public/fonts/`, latin
  subset only — no Google Fonts CDN request at runtime). Body text uses the
  system font stack.
- All icons are hand-authored inline SVGs in `src/components/icons/` — none
  are sourced from an icon library or stock asset.
