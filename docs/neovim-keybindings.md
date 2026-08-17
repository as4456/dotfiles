# Neovim keybindings — tearsheet

Describes the config **as it now stands**, after the August 2026 repairs. Verified
against Neovim 0.12.4. Where a binding moved, the old key is noted so muscle memory has
something to unlearn against.

**Leader is `Space`.** `timeoutlen` is 500ms (`which-key.lua`).

Mappings marked **buffer-local** attach on `LspAttach`, so they exist only in files
with a language server running — and they outrank global mappings on the same keys.

`SHADOW` means the mapping overrides a Vim builtin. That is a design choice, not a
defect, but it is worth knowing which builtin you gave up.

---

## General

| Keys | Mode | Does |
|---|---|---|
| `<leader>nh` | n | Clear search highlights |
| `K` | n | Hover documentation |
| `an` / `in` | v | Grow / shrink selection by Treesitter node — **native, replaces `<C-Space>` / `<BS>`** |
| `]n` / `[n` | n, v | Jump to next / previous Treesitter node |
| `<C-d>` / `<C-u>` | n | Half page down / up, cursor recentred |
| `n` / `N` | n | Next / previous search result, recentred |
| `J` / `K` | v | Move the selection down / up, reindenting |
| `<leader>p` | x | Paste over a selection without clobbering the register |

## Splits and windows

| Keys | Mode | Does |
|---|---|---|
| `<leader>sv` | n | Split vertically |
| `<leader>sh` | n | Split horizontally |
| `<leader>se` | n | Equalise split sizes |
| `<leader>sx` | n | Close current split |
| `<leader>sm` | n | Maximise / restore split — now a native toggle, `vim-maximizer` deleted |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | n | Move between nvim splits **and** tmux panes |
| `<C-\>` | n | Jump to previously used pane |
| `<C-Up>` / `<C-Down>` | n | Grow / shrink window height by 2 |
| `<C-Left>` / `<C-Right>` | n | Shrink / grow window width by 2 |

The four resize mappings previously did nothing but corrupt the buffer: they were set
to bare strings like `"resize +2"` with no `<cmd>` and no `<CR>`, so Vim replayed them
as normal-mode keystrokes. They also disagreed about modifiers — grow used
`Ctrl+Shift`, shrink used plain `Ctrl`. Both fixed; the modifier is now plain `Ctrl`
throughout.

`<C-h/j/k/l>` is the most valuable binding here: one keystroke crosses the nvim/tmux
boundary, because both halves of `vim-tmux-navigator` are loaded.

## Tabs

| Keys | Mode | Does |
|---|---|---|
| `<leader>to` | n | Open new tab |
| `<leader>tx` | n | Close current tab |
| `<leader>tn` / `<leader>tp` | n | Next / previous tab |
| `<leader>tf` | n | Open current buffer in a new tab |

## Buffers

| Keys | Mode | Does |
|---|---|---|
| `<leader>bn` / `<leader>bp` | n | Next / previous buffer |
| `<leader>bd` | n | Delete buffer *(new)* |
| `<leader>bf` | n | Format buffer via LSP (async) |

`bn` and `bp` had the same missing-`<cmd>` defect as the resize keys — `"bnext"`
replayed as `b`, `n`, `e`, `x`, `t`. Fixed.

`bufferline` runs in `mode = "tabs"`, so the bar along the top lists **tabs** while
these mappings move between **buffers**. What you see and what you navigate are still
different objects; that is upstream configuration, not a bug.

## File explorer (nvim-tree)

| Keys | Mode | Does |
|---|---|---|
| `<leader>ee` | n | Toggle file explorer |
| `<leader>ef` | n | Toggle explorer focused on current file |
| `<leader>ec` | n | Collapse tree |
| `<leader>er` | n | Refresh tree |
| `<leader>em` | n | Focus the explorer — **moved from `<leader>m`** |

`<leader>m` was both a complete mapping and the prefix of `<leader>mp`, `<leader>mc`
and `<leader>md`, so every press waited the full 500ms to disambiguate. Moving it into
the explorer's own `<leader>e` namespace removes the stall and groups it sensibly.

