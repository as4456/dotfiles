# Dotfiles audit — what was wrong and what changed

Audited at commit `6fb42f1` (last touched **2024-10-11**), applied on Ubuntu 24.04 WSL2
in August 2026. Findings are evidence from the files and from this machine, not
inference from plugin docs.

## The headline: this was a macOS config

Two independent proofs rather than a guess.

1. `alacritty.toml` imported its theme from `/Users/asingh/.config/alacritty/…`. That
   is a macOS home directory. On Linux the import silently fails and you get
   Alacritty's default colours.
2. `.zshrc` set `FZF_DEFAULT_COMMAND="fd …"` while separately aliasing `fd=fdfind` for
   Ubuntu. fzf executes that variable through `sh`, where an interactive shell alias
   does not exist — so every fzf call looked for a binary Ubuntu does not ship. The
   alias was a partial Linux patch that did not reach the place it mattered.

Supporting evidence: `decorations = "buttonless"` is documented **macOS only**, and
`pbcopy`/`pbpaste` were aliased to `xclip`, recreating macOS command names.

## Why the Neovim half still worked

`lazy-lock.json` pins all 46 plugins to October 2024 commits and lazy.nvim restores
that lock on install, so the config installed and ran as committed. The breakage was
**latent**, waiting on the first `:Lazy update` — and `lazy.lua` sets
`checker.enabled = true`, which prompts toward exactly that update every session.

That is now a live problem rather than a theoretical one, because the Neovim installed
here is **0.12.4**, not the 0.10 this config was written against.

## Portability defects

| Severity | What | Where |
|---|---|---|
| High | Repo had no templates and no per-OS logic — 49 entries, 0 `.tmpl` files, a five-line static `.chezmoiignore`. chezmoi's whole multi-machine story is templates, so this was structurally a single-machine repo. | whole repo |
| High | Alacritty config would not be found at all on native Windows: the source path maps to `~/.config/alacritty/`, but on Windows Alacritty reads only `%APPDATA%\alacritty\alacritty.toml` with no XDG fallback. | `private_dot_config/alacritty/` |
| High | Theme import pointed at a macOS home directory. | `alacritty.toml:1` |
| High | `FZF_DEFAULT_COMMAND` called a binary Ubuntu names differently. | `dot_zshrc:20` vs `51-53` |
| High | asdf sourced via `asdf.sh`, which asdf 0.16 removed in its Go rewrite. Unguarded, so every shell would error. | `dot_zshrc:35-36` |
| High | `default-terminal "alacritty"` — **verified absent** on this machine (`infocmp alacritty` fails), which stops tmux starting. | `tmux.conf:1` |
| High | No true-colour passthrough in tmux while nvim sets `termguicolors`. | `tmux.conf` |
| Medium | Alacritty config written against the pre-0.14 schema: top-level `[shell]` rather than `[terminal].shell`, and `program = "/usr/bin/zsh"` — a Linux path, proving it never ran as a Windows terminal. | `alacritty.toml:29-30` |
| Medium | `/opt/nvim-linux64/bin` on PATH; upstream renamed the tarball to `nvim-linux-x86_64`. | `dot_zshrc:24` |
| Medium | Unguarded `source ~/fzf-git.sh/fzf-git.sh`, unlike line 47 which is guarded. | `dot_zshrc:67` |
| Medium | Catppuccin tmux styled through pre-v2 option names — 16 lines that do nothing on a current install. | `tmux.conf:37-52` |
| Medium | tpm run from `~/.tmux/plugins/tpm` while the config lives in `~/.config/tmux`. Not committed either. | `tmux.conf:69` |
| Medium | No `escape-time` override, so `Esc` lags leaving insert mode inside tmux. | `tmux.conf` |
| Low | `pbcopy`/`pbpaste` aliased to xclip, which needs an X server under WSL. `clip.exe` is the WSL answer and is already present. | `dot_zshrc:26-27` |
| Low | No `focus-events`, so nvim `autoread` and gitsigns refresh do not fire. | `tmux.conf` |

## Neovim plugin drift

