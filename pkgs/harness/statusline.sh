#!/usr/bin/env bash
input=$(cat)
cwd=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
model=$(jq -r '.model.display_name' <<<"$input")
model="${model/ (1M context)/}"
transcript_path=$(jq -r '.transcript_path // ""' <<<"$input")

query_transcript() {
  if [[ -f "$transcript_path" ]]; then
    jq -s "$1" "$transcript_path" 2>/dev/null
  else
    echo null
  fi
}

thinking_mode=""
if [[ "$(query_transcript 'map(select(.thinkingMetadata)) | last | .thinkingMetadata.disabled')" == "false" ]]; then
  thinking_mode=yes
fi

last_action=""
last_tool_json=$(query_transcript '[.[] | select(.message.role == "assistant" and .message.content) | .message.content[] | select(.type == "tool_use")] | last')
if [[ -n "$last_tool_json" && "$last_tool_json" != null ]]; then
  tool_name=$(jq -r '.name // ""' <<<"$last_tool_json")
  tool_desc=$(jq -r '.input.description // ""' <<<"$last_tool_json")
  tool_file=$(jq -r '.input.file_path // ""' <<<"$last_tool_json")
  if [[ -n "$tool_file" && "$tool_file" != null ]]; then
    last_action="${tool_name}: $(basename "$tool_file")"
  elif [[ -n "$tool_desc" && "$tool_desc" != null ]]; then
    if (( ${#tool_desc} > 30 )); then
      last_action="${tool_name}: ${tool_desc:0:27}..."
    else
      last_action="${tool_name}: ${tool_desc}"
    fi
  else
    last_action="$tool_name"
  fi
fi

fg0="251;241;199"
c_red="193;18;28" c_orange="214;93;14" c_yellow="215;153;33" c_greenl="197;202;48" c_green="138;201;38"
c_aqua="104;157;106" c_bblue="25;130;196" c_blue="0;56;123" c_bpurple="127;98;169" c_purple="203;137;167"
c_bg3="84;88;90" c_bg1="60;56;54"
reset=$'\033[0m'
start_sep=$(printf '')
main_sep=$(printf '')
end_sep=$(printf '')

seg() { printf '\033[38;2;%sm\033[48;2;%sm%s%s' "$fg0" "$1" "$2" "$reset"; }
sep() { printf '\033[38;2;%sm\033[48;2;%sm%s%s' "$1" "$2" "$main_sep" "$reset"; }

sym_starburst=$(printf '❋')
sym_home=$(printf '')
sym_docs=$(printf '9')
sym_repos=$(printf '')
sym_tree=$(printf '')
sym_agent=$(printf '')
sym_music=$(printf 'a')
sym_videos=$(printf '')
sym_desktop=$(printf '')
sym_downloads=$(printf '')
sym_pictures=$(printf '')
sym_git_branch=$(printf '')
sym_time=$(printf '')
sym_thinking=$(printf '◉')

glyph_dir() {
  local path=$1 prefix glyph rest
  local -a table=(
    "${STATUSLINE_TREE:-/usr/local/src}|$sym_tree"
    "${STATUSLINE_AGENT_HOME:-/var/lib/agent}|$sym_agent"
    "$HOME/.local/user-dirs/Repos|$sym_repos"
    "$HOME/Documents|$sym_docs"
    "$HOME/Downloads|$sym_downloads"
    "$HOME/Pictures|$sym_pictures"
    "$HOME/Music|$sym_music"
    "$HOME/Videos|$sym_videos"
    "$HOME/Desktop|$sym_desktop"
    "$HOME|$sym_home"
  )
  for entry in "${table[@]}"; do
    prefix=${entry%%|*}
    glyph=${entry#*|}
    if [[ "$path" == "$prefix" || "$path" == "$prefix/"* ]]; then
      rest=${path#"$prefix"}
      printf '%s %s' "$glyph" "${rest#/}"
      return
    fi
  done
  IFS=/ read -ra parts <<<"$path"
  if (( ${#parts[@]} > 4 )); then
    printf '/…/%s' "${parts[-1]}"
  else
    printf '%s' "$path"
  fi
}

who=$(id -un)
[[ -n "${SSH_CONNECTION:-}" ]] && who="$who @ $(hostname)"

out=$(printf '\033[38;2;%sm%s%s' "$c_red" "$start_sep" "$reset")
out+=$(seg "$c_red" "$sym_starburst")
out+=$(sep "$c_red" "$c_orange")
out+=$(seg "$c_orange" " ${last_action:-$who} ")
out+=$(sep "$c_orange" "$c_yellow")
out+=$(seg "$c_yellow" " $(glyph_dir "$cwd") ")
out+=$(sep "$c_yellow" "$c_greenl")
out+=$(seg "$c_greenl" "")
out+=$(sep "$c_greenl" "$c_green")
out+=$(seg "$c_green" "")
out+=$(sep "$c_green" "$c_aqua")

if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [[ -n "$branch" ]] || branch=detached
  git_status=""
  if git -C "$cwd" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    ahead=$(git -C "$cwd" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
    (( ahead > 0 )) && git_status+=" ⇡"
    (( behind > 0 )) && git_status+=" ⇣"
  fi
  out+=$(seg "$c_aqua" " ${sym_git_branch} ${branch}${git_status} ")
fi

out+=$(sep "$c_aqua" "$c_bblue")
out+=$(seg "$c_bblue" "")
out+=$(sep "$c_bblue" "$c_blue")
out+=$(seg "$c_blue" "")
out+=$(sep "$c_blue" "$c_bpurple")
out+=$(seg "$c_bpurple" "")
out+=$(sep "$c_bpurple" "$c_purple")
out+=$(seg "$c_purple" "")
out+=$(sep "$c_purple" "$c_bg3")
if [[ "$thinking_mode" == yes ]]; then
  out+=$(seg "$c_bg3" " ${sym_thinking} ${model} ")
else
  out+=$(seg "$c_bg3" " ${model} ")
fi
out+=$(sep "$c_bg3" "$c_bg1")
out+=$(seg "$c_bg1" " ${sym_time} $(date +%R) ")
out+=$(printf '\033[38;2;%sm%s%s ' "$c_bg1" "$end_sep" "$reset")
printf '%s\n' "$out"
