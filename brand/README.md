# gitslim · branding package

Everything you need to put gitslim's face on a README, npm listing, social card,
or the tool's own splash. Plus the bones of a TUI implementation that matches.

```
       _ _       _ _
   ___(_) |_ ___| (_)_ __ ___
  / _ \ | __/ __| | | '_ ` _ \
 | (_| | | |_\__ \ | | | | | |
  \__, |_|\__|___/_|_|_| |_| |
   __/ |
  |___/  ✂─ ─ ─ ─ ─ ─ ─
```

---

## What's in here

```
brand/
├── icon/                  the disk-slice icon
│   ├── gitslim-icon.svg          ← canonical, scales to anything
│   ├── gitslim-icon-256.png      ← npm thumbnail / favicon
│   ├── gitslim-icon-512.png      ← README / app icon
│   └── gitslim-icon-1024.png     ← marketing / hi-DPI
│
├── banner/                the terminal-demo banner
│   ├── gitslim-banner-preview.png    ← 924×462, README / OG card
│   ├── gitslim-banner-2x.png         ← 1848×924, hi-DPI
│   └── _snap/banner-snap.html        ← native re-render source
│
├── ascii/                 drop-in CLI sigils
│   ├── tiny-01-prompt.txt        single line, prompt-adjacent
│   ├── tiny-02-tagline.txt       3 lines, w/ tagline
│   ├── tiny-03-boxed.txt         boxed prompt
│   ├── medium-01-figlet-small.txt  figlet, splash on launch
│   ├── medium-02-banner-box.txt    boxed wordmark
│   ├── large-01-figlet-standard.txt  full figlet, --version
│   └── large-02-scissors.txt     pure scissors sigil
│
├── colors/                palette in 3 formats
│   ├── palette.css               CSS custom properties (--gs-*)
│   ├── palette.json              JSON tokens + role mapping
│   └── ansi-256.sh               shell-source for TUIs
│
└── layout/                implementer-facing demo
    └── layout-demo.html      open in a browser, toggle states + annotations
```

---

## Quick start by surface

### npm package listing
- **Thumbnail**: `icon/gitslim-icon-256.png` (square)
- **README hero**: `banner/gitslim-banner-2x.png` (2:1)

### GitHub repo
- **Social preview** (`Settings → Social preview`): `banner/gitslim-banner-2x.png`
- **README opening line**: `banner/gitslim-banner-preview.png` or the figlet from
  `ascii/large-01-figlet-standard.txt` in a fenced code block.

### The CLI itself
- **Splash on launch**: print `ascii/medium-01-figlet-small.txt` in cyan with
  the tagline underneath in `ink-dim`. See `colors/ansi-256.sh` for the codes.
- **`--version`**: print `ascii/large-01-figlet-standard.txt`.
- **Help prompt accent**: prefix every shell example with `\033[38;5;51m$\033[0m`.

### Social card / OG image
- Use `banner/gitslim-banner-2x.png` directly. It's 2:1 which matches
  Twitter/X large card and GitHub social preview.

---

## Color usage

Three colors carry meaning. Don't reassign them:

| Token       | Hex       | ANSI 256 | Means                                              |
|-------------|-----------|----------|----------------------------------------------------|
| `magenta`   | `#ff2bbe` | 199      | the user's intent — marks, prompts, destructive    |
| `cyan`      | `#36f9f6` | 51       | the system's state — cursor, focus, success links  |
| `amber`     | `#ffcf3a` | 221      | a warning — large repo, "you sure?"                |
| `lime`      | `#b8ff5c` | 155      | a win — bytes freed, "✓ done"                      |
| `violet`    | `#a06fff` | 141      | chrome — borders, dividers                         |
| `ink-mute`  | `#5a4d80` | 60       | quietest text — key hint labels                    |

Everything else (`ink`, `ink-dim`, the backgrounds) is supporting cast.

---

## TUI layout, in one breath

```
┌─────────────────────── ── gitslim · ~/code ── ─────────────────────────┐
│ ▍ gitslim v0.1.0 · scanning ~/code     ▲ 4.2G freed · 27/142 selected │
│                                                                        │
│      REPOSITORY              .GIT SIZE      LAST COMMIT                │
│ ──────────────────────────────────────────────────────────────         │
│ [x]  ~/code/old-dotfiles         1.2G       3y ago         SLIM        │
│ ▍[ ]  ~/code/personal/blog-engine 684M       11mo ago                  │
│ [x]  ~/code/forks/linux          2.1G       2y ago         SLIM        │
│ [ ]  ~/code/work/api-server       92M       2d ago                     │
│ [x]  ~/code/archive/old-rails-app 412M      4y ago         SLIM        │
│                                                                        │
│ ↑↓ nav   SPC mark   S slim   ? help   Q quit                          │
└────────────────────────────────────────────────────────────────────────┘
```

- **Cursor row**: 3-px cyan bar at left, 8 % cyan background tint, path in cyan.
- **Marked row**: `[x]` and the size both flip to magenta. `SLIM` tag in lime.
- **Size color** (independent of marked state): `< 100M` ink-dim, `< 1G` ink,
  `≥ 1G` amber.
- **Key glyphs** colored by intent: cyan for nav, magenta for destructive (S, Y),
  ink-dim for neutral (Q, ESC).

Open `layout/layout-demo.html` for a live version with BROWSE / CONFIRM / RESULT
states, an `annotate` toggle that overlays measurements, and a `CRT FX` toggle
to see how it reads with effects off.

---

## ASCII sigils — when to use which

- `tiny-01-prompt.txt` — inline in flowing CLI text, e.g. error messages.
- `tiny-02-tagline.txt` — top of `--help`.
- `medium-01-figlet-small.txt` — default launch splash. Fits in 80 cols.
- `large-01-figlet-standard.txt` — `--version` and the README hero block.
- `large-02-scissors.txt` — for places where the wordmark is already nearby.

All large sigils use box-drawing and a single backtick (and one backslash per
line) — they render cleanly in monospaced fonts everywhere it matters.

---

## Re-rendering the banner

If you want the banner at a different size or with different repos:

1. Open `banner/_snap/banner-snap.html` in a browser. It renders the canonical
   1280×640 banner at native resolution (uses html-to-image under the hood).
2. Right-click the rendered `<img>` → Save Image As.
3. To swap the repo list, edit `BannerTerminalDemo` in `../../banners.jsx`
   (top-level of the source project) and reload.

The icon SVG is canonical and resolution-free — re-render any PNG size with:

```bash
# requires librsvg (`brew install librsvg`)
rsvg-convert -w 2048 brand/icon/gitslim-icon.svg > icon-2048.png
```

---

## License

The brand mark, banner, and palette are © the gitslim project. Use them for
gitslim itself, gitslim packaging, gitslim coverage, and tools that integrate
with gitslim. Don't use them to brand unrelated projects.
