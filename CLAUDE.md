# CLAUDE.md — gitslim

## What this is

`gitslim` is a single-file bash TUI script (`gitslim`) that finds git repositories and converts them to shallow clones. It is modeled on `npkill`.

The script is a single file: `gitslim`. Install it by copying or symlinking it onto your `$PATH`.

## Architecture

Everything is in one bash script. The execution flow is:

1. **Scan phase** (`scan`): runs in two passes. Phase 1 (`discover_repos`) is just `find`, which can take a minute over all of `$HOME`. It runs `find` in the background writing to a temp file (`DISCOVER_TMP`), and polls that file every 0.2s, showing the splash logo plus a live "N repos found" count and checking for `Q`. Complete lines populate `RP[]` and seed the data arrays with placeholders (`RS=0`, `RA=9999`, etc.); when `find` finishes the full list draws immediately. Phase 2 (`enrich_repo` per index) does the expensive work: `du`, `git log`, `git rev-parse --is-shallow-repository`, `git remote`, `git rev-list --count @{u}..HEAD`, and `find … stat`. `draw()` runs between each enrichment so cells fill in progressively. A persistent cache at `~/.cache/gitslim/cache` (or `~/.gitslim-cache` fallback) keyed by repo path with the `.git` mtime as the freshness check makes subsequent runs nearly instant.

2. **Sort** (`do_sort`): builds a sorted index array `RI` over the data arrays using an external `sort` invocation via a temp file. Default sort is by age descending (oldest first).

3. **TUI loop** (`draw` + `read_key` + `main`): the alternate screen and `stty cbreak -echo` are entered *before* scanning so repos appear in the TUI as they are found. `SCANNING=1` while the scan is in progress; `draw()` adapts its header and footer for that state, and a non-blocking `poll_key` during discovery and after each enriched repo lets the user quit early. After scan completes, `do_sort()` applies the real sort order and buffered keypresses are flushed. The TUI then redraws on every keypress, repositioning the cursor to 0,0. Each row ends with `tput el` (erase to end of line) to clear stale content and extend the reverse-video highlight bar.

4. **Slim operation** (`do_slim`): exits the alternate screen, runs `git pull --depth N` (or `--shallow-since=DATE` from config) + cleanup commands, updates the in-memory arrays, then returns to the TUI.

## Key data structures

All arrays are parallel and indexed by repo number (0..n-1):

| Array | Content |
|-------|---------|
| `RP[]` | Absolute repo path |
| `RS[]` | `.git` size in KB |
| `RA[]` | Age in days since last commit (9999 if no commits) |
| `RH[]` | Has remote: 1 or 0 |
| `RW[]` | Is shallow: `true` or `false` |
| `RU[]` | Has unpushed commits: 1 or 0 |
| `RF[]` | Last file modification in working tree (epoch seconds; 0 if unknown) |
| `RM[]` | Marked for slimming: 1 or 0 |
| `RI[]` | Sorted indices into the above arrays |

## TUI layout

The footer is dynamically 2 or 3 lines tall: the baseline is a separator + key hint line; a third legend line is appended when any repos in the list carry a status label (`done` = already shallow, `n/rm` = no remote, `push` = has unpushed commits). `draw()` computes `footer_h` and adjusts `vrows` accordingly. The last drawn line intentionally has **no trailing newline** — printing past the terminal's last row causes a scroll that shifts the whole display.

Status indicators are a 4-character text label in the rightmost column of each row, with a legend at the bottom explaining them. The row format is:

```
 [M] <path>  <size>  <last commit>  <last touch>  <status>
```

where `pw = cols - 54` gives the path column its width. `<last commit>` is the age of the most recent git commit; `<last touch>` is the age of the most recently modified file in the working tree (from `RF[]`).

## Constraints and gotchas

