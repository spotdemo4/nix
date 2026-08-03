# shellcheck shell=bash

project_path=${1:-$PWD}
separator=$'\x1f'
lock_file=${XDG_RUNTIME_DIR:-/tmp}/tmux-project-session-$UID.lock

if [[ "${2:-}" != "--locked" ]]; then
  session=$(
    flock --exclusive --close "$lock_file" "$0" "$project_path" --locked
  )
  exec tmux attach-session -t "$session"
fi

while IFS="$separator" read -r name path; do
  if [[ "$path" == "$project_path" ]]; then
    printf '%s\n' "$name"
    exit 0
  fi
done < <(
  tmux list-sessions -F '#{session_name}'"$separator"'#{@project-root}' 2>/dev/null || true
)

name=${project_path##*/}
name=${name//[^[:alnum:]_-]/-}
[[ -n "$name" ]] || name=project
candidate=$name
suffix=2
while tmux has-session -t "$candidate" 2>/dev/null; do
  candidate="$name-$suffix"
  ((suffix += 1))
done

tmux new-session -d -s "$candidate" -c "$project_path"
tmux set-option -t "$candidate" @project-root "$project_path"
printf '%s\n' "$candidate"
