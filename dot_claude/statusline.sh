#!/usr/bin/env bash
# Claude Code status line: model, dir, git branch, plus context / 5h / 7d usage bars.
# Works in Git Bash (Windows) and Linux/WSL. Needs jq.
# Caches the last known rate limits so a fresh session shows them before its first response.

JQ=$(command -v jq || echo /c/rtools45/x86_64-w64-mingw32.static.posix/bin/jq)
CACHE="$HOME/.claude/statusline-rate-cache.json"
cached=$(cat "$CACHE" 2>/dev/null); [ -n "$cached" ] || cached=null
input=$(cat)

# Remote Control is not in the status line JSON. Claude Code passes it to this script as
# CLAUDE_CODE_BRIDGE_SESSION_ID (the claude.ai/code session id) while connected. Older
# builds only record it in the internal per-process file ~/.claude/sessions/<pid>.json
# as bridgeSessionId, so that is the fallback. Neither is a documented interface: if
# both disappear in a future version, the indicator simply stops showing.
session_state=null
if [ -z "${CLAUDE_CODE_BRIDGE_SESSION_ID:-}" ] && [[ $input =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  session_file=$(grep -l -F "\"${BASH_REMATCH[1]}\"" "$HOME"/.claude/sessions/*.json 2>/dev/null | head -1)
  [ -n "$session_file" ] && session_state=$(cat "$session_file" 2>/dev/null)
  [ -n "$session_state" ] || session_state=null
fi

# One jq call. Live rate limits arrive only after the first API response, so fall back
# to the cache until then. tr strips the CRLF a native Windows jq prints.
IFS=$'\x1f' read -r live model cwd ctx h5 h5r d7 d7r effort rc_id rc_name rl < <(printf '%s' "$input" | "$JQ" -r --argjson c "$cached" --argjson s "$session_state" '
  (.rate_limits | (.five_hour or .seven_day)) as $live
  | (if $live then .rate_limits else ($c // {}) end) as $r
  | [
      ($live | tostring),
      (.model.display_name // "?"),
      ((.workspace.current_dir // .cwd // ".") | gsub("\\\\"; "/")),
      (.context_window.used_percentage // "" | tostring),
      ($r.five_hour.used_percentage // "" | tostring),
      ($r.five_hour.resets_at // "" | tostring),
      ($r.seven_day.used_percentage // "" | tostring),
      ($r.seven_day.resets_at // "" | tostring),
      (.effort.level // ""),
      ($ENV.CLAUDE_CODE_BRIDGE_SESSION_ID // $s.bridgeSessionId // ""),
      (.session_name // $s.name // ""),
      ($r | tojson)
    ] | join("\u001f")' 2>/dev/null | tr -d '\r')

if [ "$live" = true ]; then stale=0; printf '%s' "$rl" > "$CACHE"; else stale=1; fi

R=$'\e[0m'; DIM=$'\e[2m'; BOLD=$'\e[1m'; CYAN=$'\e[36m'; MAG=$'\e[35m'
now=$(date +%s)

bar() { # bar <percent> <width>
  local p=${1%.*} w=${2:-10} c f i out=""
  [ -z "$p" ] && { printf '%s' "${DIM}--${R}"; return; }
  (( p > 100 )) && p=100
  if (( p >= 90 )); then c=$'\e[31m'; elif (( p >= 70 )); then c=$'\e[33m'; else c=$'\e[32m'; fi
  f=$(( (p * w + 50) / 100 ))
  for ((i = 0; i < w; i++)); do (( i < f )) && out+="█" || out+="░"; done
  printf '%s' "${c}${out}${R} ${p}%"
}

until_reset() { # until_reset <epoch>
  local t=$1 s
  [ -z "$t" ] && return
  s=$(( t - now ))
  (( s <= 0 )) && { printf ' %s' "${DIM}(reset)${R}"; return; }
  if (( s >= 86400 )); then
    printf ' %s' "${DIM}↻ $(( s / 86400 ))d$(( s % 86400 / 3600 ))h $(date -d "@$t" '+%a %H:%M' 2>/dev/null)${R}"
  else
    printf ' %s' "${DIM}↻ $(( s / 3600 ))h$(( s % 3600 / 60 ))m $(date -d "@$t" '+%H:%M' 2>/dev/null)${R}"
  fi
}

# Claude Code passes the pane width as COLUMNS. Under 110 columns (a herdr split, a
# narrow window) the compact layout keeps what matters on screen: Claude truncates long
# lines, and the branch and RC indicator used to sit at the very end of line 1.
cols=${COLUMNS:-200}
narrow=0; (( cols < 110 )) && narrow=1

dir=${cwd##*/}
branch=$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null) ||
  branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) # detached HEAD: show the commit