- **`set -uo pipefail`** is set but not `-e`. Arithmetic expressions like `(( x ))` that evaluate to zero return exit code 1; that's intentional and must not be changed to `-e` without auditing every `(( ))` site.
- **Bash arrays don't cross subshell boundaries.** The scan runs in the main shell (not backgrounded) for this reason.
- **Every `stty` call uses `</dev/tty`.** `stty` acts on fd 0 (stdin) by default, and inside a `while read … done < <(…)` loop fd 0 is the pipe, not the terminal. That applies to the `EXIT` trap too: if a signal arrives mid-loop, `_cleanup` runs with stdin still redirected, the `stty "$SAVED_STTY"` restore silently fails, and the user's shell is left without echo until they run `reset`. For `stty size`, without `</dev/tty` it silently fails and `_rows()`/`_cols()` fall back to terminfo defaults (24×80), causing a visible layout jump when the scan completes and stdin returns to the terminal. `</dev/tty` explicitly targets the controlling terminal regardless of stdin redirection.
- **`_sep`** uses `printf '─%.0s' $(seq 1 N)` to repeat the box-drawing character N times. `tr` is not used because it works byte-by-byte and `─` is a 3-byte UTF-8 sequence.
- **`fit`** truncates with `…` (ellipsis character) at width-1 to keep column alignment intact.
- **`stty cbreak -echo`** is used instead of just `stty -echo`. `cbreak` disables canonical (line-buffered) mode so individual keypresses are delivered immediately. During the scan the tty is also set to `min 0 time 0`, so `poll_key` (a `dd bs=1 count=1 </dev/tty`) returns at once whether or not a key is waiting. bash 3.2's `read -t 0` can't do this because it never consumes input, and `read -t N` discards partial input when it times out. `main` switches back to `min 1` before the interactive loop. The original terminal settings are saved with `stty -g` and fully restored in `_cleanup`.
- **`read_key`** sets `REPLY` directly rather than using `printf`+command substitution. Running `read` inside `$()` forks a subshell that temporarily modifies terminal settings; when it exits the terminal state can become inconsistent. Setting `REPLY` in the current shell avoids this entirely.
- **bash 3.x `read -t`** only accepts integer timeouts (fractional-second support was added in bash 4.0). `read_key` uses `-t 1`; arrow-key bytes are already in the TTY buffer so the read completes instantly for real sequences, and bare ESC waits at most 1 second.
- **`tput rmam`** disables automatic line-wrap on entry so that any overlong rows (e.g. very long paths) clip at the right margin rather than wrapping and adding phantom lines. Restored with `tput smam` in `_cleanup`.
- **No trailing newline on the last drawn line.** Printing a newline while the cursor is on the terminal's last row causes the terminal to scroll, shifting the entire display up. `draw()` omits the final `\n`.
- The TUI redraws by moving to `(0,0)` and overwriting every row. Do not use `tput clear` in the draw loop.
- After `do_slim` returns to the TUI it calls `do_sort` to re-sort with updated sizes/shallow flags.
- **`do_slim` skips repos** with uncommitted changes or unpushed commits (both would result in data loss). It re-checks unpushed commits at slim time rather than relying on the cached `RU[]` value, which may be stale.

## Cache

`load_cache` / `save_cache` / `cache_lookup` read and write `~/.cache/gitslim/cache` (or `~/.gitslim-cache` if XDG cache isn't writable). Format is tab-separated, one record per line: `path\tgit_mtime\tkb\tage\thas_remote\tshallow\tunpushed\tlast_mod`. The cache lookup uses the `.git` directory's mtime as the freshness check — if it hasn't changed since the cache was written, the cached values are loaded into the data arrays and the enrichment for that repo is skipped entirely. Unenriched entries (`RS == 0`) are excluded from `save_cache` so partial scans don't pollute the cache.

## Config file

`load_config` reads `~/.config/gitslim/config` (checked first) or `~/.gitslim`. Supported keys:

```
depth = N        # keep N commits (default: 1); passed as --depth N
since = <spec>   # keep history since a date; overrides depth
                 # Shorthand: Nd/Nw/Nm/Ny (days/weeks/months/years)
                 # Or any git date: "2024-01-01", "6 months ago"
```

## Debug log

`DEBUG_LOG` comes from the `GITSLIM_DEBUG_LOG` environment variable and is empty by default (logging disabled). Run `GITSLIM_DEBUG_LOG=/tmp/gitslim.log gitslim` to enable it; the log is cleared on each run. Useful entries that remain in the code: startup environment, SIGINT/SIGTERM receipt, and slim invocations.

## Making changes

After editing, always:
1. Run `bash -n gitslim` to check syntax.
2. Test interactively: `gitslim ~/code` is a fast test target.
