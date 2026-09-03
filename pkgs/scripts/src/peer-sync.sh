# shellcheck shell=bash
# peer-sync: two-way newest-wins sync of selected directories with a peer host.
#
# Each set is synced with two rsync --update passes (pull, then push), so for
# every file the copy with the newer mtime wins on both ends. Nothing is ever
# deleted. Paths must match on both hosts.
set -euo pipefail

# "dir|exclude,exclude,..." — dir must end with /
sets=(
  "$HOME/.local/share/FasterThanLight/|settings.ini,steam_autocloud.vdf"
)

case "$(uname -n)" in
  bubblegum) peer=thoughtful ;;
  *) peer=bubblegum ;;
esac
[[ $# -ge 1 ]] && peer=$1

echo "Syncing with $peer (newest wins)..."
for set in "${sets[@]}"; do
  dir=${set%%|*}
  args=(-au -s --info=name)
  IFS=, read -ra excludes <<<"${set#*|}"
  for e in "${excludes[@]}"; do
    [[ -n "$e" ]] && args+=("--exclude=$e")
  done
  echo "== $dir"
  rsync "${args[@]}" "$peer:$dir" "$dir"
  rsync "${args[@]}" "$dir" "$peer:$dir"
done
echo "Done."
