# tmux keybindings — tearsheet

Read from `private_dot_config/tmux/tmux.conf` in this repo.

**Prefix is `C-a`**, not the default `C-b`. `C-b` is unbound.

Rows sourced as *tmux default* are **not** in the config — they are listed because the
config does not unbind them and you will use them daily. `C-a ?` is always the
authoritative list on a running server.

---

## Prefix

| Keys | Does | Source |
|---|---|---|
| `C-a` | Prefix key | config |
| `C-a C-a` | Send a literal `C-a` to the inner program | config |

The passthrough matters because `C-a` is readline's start-of-line in your shell.

## Panes

| Keys | Does | Source |
|---|---|---|
| `C-a \|` | Split left/right, inheriting the current path | config |
| `C-a -` | Split top/bottom, inheriting the current path | config |
| `C-a h` / `j` / `k` / `l` | Resize pane left / down / up / right by 5 | config |
| `C-a m` | Toggle pane zoom | config |
| `C-a z` | Toggle pane zoom | tmux default |
| `C-h` / `C-j` / `C-k` / `C-l` | Move between panes **and** nvim splits, no prefix | vim-tmux-navigator |
| `C-a o` | Cycle to the next pane | tmux default |
| `C-a ;` | Jump to the last-used pane | tmux default |
| `C-a x` | Kill the current pane | tmux default |
| `C-a q` | Show pane numbers, type one to jump | tmux default |
| `C-a <Space>` | Cycle through the built-in layouts | tmux default |

The resize bindings are declared with `-r`, so they repeat — hold the key without
re-pressing the prefix. `%` and `"` (the default split keys) are explicitly unbound.

Two things worth knowing: `C-a l` normally means *last window*, and the resize binding
takes it over. And `C-a m` is declared repeatable, which is meaningless for a toggle.

`C-h/C-j/C-k/C-l` is the single most valuable binding in the setup — one keystroke
crosses the tmux/nvim boundary transparently, because both halves of
`vim-tmux-navigator` are loaded.

## Windows

| Keys | Does | Source |
|---|---|---|
| `C-a C-n` / `C-a C-p` | Next / previous window | config |
| `C-a n` / `C-a p` | Next / previous window | tmux default |
| `C-a c` | Create a new window | tmux default |
| `C-a ,` | Rename the current window | tmux default |
| `C-a w` | Interactive window and session picker | tmux default |
| `C-a &` | Kill the current window | tmux default |
| `C-a 0`…`9` | Jump to window by number | tmux default |

The `C-n`/`C-p` bindings in the config are additions, not replacements — the default
`n`/`p` still work.

## Copy mode

| Keys | Does | Source |
|---|---|---|
| `C-a [` | Enter copy mode | config (`mode-keys vi`) |
| `v` | Begin selection | config |
| `y` | Copy selection to the tmux buffer | config |
| `C-a ]` | Paste the tmux buffer | tmux default |
| *(mouse drag)* | Select text; the highlight is not auto-cleared | config |

`mode-keys` is `vi`, so `hjkl`, `w`, `b`, `G` and `/` all navigate inside copy mode.

`MouseDragEnd1Pane` is deliberately unbound so the selection persists after you
release the button.

**`y` copies to tmux's own buffer only — not the Windows clipboard.** Under WSL you
want `copy-pipe-and-cancel` piping into `clip.exe`, which is available on this machine
at `/mnt/c/Windows/system32/clip.exe`.

## Session and plugins

| Keys | Does | Source |
|---|---|---|
| `C-a r` | Reload `~/.config/tmux/tmux.conf` | config |
| `C-a d` | Detach from the session | tmux default |
| `C-a $` | Rename the session | tmux default |
| `C-a ?` | List every active binding | tmux default |
| `C-a C-s` | Save the session to disk | tmux-resurrect |
| `C-a C-r` | Restore the saved session | tmux-resurrect |
| `C-a I` | Install plugins declared in tmux.conf | tpm |
| `C-a U` | Update installed plugins | tpm |

`@resurrect-capture-pane-contents` is on, so pane contents are saved too.
`@continuum-restore` is on, which means a restore also happens automatically when the
tmux server starts, and continuum saves every 15 minutes.

## Options set

| Option | Value | Note |
|---|---|---|
| `mouse` | `on` | Click to select panes, drag to resize, scroll to scroll |
| `mode-keys` | `vi` | vi navigation in copy mode |
| `status-position` | `top` | Status bar above rather than below |
| `default-terminal` | see below | |

---

## What was wrong in the committed version

**`default-terminal "alacritty"` prevented tmux from starting.** Verified on this
machine: `infocmp alacritty` returns nothing, because that terminfo entry is not part
of a base Ubuntu install — it ships with Alacritty itself or with `ncurses-term`. tmux
refuses to start with *"missing or unsuitable terminal"* when its `default-terminal`
has no terminfo entry. It also hardcodes one emulator into a file that should not care
which emulator is attached. Now `tmux-256color`, which is present.

**No true-colour passthrough.** `options.lua` sets `termguicolors = true`, but without
a `terminal-features` RGB declaration tmux does not advertise 24-bit colour to
programs running inside it, so the Neovim colourscheme degrades to 256 colours. This
is the single most common cause of "why does nvim look different inside tmux". Fixed
with `set -as terminal-features ",*:RGB"` (tmux 3.4 is installed, which supports it).

**No `escape-time` override.** Without `set -sg escape-time 10`, leaving insert mode
with `Esc` inside tmux carries a noticeable delay. Effectively mandatory for
tmux + Neovim.

**No `focus-events`.** Neovim's `autoread` and gitsigns' refresh-on-focus both need
focus events to reach the client. Without it, files changed outside the editor go
unnoticed.

**Catppuccin styled through pre-v2 option names.** The sixteen `@catppuccin_*` lines
are the v0.3.x API; v2 renamed all of them, so on a current install they silently do
nothing. The plugin is now pinned to `v0.3.0` so the existing options keep working —
migrating to the v2 names is a separate piece of work.

**tpm loaded from a path the config does not otherwise use.** `run '~/.tmux/plugins/tpm/tpm'`
points outside `~/.config/tmux`, where tpm installs everything else. tpm is also not
committed, so it has to be cloned before any `@plugin` line does anything.