## Search (fzf-lua)

| Keys | Mode | Does |
|---|---|---|
| `<leader>ff` | n | Find files in cwd |
| `<leader>fr` | n | Recently opened files |
| `<leader>fg` | n | Live grep across cwd |
| `<leader>fc` | n | Grep the word under the cursor |
| `<leader>fb` | n | List open buffers |
| `<leader>ft` | n | Find TODO comments |
| `<leader>fh` | n | Search help tags *(new)* |
| `<leader>fk` | n | Search keymaps *(new)* |
| `<leader>fs` | n | Resume the last picker *(new)* |
| `<C-k>` / `<C-j>` | i | Previous / next result inside a picker |
| `<C-q>` | i | Send all results to quickfix and open it |
| `<C-u>` / `<C-d>` | i | Scroll the preview up / down |

**This replaced Telescope.** The old keys are unchanged — fzf-lua is loaded with its
`"telescope"` profile, which keeps the layout and bindings familiar — so the switch
costs no muscle memory and adds three pickers.

The reason for switching is that fzf-lua needs no build step at all: it drives the
`fzf` binary, so matching and grepping happen in a compiled Go process instead of on
Neovim's event loop. Telescope's fast path (`telescope-fzf-native`) is a C library that
has to be compiled locally, which is what was failing before.

## LSP (all buffer-local)

| Keys | Mode | Does |
|---|---|---|
| `gd` | n | Go to definition (fzf-lua) |
| `gD` | n | Go to declaration |
| `gR` | n | List references |
| `gi` | n | List implementations |
| `gt` | n | Go to type definition — `SHADOW` |
| `<leader>ca` | n, v | Code action |
| `<leader>rn` | n | Rename symbol |
| `<leader>D` | n | Diagnostics for this buffer |
| `<leader>d` | n | Diagnostic under cursor, in a float |
| `[d` / `]d` | n | Previous / next diagnostic |
| `<leader>oi` | n | Organise imports (pyright only) |
| `<leader>bf` | n | Format buffer |
| `<leader>rs` | n | Restart language server |

`gt` is Vim's builtin "go to next tab", and the buffer-local mapping wins wherever a
server is attached — so `gt` means different things in different buffers. Use
`<leader>tn` for tabs.

`gD` calls `vim.lsp.buf.declaration`, which most servers do not implement, so it often
does nothing. `gd` is the one you want.

`<leader>rs` is now unambiguous: iron's REPL moved off it (see below).

`[d`/`]d` now call `vim.diagnostic.jump`; `goto_prev`/`goto_next` were deprecated in
Neovim 0.11.

**Python type checking is on.** pyright was set to `typeCheckingMode = "off"`,
justified by a comment saying Ruff would cover it — but Ruff is a linter and formatter
and has never been a type checker, so nothing was checking types. Now `"basic"`.

## Completion (blink.cmp, insert mode)

| Keys | Does |
|---|---|
| `<C-j>` / `<C-k>` | Next / previous completion item |
| `<C-Space>` | Trigger completion menu / toggle docs |
| `<C-b>` / `<C-f>` | Scroll docs up / down |
| `<C-e>` | Abort completion |
| `<CR>` | Confirm selected item |
| `<C-l>` / `<C-h>` | Next / previous snippet placeholder — **new, was unmapped** |
| `<C-n>` / `<C-p>` / `<C-y>` | Next / previous / confirm (from the default preset) |

**This replaced nvim-cmp**, which had one tagged release, 302 open issues, and a README
opening with "don't expect a fix". The swap collapsed seven plugins — nvim-cmp,
cmp-buffer, cmp-path, cmp-nvim-lsp, cmp_luasnip, LuaSnip and lspkind — into two, since
blink has buffer, path, snippet and LSP sources built in, draws its own kind icons, and
uses Neovim's native `vim.snippet`. It needs no toolchain: prebuilt matcher binaries
ship with each release, with a pure-Lua fallback.

