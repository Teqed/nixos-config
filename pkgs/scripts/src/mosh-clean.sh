# shellcheck shell=bash
# mosh-clean: find and kill orphaned mosh-server sessions.
#
# A session counts as orphaned when utmp (who -u) shows no client address
# for it — "(mosh [PID])" instead of "(1.2.3.4 via mosh [PID])". Sessions
# with a connected client and the session this script runs inside are
# always kept.
set -euo pipefail

dry_run=0
assume_yes=0

usage() {
  cat <<'EOF'
Usage: mosh-clean [-n] [-y]
Find orphaned mosh-server sessions (no connected client) and kill them.

  -n, --dry-run  Only report, do not kill anything
  -y, --yes      Kill without prompting
  -h, --help     Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n | --dry-run) dry_run=1 ;;
    -y | --yes) assume_yes=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

# PIDs in our own ancestry — never kill the session we are running inside.
declare -A ancestors=()
p=$$
while [[ -n "$p" && "$p" != 1 ]]; do
  ancestors[$p]=1
  p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ') || break
done

who_output=$(who -u 2>/dev/null || true)

orphans=()
found_any=0
while read -r pid; do
  [[ -n "$pid" ]] || continue
  found_any=1
  info=$(ps -o lstart=,etime= -p "$pid" 2>/dev/null | sed 's/  */ /g; s/^ //') || info="?"
  if [[ -n "${ancestors[$pid]:-}" ]]; then
    echo "KEEP    $pid  this script is running inside it; started $info"
  elif grep -q "via mosh \[$pid\]" <<<"$who_output"; then
    client=$(grep -o "([^)]* via mosh \[$pid\])" <<<"$who_output" | head -n 1)
    echo "KEEP    $pid  client connected $client; started $info"
  else
    echo "ORPHAN  $pid  no connected client; started $info"
    orphans+=("$pid")
  fi
done < <(pgrep -u "$(id -un)" -x mosh-server || true)

if [[ $found_any -eq 0 ]]; then
  echo "No mosh-server processes for user $(id -un)."
  exit 0
fi

if [[ ${#orphans[@]} -eq 0 ]]; then
  echo "No orphaned sessions."
  exit 0
fi

if [[ $dry_run -eq 1 ]]; then
  echo "Dry run: would kill ${orphans[*]}"
  exit 0
fi

if [[ $assume_yes -ne 1 ]]; then
  read -r -p "Kill ${#orphans[@]} orphaned session(s) [${orphans[*]}]? [y/N] " reply
  [[ "$reply" =~ ^[Yy] ]] || {
    echo "Aborted."
    exit 1
  }
fi

kill -- "${orphans[@]}"
sleep 1
for pid in "${orphans[@]}"; do
  if kill -0 "$pid" 2>/dev/null; then
    echo "WARNING: $pid still running after SIGTERM (kill -9 $pid to force)" >&2
  else
    echo "Killed $pid."
  fi
done
