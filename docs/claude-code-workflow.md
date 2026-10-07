# Claude Code + Neovim + herdr — workflow tearsheet

Two ways to work. Same nvim config, same keys, on Windows (Git Bash) and WSL.

| | Style A — one project | Style B — several agents / long tasks |
|---|---|---|
| Start | Alacritty → `Ctrl+Shift+G` (Git Bash) → `cd proj` → `nvim` | Alacritty → `Ctrl+Shift+H` (herdr, Windows) or `Ctrl+Shift+L` (herdr, WSL) → `cd proj` → `herdr-dev` |
| Claude lives | in an nvim split: `Space a c` | in its own herdr pane, next to the nvim pane |
| Agents | one | `herdr-dev --agents 3` for three; herdr sidebar shows working / blocked / done |
| Survives closing nvim | no (`Space a r` resumes) | yes; detach with `Ctrl+a q`, run `herdr` to come back |

## Layout (Style A)

```
┌──────────────────┬─────────────┬─────────────┐
│ code             │ ipython     │ Claude Code │   Space r i   open ipython REPL
│                  │ (Space r i) │ (Space a c) │   Space a c   toggle Claude
│                  │             │             │   Ctrl-h/j/k/l  move, from any
└──────────────────┴─────────────┴─────────────┘                 window, terminals too
```

## Moving around

| Keys | Where | Does |
|---|---|---|
| `Ctrl-h/j/k/l` | anywhere in nvim, **including the REPL and Claude terminals** | move to the window in that direction |
| `Ctrl-h/j/k/l` | WSL herdr | same, and crosses into neighbouring herdr panes at nvim's edge |
| `Alt+←↓↑→` | herdr, Windows and WSL | move between herdr panes without the prefix (on Windows Ctrl-hjkl stays inside nvim) |
| `Esc Esc` | Claude split | leave terminal mode without moving |
| `Ctrl-\ Ctrl-n` | any terminal | leave terminal mode without moving |

Entering a terminal window drops you straight into typing mode. Inside terminals,
`Ctrl-l` / `Ctrl-j` belong to navigation: clear ipython with `Space c l`, add a newline
in Claude with `Shift+Enter`.

## Claude Code in nvim (claudecode.nvim)

| Keys | Does |
|---|---|
| `Space a c` / `Space a f` | toggle / focus the Claude split |
| `Space a r` / `Space a C` | resume a past session / continue the last one |
| `Space a s` | send selection (visual) · add file (in nvim-tree) |
| `Space a b` | add the current buffer |
| `Space a a` / `Space a d` | accept / deny the diff Claude proposed |
| `Space a m` | pick model |

claudecode.nvim starts with nvim and writes `~/.claude/ide/<port>.lock`. Any Claude
started in the same project directory can attach: `claude --ide` at launch, or `/ide`
inside a running Claude. That is how Style B's separate Claude pane still opens its
diffs in the nvim pane.

## herdr (prefix `Ctrl+a`, same as tmux — never nest the two)

| Keys | Does |
|---|---|
| `Ctrl+a \|` / `Ctrl+a -` | split right / down (tmux keys; `Ctrl+a v` also works) |
| `Ctrl+a h/j/k/l` | resize the pane (as in tmux.conf) |
| `Ctrl+Alt+↑/↓` · `Alt+1…9` · `Ctrl+a o` | prev/next space · tab N · agent that needs you |
| `Ctrl+a c` | new tab |
| `Ctrl+a x` | close pane |
| `Ctrl+a z` | zoom pane |
| `Ctrl+a w` | workspace picker |
| `Ctrl+a b` | toggle sidebar |
| `Ctrl+a alt+g` | lazygit popup |
| `Ctrl+a q` | detach (agents keep running) |
| `Ctrl+a ?` | every binding |

Mouse works everywhere: click panes and sidebar rows, drag borders, right-click menus.

`herdr-dev [DIR] [--agents N]` (run inside herdr): new workspace named after DIR, nvim
on the left, Claude (`--ide`) on the right, N-1 extra Claude panes stacked below.

## Platform notes

- **Windows herdr is beta.** Full-screen apps can show stray colour codes; WSL herdr is
  the stable build. Config on Windows exists in two places from one template, because
  herdr reads `$XDG_CONFIG_HOME\herdr` (set by the Git Bash `.bashrc`) before
  `%APPDATA%\herdr`.
- **herdr-nvim-nav** (seamless Ctrl-hjkl across herdr panes) is Linux-only: it talks to
  herdr over a Unix socket. Installed in WSL with
  `herdr plugin install aimdevlee/herdr-nvim-nav`.
- **Claude integration** (`herdr integration install claude`) adds one SessionStart hook
  so the sidebar gets real agent state; installed on both sides.