# Remote Control: green dot + session name while connected, clickable (OSC 8) to open the
# session on claude.ai in terminals that support links (Alacritty does).
rc=""
if [ -n "$rc_id" ]; then
  # The title Remote Control shows is, in order: the name given to `/remote-control
  # <name>` (or /rc), else /rename's title, else the AI title. session_name covers the
  # last two; the first is only in the transcript, so take the latest such command
  # from it (~80 ms on a 4 MB transcript, and only while Remote Control is on).
  if [[ $input =~ \"transcript_path\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    transcript=${BASH_REMATCH[1]//\\\\/\\}
    rc_arg=$(grep -o '<command-name>/\(remote-control\|rc\)</command-name>.\{0,160\}<command-args>[^<]*</command-args>' \
      "$transcript" 2>/dev/null | tail -1 | sed 's/.*<command-args>\(.*\)<\/command-args>/\1/')
    [ -n "$rc_arg" ] && rc_name=$rc_arg
  fi
  rc_name=${rc_name:-remote}
  (( narrow )) && (( ${#rc_name} > 18 )) && rc_name="${rc_name:0:17}…"
  url="https://claude.ai/code/${rc_id}"
  rc=$'\e[32m'"● RC${R} "$'\e]8;;'"${url}"$'\a'"${BOLD}${rc_name}${R}"$'\e]8;;\a'
fi

# Line 1, most important first: RC, branch, project, model. The branch is yellow with a
# branch glyph so it reads at a glance; the model drops its effort level when narrow.
YEL=$'\e[33m'
parts=()
[ -n "$rc" ] && parts+=("$rc")
[ -n "$branch" ] && parts+=("${YEL}⎇ ${branch}${R}")
parts+=("${CYAN}${dir}${R}")
if (( narrow )); then
  parts+=("${MAG}${model}${R}")
else
  parts+=("${BOLD}${MAG}${model}${R}${effort:+ ${DIM}(${effort})${R}}")
fi
line1=""
for part in "${parts[@]}"; do line1+="${line1:+  ${DIM}│${R}  }${part}"; done

# A cached window whose reset time has passed is no longer meaningful.
[ "$stale" = 1 ] && [ -n "$h5r" ] && (( h5r <= now )) && { h5=0; h5r=""; }
[ "$stale" = 1 ] && [ -n "$d7r" ] && (( d7r <= now )) && { d7=0; d7r=""; }
tag=""; [ "$stale" = 1 ] && [ -n "$h5$d7" ] && tag=" ${DIM}(cached)${R}"

if (( narrow )); then
  short_reset() { # like until_reset, without the clock time
    local t=$1 s
    [ -z "$t" ] && return
    s=$(( t - now ))
    (( s <= 0 )) && return
    if (( s >= 86400 )); then printf ' %s' "${DIM}$(( s / 86400 ))d${R}"
    else printf ' %s' "${DIM}$(( s / 3600 ))h$(( s % 3600 / 60 ))m${R}"; fi
  }
  line2="ctx $(bar "$ctx" 4)  5h $(bar "$h5" 5)$(short_reset "$h5r")  7d $(bar "$d7" 5)$(short_reset "$d7r")"
else
  line2="ctx $(bar "$ctx" 8)  │  5h $(bar "$h5" 10)$(until_reset "$h5r")  │  7d $(bar "$d7" 10)$(until_reset "$d7r")${tag}"
fi

printf '%s\n%s\n' "$line1" "$line2"
