# gitslim

An interactive TUI tool for finding git repositories and converting them to shallow clones to reclaim disk space — inspired by [npkill](https://github.com/voidcosmos/npkill).

## How it works

`gitslim` scans a directory tree for git repositories, then presents an interactive list showing each repo's `.git` folder size and how long ago it was last committed to. You mark the repos you want to slim and press `S` — it converts them to shallow clones in place.

The slim operation uses:

```bash
git pull --depth 1          # re-fetch with depth 1, discarding old history
git tag -d $(git tag -l)    # remove all tags (they hold references to old objects)
git reflog expire --expire=all --all
git gc --prune=all          # garbage-collect unreachable objects
```

This matches the technique from [afriza's gist](https://gist.github.com/afriza/6c13369d060c3361a06892e039ab9cf0).

## Requirements

- bash 4+ (macOS ships with 3.2; use `brew install bash` if needed)
- Standard Unix tools: `git`, `find`, `du`, `tput`, `sort`
- A terminal with ANSI color support

## Installation

```bash
cp gitslim /usr/local/bin/gitslim
chmod +x /usr/local/bin/gitslim
```

Or anywhere else on your `$PATH`.

## Usage

```bash
gitslim            # scan $HOME
gitslim ~/code     # scan a specific directory
```

### Keyboard controls

| Key | Action |
|-----|--------|
| `↑` / `↓` or `j` / `k` | Navigate the list |
| `Space` | Mark / unmark a repo for slimming |
| `S` | Slim all marked repos |
| `R` | Sort by age (oldest first) |
| `Z` | Sort by `.git` size (largest first) |
| `P` | Sort by path (alphabetical) |
| `Q` or `Ctrl-C` | Quit |

### What gets skipped

- Repos already marked as shallow (`git rev-parse --is-shallow-repository` returns `true`)
- Repos with no remote (slimming requires `git pull`)
- Repos with uncommitted changes (to avoid data loss)

## Caveats

- **Slimming is destructive.** It removes all commit history beyond the latest commit. You cannot recover old history without re-cloning.
- **Requires network access** during the slim operation (`git pull --depth 1` fetches from the remote).
- **Tags are deleted.** If you care about tags, back them up first or don't slim that repo.
- Repos in detached HEAD state or with complex merge situations may fail; the error output from git is shown so you can diagnose.