| Severity | What |
|---|---|
| High | `mason-lspconfig.setup_handlers` was removed in mason-lspconfig 2.0. The entire LSP setup block is built on it. |
| High | `tsserver` was renamed `ts_ls`. Under new versions TypeScript gets no server and mason fails to install the package. |
| High | Python type checking is off (`typeCheckingMode = "off"`) and nothing replaces it. The comment says "we'll use Ruff for this", but Ruff is a linter and formatter and has never been a type checker. The result looks configured rather than absent. |
| Medium | `nvim-ts-autotag` configured through the old Treesitter module API, so JSX and HTML tags do not auto-close despite the config saying they do. |
| Medium | Treesitter config targets the frozen `master`-branch API (`require("nvim-treesitter.configs")`). |
| Low | Mason plugins referenced at `williamboman/…`; they moved to the `mason-org` organisation. |
| Low | `isort`, `black` and `pylint` installed but never invoked — conform and nvim-lint both point at ruff. |
| Low | `path_display = { "truncate " }` has a trailing space, so it never matches the option name and paths are never shortened. |
| Low | `install.colorscheme = "nightfly"` in `lazy.lua` — confirm it matches what `colorscheme.lua` loads. |
| Low | `-- Set leader key to Ctrl` sits above `vim.g.mapleader = " "`. |

## Broken keymaps

Three defects that did not depend on any version, documented in
[`neovim-keybindings.md`](./neovim-keybindings.md):

- Six mappings (`<leader>bn`, `<leader>bp`, and four window-resize bindings) set to
  bare command strings with no `<cmd>` or `<CR>`, so they replayed as normal-mode
  keystrokes and edited the buffer.
- Ctrl+/ mapped to `"gtc"`/`"goc"`, which are not Comment.nvim mappings.
- `<leader>rf` bound twice in one file, leaving iron's "send file to REPL" unreachable.

Plus four colliding leader namespaces, two of which cost 500ms on every press.

## Environment as found

| | |
|---|---|
| Distro | Ubuntu 24.04.4 LTS on WSL2 |
| Shell | `/bin/bash` — **zsh was not installed** |
| Already present | tmux 3.4, git 2.43, vim, mise 2026.8.5, uv 0.12.3, node 24.19.0 |
| Missing | zsh, neovim, starship, chezmoi, fzf, ripgrep, fd, lazygit, zoxide, xclip, gcc, make |
| sudo | **requires a password**, so nothing could be installed via apt |

Everything except zsh and a C compiler was installable without sudo through mise.

## What is now installed

Via `mise use -g`, all user-level and no sudo: neovim 0.12.4, starship 1.26.0,
chezmoi 2.72.0, fzf 0.74.2, ripgrep 15.2.0, fd 10.4.2, lazygit 0.64.1, zoxide 0.10.0.

Via `uv python install`: CPython 3.10.20 and 3.14.7, with 3.10 as the default for both
the bare `python`/`python3` commands and for new `uv venv` environments.

One useful side effect: mise installs fd as **`fd`**, the upstream binary name. That
fixes the fzf bug for free and makes the `alias fd=fdfind` line wrong, so it was
removed.

## Every problem hit during setup

In order, with the root cause and the fix. Nine of the fourteen only became visible by
running things rather than reading them.

| # | Problem | Root cause | Fix |
|---|---|---|---|
| 1 | Could not install anything with apt | `sudo -n true` fails — sudo needs a password | Everything except zsh and a compiler installed via mise into `~/.local`, no root |
| 2 | tmux would not start | `default-terminal "alacritty"`; `infocmp alacritty` confirms no such terminfo on Ubuntu | `tmux-256color` |
| 3 | nvim colours degraded inside tmux | `termguicolors` set but tmux never advertised RGB | `set -as terminal-features ",*:RGB"` |
| 4 | `Esc` lagged leaving insert mode | no `escape-time` override | `set -sg escape-time 10` |
| 5 | Alacritty theme never loaded | `import` pointed at `/Users/asingh/...`, a macOS path | Catppuccin palette inlined; no import at all |
| 6 | Alacritty config unreachable on Windows | Windows reads only `%APPDATA%\alacritty`, no XDG fallback | One shared body in `.chezmoitemplates`, included by two OS-gated targets |
| 7 | `mason_lspconfig.setup_handlers` — "attempt to call field (a nil value)" | mason-lspconfig 2.0 removed it; the whole LSP block was built on it | Rewritten onto `vim.lsp.config()` + `automatic_enable` |
| 8 | `module 'nvim-treesitter.configs' not found` | the plugin's default branch is now `main`, a rewrite that deleted that module | Pinned `branch = "master"` — a deferral, since master is archived |
| 9 | Telescope failed to load entirely | unguarded `load_extension("fzf")`; `libfzf.so` needs a C compiler to build | `pcall` + one warning; falls back to the built-in sorter |
| 10 | `Error running ruff: ENOENT` | ruff not installed anywhere | `uv tool install ruff` |
| 11 | "No C compiler found!" printed ~25× per file open | one failure per parser in `ensure_installed` | `ensure_installed` gated on a compiler existing; one clear message instead |
| 12 | stylua failed to install via mason | mason's installer needs `unzip`, which is absent and needs root | Installed via mise instead |
| 13 | `chezmoi apply` aborted, then silently skipped later files | nvim rewrites `lazy-lock.json`, so every `:Lazy` action became a chezmoi conflict; apply stopped at the prompt and never reached the Lua files | Renamed to `create_lazy-lock.json` — written only if absent, so nvim owns it thereafter |
| 14 | `tomllib` missing under `python3` | tomllib arrived in 3.11, and `python3` is now 3.10 by request | Use `python3.14` for anything needing 3.11+ stdlib |