The old keys are preserved deliberately. `<CR>` still only confirms an item you have
explicitly selected; otherwise it inserts a newline.

**Snippet placeholder jumping now works.** Under LuaSnip it was never mapped, so
snippets expanded and then you could not reach the next placeholder. `<C-l>` and
`<C-h>` are bound insert-mode only, so the normal-mode `<C-h>` that belongs to
`vim-tmux-navigator` is untouched.

Pinned to `1.*` on purpose — `main` is V2, has many breaking changes, and needs a
separate `blink.lib` install.

## Formatting

| Keys | Mode | Does |
|---|---|---|
| `<leader>mp` | n, v | Format file, or selection in visual mode |
| *(on save)* | auto | Format on write via conform.nvim |

Two things changed here. Python was configured with a formatter named `ruff`, which is
not a conform formatter, so Python format-on-save silently fell through to the LSP. It
now runs `ruff_organize_imports`, then `ruff_fix`, then `ruff_format`. And
`lsp_fallback` was renamed `lsp_format` in conform 6.0.

There used to be three formatters competing on save — conform, efm-langserver wired as
an LSP formatter over the same filetypes, and `vim.lsp.buf.format`. efm is gone, so
conform owns formatting outright.

## Linting

| Keys | Mode | Does |
|---|---|---|
| `<leader>ll` | n | Lint the current file now — **moved from `<leader>l`** |
| *(auto)* | auto | Lint on BufEnter, BufWritePost, InsertLeave |

`<leader>l` collided with `<leader>lg` (LazyGit) and cost 500ms every press.

Diagnostics are no longer duplicated: efm-langserver was separately running ruff and
eslint over the same filetypes nvim-lint already handles, so every violation appeared
twice. nvim-lint owns linting now.

## Git

| Keys | Mode | Does |
|---|---|---|
| `]h` / `[h` | n | Next / previous hunk |
| `<leader>hs` | n, v | Stage hunk, or selection |
| `<leader>hr` | n, v | Reset hunk, or selection |
| `<leader>hS` | n | Stage the whole buffer |
| `<leader>hR` | n | Reset the whole buffer |
| `<leader>hu` | n | Toggle staged state of the hunk |
| `<leader>hp` | n | Preview hunk inline |
| `<leader>hb` | n | Full blame for the current line |
| `<leader>hB` | n | Toggle persistent line blame |
| `<leader>hd` | n | Diff file against index |
| `<leader>hD` | n | Diff file against last commit |
| `ih` | o, x | Hunk text object (`dih`, `vih`) |
| `<leader>lg` | n | Open LazyGit |

`]h`/`[h` now call `nav_hunk('next'|'prev')`; `next_hunk`/`prev_hunk` were deprecated in
gitsigns 1.0. `<leader>hu` was `undo_stage_hunk`, which gitsigns 1.0 removed entirely —
`stage_hunk` now toggles, so the key does the same job by a different route.

## Diagnostics list (Trouble)

| Keys | Mode | Does |
|---|---|---|
| `<leader>xw` | n | All workspace diagnostics |
| `<leader>xd` | n | Diagnostics for this file only |
| `<leader>xq` | n | Quickfix list |
| `<leader>xl` | n | Location list |
| `<leader>xt` | n | TODO comments list |
| `]t` / `[t` | n | Next / previous TODO comment |

## Sessions

| Keys | Mode | Does |
|---|---|---|
| `<leader>wr` | n | Restore the session for this directory |
| `<leader>ws` | n | Save the session for this directory |

`auto_restore_enabled` is false, so restoring is always manual.

## Substitute and surround

| Keys | Mode | Does |
|---|---|---|
| `s{motion}` | n | Replace motion with the yank register — `SHADOW` |
| `ss` | n | Replace the whole line |
| `S` | n | Replace to end of line — `SHADOW` |
| `s` | x | Replace the selection |
| `ys{motion}{char}` | n | Add surround around a motion |
| `yss{char}` | n | Surround the whole line |
| `ds{char}` | n | Delete the surrounding pair |
| `cs{old}{new}` | n | Change one surrounding pair for another |
| `S{char}` | v | Surround the visual selection |
| `gS{char}` | v | Surround selection on its own lines |

