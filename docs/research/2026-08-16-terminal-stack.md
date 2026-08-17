# Terminal stack for Ubuntu 24.04 on WSL2 — state of play, August 2026

Research date: **2026-08-16**. Target environment: Ubuntu 24.04.4 LTS under WSL2
(kernel 6.6.87.2-microsoft-standard-WSL2), Windows host, **no passwordless sudo**.
Secondary machines: macOS and Windows.

Version and date claims below come from GitHub release APIs, project changelogs, and
official docs, queried on the research date. Where a claim is a judgement rather than a
fact it is marked as such.

---

## 0. Executive answer

**Adopt now (all no-root):**

| Change | Why | Cost |
| --- | --- | --- |
| `mise use -g tmux` → tmux 3.7 | apt gives you 3.4; 3.7 is a real feature release and mise installs it without root | 2 min |
| Drop Alacritty from the plan; use Windows Terminal as the host emulator | Already installed, zero setup, best ConPTY story, 1.25 preview ships the kitty keyboard protocol | 0 |
| antidote (or plain zsh + `zsh-defer`) instead of oh-my-zsh | oh-my-zsh is the measured outlier in `zsh-bench`, not folklore | 30 min |
| eza, bat, delta, atuin via mise | Genuinely better, no root, reversible | 15 min |

**Consider:** fish 4.8.1 if you cannot get one `apt install zsh` approved — it is the only
mainstream shell with an official static Linux binary and a working `mise` path.
powerlevel10k over starship *if* you commit to zsh (it is measurably faster; it is also
still maintained, despite the rumours). WezTerm if you want one emulator config across
Windows, macOS and Linux.

**Skip:** Ghostty on Windows (does not exist), kitty on Windows (never will), zellij
(you are fluent in tmux), nushell as a login shell (pre-1.0, breaking changes monthly),
television (you already have fzf), procs/sd/duf (novelty).

**Honest answer to the underlying question:** your planned stack is fine. The only part
that is actually wrong is Alacritty, and the only part that is actually leaving
performance on the table is oh-my-zsh (which you have not installed yet, so there is
nothing to fix).

---

## 1. Terminal emulator

### 1.1 Current versions and Windows status

| Emulator | Current version | Released | Native Windows? | Config format | Config location |
| --- | --- | --- | --- | --- | --- |
| Alacritty | **0.17.0** | 2026-04-06 | Yes (MSI + portable `.exe` in release assets) | TOML (1.1 since 0.17.0) | UNIX: `$XDG_CONFIG_HOME/alacritty/alacritty.toml`; Windows: `%APPDATA%\alacritty\alacritty.toml` |
| WezTerm | **20240203-110809-5046fc22** (last *stable*) | 2024-02-03 | Yes, and it bundles a modern ConPTY | Lua | `$HOME/.wezterm.lua` / `%USERPROFILE%\.wezterm.lua`, or `$XDG_CONFIG_HOME/wezterm/wezterm.lua` |
| Ghostty | **1.3.1** | 2026-03-13 (1.3.0: 2026-03-09) | **No** | key=value | `$XDG_CONFIG_HOME/ghostty/config` |
| kitty | **0.48.2** | 2026-07-30 | **No, and not planned** | `kitty.conf` key=value | `~/.config/kitty/kitty.conf` |
| Rio | **0.5.25** | 2026-08-15 | Yes (Win 10+; winget/scoop/choco) | TOML | `~/.config/rio/config.toml` |
| Contour | **0.6.3.8249** | 2026-04-09 | Yes (Win 10+) | YAML | `~/.config/contour/contour.yml` |
| Windows Terminal | **1.24.11911.0** stable / **1.25.1912.0** preview | both 2026-07-16 | N/A (Windows-only) | JSON | package `LocalState\settings.json` |

