# gitslim · ANSI 256-color reference
#
# Source these in a shell script, or copy individual codes into
# your TUI library's color config. Foreground = \033[38;5;Nm,
# background = \033[48;5;Nm, reset = \033[0m.
#
# All picks tested on Solarized Dark, Catppuccin Mocha, and
# the default macOS Terminal palette.

# ── ROLE ──────────────────── ANSI ── HEX ────── USAGE ─────────────────────
GS_MAGENTA=199        # #ff2bbe — primary accent · marks, prompts, destructive
GS_MAGENTA_HOT=213    # #ff5cd1 — hover / focus highlight
GS_MAGENTA_DIM=162    # #a8137e — low-emphasis magenta

GS_CYAN=51            # #36f9f6 — secondary accent · cursor, success, links
GS_CYAN_HOT=87        # #7afffd — selected row
GS_CYAN_DIM=37        # #0fb8b5 — low-emphasis cyan

GS_VIOLET=141         # #a06fff — bridge / borders
GS_VIOLET_DIM=99      # #6a3fcc — dim border

GS_AMBER=221          # #ffcf3a — warning · large repo size
GS_LIME=155           # #b8ff5c — success · bytes freed

GS_INK=255            # #f0e6ff — primary text
GS_INK_DIM=103        # #9f8fc8 — secondary text
GS_INK_MUTE=60        # #5a4d80 — tertiary · key hints

GS_BG_DEEP=233        # #0d0220 — main background
GS_BG_VOID=232        # #07000f — deepest void

# ── helpers ───────────────────────────────────────────────────────────────
gs_fg() { printf '\033[38;5;%sm' "$1"; }
gs_bg() { printf '\033[48;5;%sm' "$1"; }
gs_reset() { printf '\033[0m'; }

# ── example usage ─────────────────────────────────────────────────────────
# printf "$(gs_fg $GS_CYAN)\$$(gs_reset) gitslim $(gs_fg $GS_INK_MUTE)v0.1.0$(gs_reset)\n"
# printf "$(gs_fg $GS_MAGENTA)[x]$(gs_reset) ~/code/forks/linux  $(gs_fg $GS_AMBER)2.1G$(gs_reset)\n"
# printf "$(gs_fg $GS_LIME)✓ 3.3 GB freed$(gs_reset)\n"