Number 13 is the one worth remembering: because apply aborts on the first conflict, a
later `chezmoi verify` disagreeing with a passing-looking apply is the signal that
edits never landed. Two rounds of "fixed" errors were actually unapplied files.

## The compiler turned out not to need root

The original conclusion here was that `build-essential` required a sudo password. That
was wrong, and the correction matters because it was the larger of the two blockers.

**`zig` is a complete, self-contained C compiler and mise ships it.** `zig cc` is a
real clang-based C driver, not a toy. Installing it took one command and no root:

```sh
mise use -g zig tree-sitter
mkdir -p ~/.local/bin
printf '#!/bin/sh\nexec zig cc "$@"\n' > ~/.local/bin/cc && chmod +x ~/.local/bin/cc
```

The wrapper is what makes it work rather than just setting `CC`, because tools probe
for a binary literally named `cc` — including the `vim.fn.executable("cc")` guard in
`treesitter.lua`.

Verified end to end: 26 Treesitter parsers compiled, highlighting confirmed attached in
a Python buffer (`vim.treesitter.highlighter.active[bufnr]` is non-nil and nodes
resolve), and `libfzf.so` built so Telescope runs its native sorter.

One wrinkle: `telescope-fzf-native`'s build step is `make`, which mise does not provide
as a normal binary. Compiling the single source file directly sidesteps it:

```sh
cc -O3 -Wall -fpic -std=gnu99 -shared src/fzf.c -o build/libfzf.so
```

## Modernisation, same day

After the repairs came a second pass against the August 2026 ecosystem. Five changes,
all verified running rather than assumed.

| Was | Now | Why |
|---|---|---|
| `nvim-treesitter` on `master` | `main` branch | `master` is frozen and its README declares Neovim 0.12 **unsupported** — which is what we run |
| `nvim-cmp` + 6 satellites | `blink.cmp` (pinned `1.*`) | nvim-cmp has one tagged release, 302 open issues, and a README saying "don't expect a fix" |
| `telescope.nvim` | `fzf-lua` | No build step at all; it drives the `fzf` binary already installed |
| `Comment.nvim` | native `gc` / `gcc` | Unmaintained since Aug 2024, and 0.10+ does this itself |
| `dressing.nvim`, `vim-maximizer` | `snacks.nvim` input, native toggle | dressing is archived and points here; vim-maximizer died in 2022 |

Net effect: **46 plugins to 35, 30 spec files to 25**, with no loss of function and one
gain — snippet placeholder jumping, which was never mapped under LuaSnip.

Two corrections to widely repeated claims, both checked against the repos: nvim-treesitter
was **not** permanently archived (the April 2026 archival was reverted, and the community
fork is a stalled side project), and Telescope is **not** dead — it shipped v0.2.2 in
February 2026. The pin here was on `0.1.x`, which predates its 0.12 fixes.

### Two failures worth recording

**zig rejects tree-sitter's target triple.** `zig cc` compiles fine on its own, but
`tree-sitter build` passes `-target x86_64-unknown-linux-gnu`, and zig fails with
`UnknownOperatingSystem` because it spells that target `x86_64-linux-gnu`. Every parser
build failed until `~/.local/bin/cc` was taught to strip `-target`. This never appeared
on the `master` branch, which invoked `cc` directly with no target flag.

**Deleting from the chezmoi source does not delete from the destination.** chezmoi just
stops managing the file and leaves it in place. Normally harmless — but lazy.nvim reads
*every* `.lua` file in its plugins directory, so five orphaned specs kept re-cloning the
plugins that had supposedly been removed. `.chezmoiignore` does not help; the tool for
this is `.chezmoiremove`, which lists target paths to delete on apply and is therefore
fixed on every machine rather than just this one.

## Still requires you

Only zsh, and only because a login shell must be listed in `/etc/shells`, which needs
root. It is the sole remaining item that genuinely cannot be done from user space.

```sh
sudo apt update && sudo apt install -y zsh
chsh -s "$(command -v zsh)"
```

The `chsh` takes effect on your next WSL session. If that one command is never going to
be approved, `mise use -g ubi:fish-shell/fish-shell` installs fish 4.x with no root —
but it is a different shell language, and the `.zshrc` in this repo would need
rewriting.