Sources: GitHub releases API for each repo; [Alacritty `alacritty.5.scd` LOCATION
section](https://github.com/alacritty/alacritty/blob/master/extra/man/alacritty.5.scd);
[WezTerm config file docs](https://wezterm.org/config/files.html).

**Windows config paths do not follow XDG.** Alacritty is the sharpest case: `%APPDATA%`
on Windows, XDG on UNIX, and *only* `%APPDATA%` — there is no Windows XDG fallback in
the man page. WezTerm is the friendliest: `~/.wezterm.lua` works identically on all
three platforms because it keys off `$HOME`/`%USERPROFILE%`, with `~/.config/wezterm/`
as the multi-file escape hatch. This is a real argument for WezTerm if you are managing
all three machines from one chezmoi repo — one file, one path, no per-OS template.

### 1.2 Does Ghostty have a Windows build?

**No, and the maintainers have said so explicitly.** From the
[Ghostty 1.3.0 release notes](https://ghostty.org/docs/install/release-notes/1-3-0)
(released 2026-03-09):

> To answer a common request, support for Microsoft Windows is still not planned. This
> still remains part of the long term roadmap, but I think that focusing on a capable
> and powerful libghostty will enable better Windows support in the long run. libghostty
> itself already supports Windows.

Ghostty 1.4 continues the six-month cadence and is planned for **September 2026** — so
nothing changes before then. There is an unofficial community fork,
[InsipidPoint/ghostty-windows](https://github.com/InsipidPoint/ghostty-windows), adding a
Win32 apprt with OpenGL rendering and ConPTY, built with Zig 0.15.2+. Treat it as an
experiment, not a daily driver.

Practical consequence for you: **Ghostty cannot be your one cross-platform emulator.**
It is arguably the best terminal on macOS today and you should keep using it there, but
you will be running something else on the Windows host regardless.

### 1.3 What happened with WezTerm?

Short version: **the hiatus is over, the fork did not happen, and there is still no new
stable release.**

Timeline from [wezterm#6341](https://github.com/wezterm/wezterm/issues/6341):

- Last stable release: `20240203-110809-5046fc22`, **2024-02-03**. No stable release since.
- 2026-05-18: collaborator `bew` writes that Wez "has been unreachable across all
  communication channels around this project for a while now, waiting doesn't feel
  viable anymore" and that a community fork had moved "from 'maybe someday' to 'probably yes'".
- 2026-05-29: `bew` pre-announces the fork in
  [discussion #7796](https://github.com/wezterm/wezterm/discussions/7796).
- **2026-06-04: Wez returns.** He cites multiple bereavements, an international move and
  a change in employment status. Crucially: *"I've upgraded @bew's access so that they are
  empowered to make changes here without blocking on me and without the need to fork to
  make things happen"*, plus a stated plan to unblock PR review and scale the core team.
- `bew` marked the fork announcement **outdated** and pivoted to PR triage inside the
  main repo ([discussion #7845](https://github.com/wezterm/wezterm/discussions/7845)).
- Repo last push: **2026-07-16**. So: active development, governance repaired, **release
  process still not restarted**.

There is a small unrelated fork, [vcabeli/wezmux](https://github.com/vcabeli/wezmux)
(created 2026-03-26, ~5 stars), adding cmux-style workspace management for running
multiple coding agents side by side. Not the "community fork" people were discussing.

**What this means practically:** if you use WezTerm you install a nightly, not a release.
That has been the de facto situation for two and a half years and the project is
demonstrably usable that way — but it is a real risk factor to weigh, and it is the
single strongest argument for Alacritty over WezTerm.

### 1.4 ConPTY in 2026 — is it still the bottleneck?

**It is much better than it was, and it is still the bottleneck.** Two things happened.

**The fix that shipped.** [microsoft/terminal#17510](https://github.com/microsoft/terminal/pull/17510)
("A minor ConPTY refactoring: Goodbye VtEngine Edition") removed the legacy `VtEngine`
renderer and made console API calls translate directly into VT sequences. Quoting the PR:

> it also improves performance for mixed text output like enwik8.txt in conhost to
> 1.3-2x and in Windows Terminal via ConPTY to roughly 20x.

This landed in the Windows Terminal **v1.22** line. Its effects: image protocols (DCS
sixel, OSC 1337, APC kitty graphics) now pass through instead of being stripped, and
DA1-style queries reach the hosting terminal.

**The fix that did not ship.** A true opt-in passthrough mode
([#1173](https://github.com/microsoft/terminal/issues/1173),
[#15630](https://github.com/microsoft/terminal/pull/15630)) is still not a thing, and the
maintainer's own analysis in #15630 explains why it would not help much anyway:

> Due to ConPTY running in a different process it'll never reach the performance that
> OpenConsole has. With all my current and future performance PRs merged in, OpenConsole
> runs at >300MB/s whereas ConPTY with passthrough still only runs at ~50MB/s […] It's
> practically entirely bottlenecked by the cross-process communication (and the redundant
> VT parsing).

The architectural answer is [in-process ConPTY (spec #13000)](https://github.com/microsoft/terminal/blob/main/doc/specs/%2313000%20-%20In-process%20ConPTY.md),
which is a design document, not a shipped feature.

**The operational consequence, and this is the important part:** the in-box `conpty.dll`
on most Windows installs is older than 1.22, so it still mangles image escapes and
multi-codepoint grapheme cells. Terminals work around this by shipping a newer
`conpty.dll` + `OpenConsole.exe` **next to their own executable**:

- **WezTerm** has done this for years (`assets/windows/conhost/`).
- **Rio** added it in 2026 — [PR #1767](https://github.com/raphamorim/rio/pull/1767)
  bundles ConPTY `1.24.260710001` into the MSI and portable zip specifically so Yazi
  image previews and sixel work out of the box.
- **Contour** documents sideloading WezTerm's copies, noting the in-box Windows 10
  ConPTY "has limitations with mouse input handling, particularly when using WSL2 with
  terminal applications like tmux."
- **Alacritty** supports loading a co-located `conpty.dll`
  ([#4501](https://github.com/alacritty/alacritty/pull/4501),
  [#6994](https://github.com/alacritty/alacritty/pull/6994)) but **does not bundle one** —
  you copy the files in yourself, into `C:\Program Files\Alacritty`, which needs an admin
  shell. Users hit this for undercurl in nvim
  ([#8392](https://github.com/alacritty/alacritty/issues/8392)).

There is also active work on Windows PTY stalls and UI wakeup floods in
[alacritty#8839](https://github.com/alacritty/alacritty/pull/8839), which notes the tiny-write
flood became *easier* to trigger with modern OpenConsole. Treat it as a known rough edge
rather than something already fixed in 0.17.0.

### 1.5 Which emulator gives the best WSL experience today?

Judgement, stated plainly:

1. **Windows Terminal** — the pragmatic winner. It is already installed, it is developed
   by the same team that owns ConPTY, it always has the newest console host, and 1.25
   preview ships **built-in support for the kitty keyboard protocol**, which is what lets
   applications distinguish `Esc` from `Ctrl+[` and receive `Shift+Enter` — Microsoft
   explicitly calls out that this "should improve your interaction with some modern
   'agentic' command line tools." 1.24 also re-enabled PGO for a stated 10-25% throughput
   increase. Downsides: Windows-only, so no shared config with macOS.
2. **WezTerm (nightly)** — the winner if cross-platform config parity is the priority.
   Bundles a modern ConPTY, one Lua file works on all three OSes, and it has a built-in
   multiplexer if you ever want one. Downside: no stable release since Feb 2024.
3. **Rio** — genuinely interesting now that it bundles ConPTY, ships on all four
   platforms, and releases weekly. But 0.5.x with a release every few days is a lot of
   churn for a tool you want to be boring.
4. **Alacritty** — fast and stable, but on Windows you get no tabs, no splits, no
   ligatures, no image protocols, and you must hand-sideload `conpty.dll` into
   `Program Files` to fix undercurl. **This is the recommendation to drop.**
5. **Contour / kitty / Ghostty** — Contour is fine but a small project; kitty and Ghostty
   are not options on the Windows host at all.

The honest framing: you are attaching to a WSL session where the real work happens in
tmux inside Linux. The Windows-side emulator is a font renderer and an input path. ConPTY
is a shared bottleneck that no emulator escapes. Spending time here has a low ceiling.

---

## 2. Shell

### 2.1 Versions and the root question

| Shell | Current version | Released | Ubuntu 24.04 apt | No-root install |
| --- | --- | --- | --- | --- |
| zsh | 5.9 (5.9-6ubuntu2 in noble/main) | — | **needs root** | awkward — see below |
| fish | **4.8.1** | 2026-07-13 (4.8.0: 2026-06-24) | needs root | **yes** — official static Linux binaries |
| nushell | **0.115.0** | 2026-08-15 | n/a | **yes** — musl tarballs |
| bash | 5.2.21 | — | already installed | n/a |

**Verified on this machine:**

```bash
mise ls-remote ubi:fish-shell/fish-shell        # => … 4.7.1 4.8.0 4.8.1
mise ls-remote 'ubi:nushell/nushell[exe=nu]'    # => … 0.114.1 0.115.0
```

So `mise use -g ubi:fish-shell/fish-shell` and
`mise use -g 'ubi:nushell/nushell[exe=nu]'` both work with zero root. Note that neither
`fish` nor `nushell` nor `zsh` is in the curated mise registry (checked: 1002 entries,
none match) — you go through the `ubi` backend, which pulls GitHub release assets
directly. fish's 4.8.1 assets include `fish-4.8.1-linux-x86_64.tar.xz`; nushell ships
`nu-0.115.0-x86_64-unknown-linux-musl.tar.gz`.

**zsh has no clean no-root path**, which is the awkward finding:

- Not in the mise registry, and upstream zsh has no GitHub release binaries to `ubi`.
- [romkatv/zsh-bin](https://github.com/romkatv/zsh-bin) provides static, relocatable zsh
  binaries installable into `~/.local` — but latest release is **v6.1.1 (2022-06-09)** and
  it ships **zsh 5.8**, older than Ubuntu's 5.9. Works, but stale.
- conda-forge has **zsh 5.9**; installable no-root via micromamba or pixi into a user
  prefix. Heavier machinery than the problem deserves.
- Build from source into `~/.local` — needs a compiler and ncurses headers, which is
  itself an apt install.

Also root-adjacent: `chsh` requires the shell to be listed in `/etc/shells`. **You do not
need it.** In WSL you set the launch command in the Windows Terminal profile
(`wsl.exe -d Ubuntu-24.04 -- ~/.local/share/mise/shims/fish -l`) or add a guarded `exec`
at the end of `~/.bashrc`. Both are fully user-space. `/etc/wsl.conf` needs root; skip it.

### 2.2 Is zsh still the sensible default?

**Yes, if you can get it installed.** zsh 5.9 is the pragmatic default because your
existing knowledge transfers, it is near-POSIX for interactive use, the plugin ecosystem
is the deepest, and macOS ships it as the default login shell — so a zsh dotfile set is
genuinely portable across your Linux and macOS machines with no translation layer.

**fish 4.x is the strongest it has ever been and is the right answer if root is the
binding constraint.** The Rust rewrite completed in the 4.0 series (first beta
2024-12-17), and the 4.x line is now on a fast cadence: 4.6.0 (2026-03-28), 4.7.0
(2026-05-06), 4.8.0 (2026-06-24), 4.8.1 (2026-07-13). Since 4.2.0 the standalone build is
the default, and as of 4.8 support files live *inside the binary* rather than
`/usr/share/fish` ([fish#12769](https://github.com/fish-shell/fish-shell/issues/12769)) —
which is exactly what makes the drop-a-tarball-in-`~/.local` install clean. Autosuggestions,
syntax highlighting and completions are on by default with no plugin manager at all,
which removes an entire category of the work section 3 is about.

The cost is real but bounded: **fish is not POSIX.** `export FOO=bar`, `$(cmd)`, `&&` in
some positions, `[[ ]]`, and most copy-pasted install one-liners do not work. The
mitigation is boring and it works: never write scripts in your login shell. Keep
`#!/usr/bin/env bash` at the top of everything in `scripts/`, and use `bash -c '…'` for
pasted installers. Interactive shell and scripting language are separable concerns, and
treating them as one is the mistake fish critics usually make.

**nushell is a specialist tool, not a login shell for this use case.** 0.115.0 shipped
2026-08-15 on a roughly four-week cadence, and it is still **pre-1.0 with no stability
guarantee** — [nushell#18297](https://github.com/nushell/nushell/issues/18297) is an open
discussion about what 1.0 even means, and maintainers confirm there is no date. 0.114.0
alone made `enforce-runtime-annotations` opt-out and stopped implicitly importing
submodules. Structured pipelines are genuinely excellent when you are piping JSON between
tools all day; the price is that your shell config can break every four weeks and no
Stack Overflow answer applies. Install it as `nu`, use it as a data tool, do not make it
your login shell.

**Recommendation:** ask for one `sudo apt install zsh` — it is a single, defensible,
one-time request. If that is not possible, go fish 4.8.1 via mise and do not feel you have
compromised.

---

## 3. zsh plugin manager

### 3.1 The oh-my-zsh reputation is earned, and the numbers exist

The authoritative measurement tool is [romkatv/zsh-bench](https://github.com/romkatv/zsh-bench),
which measures first-prompt latency through a virtual TTY rather than
`time zsh -ic exit` (which measures total init, not perceived lag). Published zsh-bench
results, as percentages of the human imperceptibility threshold — green is imperceptible,
red is noticeable:

| Config | 1st prompt | 1st command | Command lag | Input lag |
| --- | --- | --- | --- | --- |
| DIY (plain zsh baseline) | 10% 🟢 | 42% 🟢 | 24% 🟢 | 64% 🟡 |
| antidote | 10% 🟢 | 46% 🟢 | 24% 🟢 | 63% 🟡 |
| zcomet | 10% 🟢 | 44% 🟢 | 25% 🟢 | 64% 🟡 |
| zinit | 10% 🟢 | 78% 🟡 | 24% 🟢 | 64% 🟡 |
| zplug | 108% 🟠 | 100% 🟡 | 24% 🟢 | 64% 🟡 |
| **oh-my-zsh** | **187% 🟠** | 64% 🟡 | **366% 🔴** | 2% 🟢 |

(Table as reproduced from zsh-bench `linux-desktop` data.)

The independent
[rossmacarthur/zsh-plugin-manager-benchmark](https://github.com/rossmacarthur/zsh-plugin-manager-benchmark)
agrees on the shape: antibody, antidote, antigen, sheldon and zimfw all have excellent
load times and "performance would not be a reason to choose one over the other", while
zinit, zplug and zpm have "notably bad load time performance" *when no deferral is used*.

Read those two together and the conclusion is: **oh-my-zsh's command lag (366%) is the
real problem, worse than its startup**, and the gap between the good managers is
single-digit milliseconds. Choosing between antidote and zinit on speed grounds is not a
real decision.

### 3.2 Current versions

| Manager | Latest release | Repo last push |
| --- | --- | --- |
| antidote | **v2.3.0** (2026-08-07) | 2026-08-12 |
| zinit | **v3.15.0** (2026-07-01) | 2026-08-14 |
| sheldon | 0.8.5 (2025-07-22) | 2026-07-01 |
| zplug | 2.4.2 (**2017-12-28**) | 2026-03-04 |
| oh-my-zsh | no tagged releases | 2026-08-16 |

### 3.3 Recommendation and migration

**Use antidote, or plain zsh with `zsh-defer` and manual sourcing.** antidote generates a
*static* bundle file at bundle time, so there is no per-session plugin resolution, and
`kind:defer` loads a plugin after the first prompt renders. That combination is what buys
the 10% first-prompt number. It is v2.3.0 and released last week.

Do not use zplug (2.4.2 is from 2017 and the benchmarks are poor). zinit is legitimately
the most powerful — turbo mode with `wait` ices is the only approach that fully solves the
"plugins cost hundreds of milliseconds" problem — but it costs you a DSL of ice modifiers,
and antidote reaches the same first-prompt number with a text file.

**Migration path from oh-my-zsh** (you have not installed it, so this is preventative):

1. antidote ships a `use-omz` helper that resolves oh-my-zsh's internal dependencies, so
   you can cherry-pick the two or three OMZ plugins you actually use instead of the framework.
2. **Call `compinit` exactly once.** Duplicate `compinit` is the single largest measured
   cost in real-world profiles — one published `zprof` breakdown attributed 444 ms
   (78.9% of total startup) to `compinit` being called twice by two frameworks.
3. Compile the completion dump (`zcompile ~/.zcompdump`) — worth 30-80 ms.
4. Replace eager `eval "$(tool init zsh)"` calls with cached output — worth 50-100 ms.
5. Be aware that OMZ's `git` plugin ships ~150 aliases and, if deferred, will silently
   overwrite aliases you defined eagerly.

Since you are starting clean: **skip oh-my-zsh entirely.** The migration you would be
planning for is one you can simply not incur.

---

## 4. Prompt

### 4.1 Is powerlevel10k still maintained?

**Yes.** This is the clearest "the rumour is wrong" finding in this document. The last
*tagged release* is v1.20.0 (2024-01-26), which is what feeds the "abandoned" narrative.
But commits on master by Roman Perepelitsa (the maintainer) as of the research date:

```
2026-08-15  Roman Perepelitsa   Squashed 'gitstatus/' changes from 075baf6e..39d34dff
2026-08-15  Roman Perepelitsa   bug fix: slap (V) on the content of `package` (#2961)
2026-06-15  Roman Perepelitsa   fix a bug that triggers when SH_GLOB is set (#2887)
2026-06-02  Roman Perepelitsa   bump version
2026-06-02  George Nachman      emit OSC 133 k=r and k=s for iTerm2 >= 3.7.0 (#2954)
2026-03-14  Roman Perepelitsa   Squashed 'gitstatus/' changes from 44504a24..075baf6e
```

Commits yesterday, and the project simply does not cut tags — p10k users have always
tracked master. It is maintained.

### 4.2 Versions

| Prompt | Latest | Released |
| --- | --- | --- |
| starship | **v1.26.0** | 2026-06-28 |
| oh-my-posh | **v30.6.5** | 2026-08-12 (five releases in the preceding week) |
| powerlevel10k | v1.20.0 tag / master @ 2026-08-15 | see above |

### 4.3 Is starship the fastest?

**It is the fastest cross-shell prompt. It is not the fastest prompt.** Inside zsh,
powerlevel10k wins clearly, for two structural reasons: instant prompt, and no `fork+exec`
on every command.

zsh-bench's own results:

| | starship | powerlevel10k |
| --- | --- | --- |
| first prompt lag | 82% 🟡 | 4% 🟢 |
| first command lag | 28% 🟢 | 14% 🟢 |
| command lag | **354% 🔴** | 19% 🟢 |
| input lag | 1% 🟢 | 1% 🟢 |

A user-supplied absolute measurement in
[starship#6042](https://github.com/starship/starship/issues/6042) (the open "P10k-like
instant prompt" request):

| Metric | p10k | starship |
| --- | --- | --- |
| first_prompt_lag_ms | 21.3 | 106.1 |
| command_lag_ms | 14.1 | 32.2 |

zsh-bench's README explains the mechanism: starship pays "at least one additional
fork+exec on every command" compared to native zsh prompts, and p10k's instant prompt
renders the fast-to-compute parts (cwd, host, time) within ~10 ms of shell start,
independent of everything else in your startup files. Starship maintainers acknowledge in
#6042 that instant prompt is "very difficult to implement."

Note that starship's author-side counterargument (in
[starship#580](https://github.com/starship/starship/discussions/580), from Perepelitsa
himself) is fair: both are fast in absolute terms outside large git repos, and Rust buys
starship the ability to serve every shell with one implementation. Be sceptical of
blog-post benchmarks claiming starship is 6x faster than p10k — the ones I found used
version numbers that do not exist and contradict the primary measurement tooling.

**Notable newcomers:** none worth switching for. oh-my-posh is extremely actively
released (v30.6.5, five releases in a week) and is the strongest option if PowerShell is a
first-class shell for you; it is otherwise starship's more configurable, more
Windows-flavoured sibling.

**Recommendation:** you already have starship 1.26.0 installed and it is the right choice
*if* you want one prompt across zsh, fish, nu and pwsh — which, given three machines and a
possible fish move, you probably do. If you commit to zsh everywhere, p10k is measurably
better and still maintained. Either is defensible; this is not worth agonising over.

---

## 5. Multiplexer

### 5.1 tmux

**Current: 3.7b (2026-07-01).** 3.7 shipped 2026-06-26, 3.7a on 2026-07-01. Ubuntu 24.04
ships **3.4** — which you already have installed at `/usr/bin/tmux` from
`3.4-1ubuntu0.1`. **`mise use -g tmux` gets you 3.7 with no root** (mise registry entry:
`aqua:tmux/tmux-builds`). This is the highest value-per-minute action in this document.

Notable 3.7 features, from the [CHANGES file](https://raw.githubusercontent.com/tmux/tmux/3.7a/CHANGES)
and [release notes issue #5179](https://github.com/tmux/tmux/issues/5179):

- **Floating panes** — `new-pane`, bound to `Prefix *`. Like popups but *not modal*; they
  behave as real panes with full escape-sequence support. Explicitly an early feature:
  mouse-only move/resize, no swapping, no `resize-pane`, no float↔tile conversion.
- **Line numbers in copy mode** — `copy-mode-line-numbers` with `off`/`default`/`absolute`/
  `relative`/`hybrid`.
- **Pane scrollbars** — `pane-scrollbars`, `pane-scrollbars-position`, `pane-scrollbars-style`.
- **`focus-follows-mouse`**.
- **`get-clipboard`** — tmux can request clipboard content from the terminal and forward it
  to a pane. Relevant to WSL: this is a cleaner path than the `win32yank` workarounds.
- OSC 9;4 progress-bar forwarding; `kill-session -g`; `run-shell` args as `#{1}`, `#{2}`;
  `message-format` so messages can occupy part of the status line; `C-h` builtin help per
  mode; stricter sanitisation of pane titles/window names/session names plus fuzz-testing fixes.

### 5.2 zellij

**Current: 0.44.3 (2026-05-13).** 0.44.0 (2026-03-23) was the big one:

- **Native Windows support** — zellij now runs on the Windows host directly.
- **HTTPS attach** — `zellij attach https://example.com/my-cool-session`, building on the
  web client from 0.43.0.
- **Serious CLI automation surface** — `zellij action list-panes` (IDs, titles, commands,
  coordinates), `send-keys` to a specific pane, `dump-screen`, `zellij subscribe` for
  real-time session events, pane/tab IDs returned as values. This is the most genuinely
  differentiated thing zellij has, and it matters if you script or drive agents.
- **A protobuf client/server contract.** 0.44.0 orphans existing sessions on upgrade one
  last time; from here on, new versions attach to existing sessions.

### 5.3 Seamless vim-tmux-navigator-style navigation — does it work?

**Yes, but with more moving parts.** You need three pieces rather than one:

1. Zellij side: [hiasr/vim-zellij-navigator](https://github.com/hiasr/vim-zellij-navigator),
   which explicitly aims to "give the same functionality as vim-tmux-navigator in Zellij".
   Since 0.2.0 it uses `list-clients` and no longer needs a companion nvim plugin for detection.
2. Neovim side: [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)
   (has had zellij support for a while), or `zellij-nav.nvim`, or `Navigator.nvim`
   (which auto-detects tmux vs zellij).
3. Usually [zellij-autolock](https://github.com/fresh2dev/zellij-autolock) to flip zellij
   into Locked mode while nvim has focus, plus a `VimLeave` autocmd to switch back —
   otherwise zellij's keybindings fight nvim's.

Contrast with tmux, where `vim-tmux-navigator` is one `if-shell` block in `tmux.conf`.

### 5.4 Verdict

**Not worth switching if you are fluent in tmux.** Judgement, stated as such. zellij's real
advantages are discoverability (the keybinding hint bar), session resurrection, built-in
layouts, and the browser/HTTPS sharing story. Its real disadvantages against your specific
situation: you already have the muscle memory, the seamless-navigation setup is three
components instead of one, it is still 0.x, and 0.44.0 orphaned sessions on upgrade (the
last time, they say). tmux 3.7 just shipped floating panes and pane scrollbars, which
closes some of the aesthetic gap.

The one thing that would change my answer: if you are orchestrating multiple coding agents
in panes and want to script that, `zellij action send-keys` / `dump-screen` / `subscribe`
is a real capability tmux answers less cleanly.

---

## 6. Modern CLI replacements

All versions from the GitHub releases API on the research date. **None of these require
root** — every one is a static binary that installs into a user prefix, and all but two are
in the mise registry (`mise use -g <tool>`).

| Tool | Version | Released | In mise registry | Verdict |
| --- | --- | --- | --- | --- |
| **eza** (ls) | 0.23.5 | 2026-07-09 | ✅ `aqua:eza-community/eza` | **Adopt.** Git status per file, tree mode, sane colours. Low risk, immediate payoff. |
| **bat** (cat) | 0.26.1 | 2025-12-02 | ✅ | **Adopt.** Repo still active (push 2026-08-11) despite the older tag. Also a `delta`/`man` pager. |
| **zoxide** (cd) | 0.10.0 | 2026-07-04 | ✅ | **Already installed.** Highest-value tool on this list. |
| **delta** (git diff) | 0.19.2 | 2026-03-28 | ✅ | **Adopt.** Side-by-side diffs, syntax highlighting, in-diff word highlighting. Configure via `.gitconfig` — travels with chezmoi. |
| **atuin** (history) | 18.19.0 | 2026-08-03 | ✅ | **Adopt with one caveat.** SQLite-backed history with cwd/exit code/duration, optional E2EE sync across your three machines. Caveat: it takes `Ctrl-R`, so disable fzf's `Ctrl-R` binding or they fight. Prefer session-scoped up-arrow over the default global up-arrow rebinding. Sync is optional and self-hostable. |
| **yazi** (file manager) | 26.8.15 | 2026-08-15 | ✅ | **Consider.** Excellent, very actively developed. But image previews on the Windows host need a modern ConPTY — the exact issue Rio bundled ConPTY to fix. Inside WSL under Windows Terminal it is fine. |
| **dust** (du) | 1.2.4 | 2026-01-08 | ✅ | **Marginal.** Nice output; you reach for it monthly. |
| **duf** (df) | 0.9.1 | 2025-09-08 (push 2026-01-13) | ✅ | **Skip.** Slowing down, and `df -h` is not a problem you have. |
| **procs** (ps) | 0.14.12 | 2026-06-25 | ❌ (not in registry — use `ubi`) | **Skip.** Novelty. `btop`/`bottom` covers the real need. |
| **sd** (sed) | 1.1.0 | 2026-02-25 | ✅ | **Skip.** Repo quiet since the release. Simpler syntax than sed, but sed knowledge is not wasted knowledge. |
| **television** | 0.15.9 | 2026-06-14 | ✅ | **Skip for now.** A capable fuzzy finder, but it overlaps fzf 0.74.2 which you already have and which has vastly more integrations. Revisit if you find yourself writing fzf channel wrappers. |

Already installed and worth noting as the strong base you have: fzf 0.74.2, ripgrep 15.2.0,
fd 10.4.2, zoxide 0.10.0, starship 1.26.0, mise 2026.8.5, chezmoi 2.72.0, nvim 0.12.4.

**Genuinely better vs merely newer, in one line each:** eza, bat, delta, zoxide, atuin, and
fzf/rg/fd are genuinely better — they change what you can see or how fast you find it.
dust, duf, procs, sd and television are merely different — they re-skin a tool you use
rarely or duplicate one you already have.

---

## 7. Things you did not ask about

1. **tmux via mise is the actual upgrade.** You have 3.4 from apt and 3.7b exists. This is
   the single highest-value item in this document and it costs nothing.

2. **Ubuntu 26.04 LTS shipped 2026-04-23** ("Resolute Raccoon", supported to April 2031).
   You are on 24.04.4. 26.04 makes `sudo-rs` the default sudo provider and `uutils`
   coreutils the default for most utilities — **`cp`, `mv` and `rm` remain GNU** because of
   eight unresolved TOCTOU issues as of 2026-04-22, with full uutils targeted at 26.10. It
   also ships an updated WSL experience with cloud-init and Ubuntu Pro integration.
   *Judgement:* do not upgrade your WSL distro just for terminal tooling — it is a
   larger-blast-radius decision than everything else here combined, and the coreutils swap
   has genuine script-compatibility implications.

3. **WSL itself has moved a lot.** WSL went open source (MIT) with **2.6.0 on 2025-06-20**;
   current is **2.9.4 (2026-07-13)**. **2.9.3 added WSL Containers (`wslc`) in public
   preview** — native Linux container lifecycle, images, networks, volumes, GPU containers
   via CDI, and a C++/WinRT SDK, managed by a `wslc` CLI. If you run Docker Desktop purely
   for Linux containers, this is worth a look. Also in that line: virtiofs performance
   improvements and various tty-sizing fixes. Run `wsl --update`.

4. **The kitty keyboard protocol is now mainstream on Windows.** Windows Terminal 1.25
   preview ships built-in support. It is what makes `Shift+Enter` and `Esc` vs `Ctrl+[`
   disambiguation work — increasingly load-bearing for nvim and for agentic CLI tools. If
   those keys feel broken in your setup, this is usually why.

5. **OSC 133 shell integration** (semantic prompt marking) is quietly becoming standard —
   p10k emits it, Ghostty 1.3 added click-to-move-cursor in shell prompts and scrollback
   search on top of it, and WezTerm/Windows Terminal use it for jump-to-previous-prompt.
   Worth enabling in whatever prompt you pick; it is free capability.

6. **chezmoi templates are the right answer to the `%APPDATA%` vs XDG split.** You already
   have chezmoi 2.72.0. Use `.chezmoi.os` conditionals to place the same Alacritty/WezTerm
   config at the right path per machine rather than maintaining three configs. This is
   exactly the problem chezmoi exists for.

7. **mise is the linchpin of your no-root story** and is worth treating as load-bearing
   infrastructure rather than a version manager. Current 2026.8.6 (you have 2026.8.5). The
   `ubi:` backend in particular turns "any project with GitHub release binaries" into
   "installable without root", which is how fish and nushell became options at all.

8. **carapace-bin** is in the mise registry and provides cross-shell completions from one
   spec — genuinely useful if you end up running zsh on macOS and fish on WSL and want
   completions to behave the same in both.

9. **jujutsu (`jj`) is in the mise registry** (`aqua:jj-vcs/jj`), along with `jjui`. Not
   part of your question, but it is the most notable shift in 2026 developer tooling
   adjacent to this stack, and it is git-compatible so trying it costs nothing.

10. **Nerd Fonts install per-user on Windows** — no admin required. Install on the Windows
    side (the emulator renders, not WSL), and make the same font family available on macOS
    so your prompt config is portable.

---

## 8. Concrete plan

```bash
# 1. Multiplexer: 3.4 -> 3.7 (no root)
mise use -g tmux

# 2. The CLI tools that pay for themselves (no root)
mise use -g eza bat delta atuin

# 3. Shell — pick one:
#    (a) preferred: one apt install, then antidote + starship/p10k
sudo apt install zsh
#    (b) no-root fallback, verified working on this machine:
mise use -g ubi:fish-shell/fish-shell

# 4. Terminal emulator: install nothing.
#    Use Windows Terminal (already present). If you want config parity with macOS,
#    install a WezTerm nightly instead — do NOT install Alacritty.

# 5. Windows side, once:
wsl --update      # -> 2.9.x
```

Then, if you went the zsh route: antidote with a small deferred plugin list, **one**
`compinit`, `zcompile` the dump, and cached `eval`s. Measure with `zsh-bench`, not
`time zsh -ic exit`.

---

## Sources

Primary sources consulted, all on 2026-08-16:

- GitHub Releases API for: alacritty/alacritty, wezterm/wezterm, ghostty-org/ghostty,
  kovidgoyal/kitty, raphamorim/rio, contour-terminal/contour, microsoft/terminal,
  microsoft/WSL, tmux/tmux, zellij-org/zellij, starship/starship, JanDeDobbeleer/oh-my-posh,
  romkatv/powerlevel10k, fish-shell/fish-shell, nushell/nushell, and every tool in §6.
- [Ghostty 1.3.0 release notes](https://ghostty.org/docs/install/release-notes/1-3-0)
- [wezterm#6341 "Next Release Checklist"](https://github.com/wezterm/wezterm/issues/6341) — Wez's 2026-06-04 return comment
- [wezterm discussion #7845](https://github.com/wezterm/wezterm/discussions/7845)
- [microsoft/terminal#17510](https://github.com/microsoft/terminal/pull/17510),
  [#15630](https://github.com/microsoft/terminal/pull/15630),
  [#1173](https://github.com/microsoft/terminal/issues/1173),
  [in-process ConPTY spec #13000](https://github.com/microsoft/terminal/blob/main/doc/specs/%2313000%20-%20In-process%20ConPTY.md)
- [rio#1764](https://github.com/raphamorim/rio/pull/1764), [#1767](https://github.com/raphamorim/rio/pull/1767), [#1759](https://github.com/raphamorim/rio/issues/1759)
- [alacritty#4501](https://github.com/alacritty/alacritty/pull/4501), [#6994](https://github.com/alacritty/alacritty/pull/6994), [#8392](https://github.com/alacritty/alacritty/issues/8392), [#8839](https://github.com/alacritty/alacritty/pull/8839)
- [Alacritty `alacritty.5.scd`](https://github.com/alacritty/alacritty/blob/master/extra/man/alacritty.5.scd), [changelog](https://alacritty.org/changelog_0_17_0.html)
- [WezTerm config files docs](https://wezterm.org/config/files.html)
- [Contour README](https://github.com/contour-terminal/contour/blob/master/README.md)
- [kitty#640](https://github.com/kovidgoyal/kitty/issues/640), [#2701](https://github.com/kovidgoyal/kitty/issues/2701)
- [tmux 3.7a CHANGES](https://raw.githubusercontent.com/tmux/tmux/3.7a/CHANGES), [release notes #5179](https://github.com/tmux/tmux/issues/5179)
- [zellij 0.44.0 release](https://github.com/zellij-org/zellij/releases/tag/v0.44.0), [CHANGELOG](https://github.com/zellij-org/zellij/blob/main/CHANGELOG.md)
- [vim-zellij-navigator](https://github.com/hiasr/vim-zellij-navigator), [zellij#967](https://github.com/zellij-org/zellij/issues/967)
- [romkatv/zsh-bench](https://github.com/romkatv/zsh-bench), [rossmacarthur/zsh-plugin-manager-benchmark](https://github.com/rossmacarthur/zsh-plugin-manager-benchmark)
- [starship#6042](https://github.com/starship/starship/issues/6042), [starship#580](https://github.com/starship/starship/discussions/580)
- [fish CHANGELOG](https://repo.or.cz/fish-shell.mirror.git/blob/HEAD:/CHANGELOG.rst), [fish#12769](https://github.com/fish-shell/fish-shell/issues/12769)
- [nushell 0.114.0 blog](https://www.nushell.sh/blog/2026-07-04-nushell_v0_114_0.html), [nushell#18297](https://github.com/nushell/nushell/issues/18297)
- [Ubuntu 26.04 LTS release notes](https://documentation.ubuntu.com/release-notes/26.04/), [Canonical announcement](https://canonical.com/blog/canonical-releases-ubuntu-26-04-lts-resolute-raccoon), [LWN coverage](https://lwn.net/Articles/1069399/)
- [WSL 2.6.0 release](https://github.com/microsoft/WSL/releases/tag/2.6.0), [WSL 2.9.3 discussion](https://github.com/microsoft/WSL/discussions/40942)
- Local verification on this machine: `mise registry` (1002 entries),
  `mise ls-remote ubi:fish-shell/fish-shell`, `mise ls-remote 'ubi:nushell/nushell[exe=nu]'`,
  `apt-cache policy zsh tmux fish`, `dpkg -l tmux`.
