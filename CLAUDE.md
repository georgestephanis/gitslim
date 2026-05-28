# CLAUDE.md — gitslim

## What this is

`gitslim` is a single-file bash TUI script (`gitslim`) that finds git repositories and converts them to shallow clones. It is modeled on `npkill`.

The installed copy lives at `~/bin/gitslim`. Keep that in sync with `gitslim` in this repo when making changes.

## Architecture

Everything is in one bash script. The execution flow is:

1. **Scan phase** (`scan`): runs `find` to locate `.git` directories, then for each one calls `du`, `git log`, `git rev-parse --is-shallow-repository`, and `git remote`. Populates six parallel arrays (`RP`, `RS`, `RA`, `RH`, `RW`, `RM`).

2. **Sort** (`do_sort`): builds a sorted index array `RI` over the data arrays using an external `sort` invocation via a temp file. Default sort is by age descending (oldest first).

3. **TUI loop** (`draw` + `read_key` + `main`): switches to the alternate screen (`tput smcup`), draws the list on every keypress by repositioning the cursor to 0,0 rather than clearing (avoids flicker), reads single keypresses including escape sequences for arrow keys.

4. **Slim operation** (`do_slim`): exits the alternate screen, runs `git pull --depth 1` + cleanup commands with output piped through `sed 's/^/  /'` for indentation, updates the in-memory arrays, then returns to the TUI.

## Key data structures

All arrays are parallel and indexed by repo number (0..n-1):

| Array | Content |
|-------|---------|
| `RP[]` | Absolute repo path |
| `RS[]` | `.git` size in KB |
| `RA[]` | Age in days since last commit (9999 if no commits) |
| `RH[]` | Has remote: 1 or 0 |
| `RW[]` | Is shallow: `true` or `false` |
| `RM[]` | Marked for slimming: 1 or 0 |
| `RI[]` | Sorted indices into the above arrays |

## Constraints and gotchas

- **`set -uo pipefail`** is set but not `-e`. Arithmetic expressions like `(( x ))` that evaluate to zero return exit code 1; that's intentional and must not be changed to `-e` without auditing every `(( ))` site.
- **Bash arrays don't cross subshell boundaries.** The scan runs in the main shell (not backgrounded) for this reason. The progress counter uses `\r` to update in place.
- **`_sep`** uses `printf '─%.0s' $(seq 1 N)` to repeat the box-drawing character N times. `tr` is not used because it works byte-by-byte and `─` is a 3-byte UTF-8 sequence.
- **`fit`** truncates with `…` (ellipsis character) at width-1 to keep column alignment intact.
- The TUI redraws by moving to `(0,0)` and overwriting every row, including padding blank rows at the bottom. Do not use `tput clear` in the draw loop.
- After `do_slim` returns to the TUI it calls `do_sort` to re-sort with updated sizes/shallow flags.

## Making changes

After editing, always:
1. Run `bash -n gitslim` to check syntax.
2. Copy to `~/bin/gitslim` and test interactively: `gitslim ~/code` is a fast test target.
3. Commit both files if the installed copy changed.