`cl` gives you back the old `s`; `cc` gives you back the old `S`. In visual mode `S`
surrounds while `s` substitutes — adjacent keys, opposite operations.

## Comments

| Keys | Mode | Does |
|---|---|---|
| `gcc` | n | Toggle line comment |
| `gc{motion}` | n | Comment a motion |
| `gc` | v | Comment the selection |
| `gbc` / `gb{motion}` | n, v | Toggle block comment |
| `gco` / `gcO` / `gcA` | n | Comment on line below / above / at end |
| `<C-_>` or `<C-/>` | n, v | Toggle comment |

Ctrl+/ was mapped to `"gtc"` and `"goc"`, which are not commenting mappings in any
plugin — `gt` jumps to the next tab and the trailing `c` left a pending change
operator, so the binding was actively destructive. It now resolves to `gcc` and `gc`
with `remap = true`, and both `<C-_>` and `<C-/>` are bound because terminals disagree
about which one Ctrl+/ sends.

**Every mapping in this table is now native.** Comment.nvim was deleted: it had been
unmaintained since August 2024, and Neovim 0.10+ provides all of these itself.

`nvim-ts-context-commentstring` stays, because core does *not* pick the right comment
syntax for embedded languages — a comment inside a JSX expression needs `{/* */}`
rather than `//`. It is wired through `vim.filetype.get_option` now rather than through
Comment.nvim's `pre_hook`, since that host no longer exists.

## Python REPL (iron.nvim)

| Keys | Mode | Does |
|---|---|---|
| `<leader>rc` | n, v | Send motion / selection to the REPL |
| `<leader>rl` | n | Send the current line |
| `<leader>rm` | n | Send the marked region |
| `<leader>rf` | n | Focus the REPL window |
| `<leader>rF` | n | Send the whole file — **was unreachable** |
| `<leader>ri` | n | Open the REPL — **moved from `<leader>rs`** |
| `<leader>rr` | n | Restart the REPL |
| `<leader>rh` | n | Hide the REPL window |
| `<leader>mc` | n, v | Mark a motion / selection for sending |
| `<leader>md` | n | Remove the mark |
| `<leader>s<CR>` | n | Send a bare carriage return |
| `<leader>s<Space>` | n | Interrupt (SIGINT) the REPL |
| `<leader>sq` | n | Quit the REPL |
| `<leader>cl` | n | Clear the REPL buffer |

Two fixes. `<leader>rf` was bound twice in the same file — first to iron's `send_file`,
then to `IronFocus` — and the later call won, so "send whole file to REPL" had no key
at all; it is now `<leader>rF`. And `IronRepl` sat on `<leader>rs`, where the
buffer-local `LspRestart` mapping beat it in every file with a language server
attached — which is every Python file you would want a REPL in. It is now `<leader>ri`.

Still worth knowing: `<leader>sq` (quit REPL) is one key from `<leader>sx` (close
split). The REPL is `ipython`, so it must exist in whichever Python environment is
active.

---

## Leader namespaces after the repairs

| Prefix | Owner | State |
|---|---|---|
| `<leader>e` | nvim-tree | clean — `ee`, `ef`, `ec`, `er`, `em` |
| `<leader>m` | formatting `mp`, iron `mc` / `md` | no longer stalls; nothing sits on bare `<leader>m` |
| `<leader>l` | lint `ll`, LazyGit `lg` | no longer stalls |
| `<leader>r` | LSP `rn` / `rs`, iron `rc` / `rf` / `rF` / `ri` / `rl` / `rm` / `rr` / `rh` | crowded but unambiguous |
| `<leader>s` | splits `sv` / `sh` / `se` / `sx` / `sm`, iron `s<CR>` / `s<Space>` / `sq` | shared, but no key is a prefix of another |

The `<leader>s` overlap is not a technical conflict — it is just two unrelated concepts
in one namespace. Worth splitting if the adjacency ever bites.
