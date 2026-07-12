# shellcheck shell=bash

project_root="$HOME/dev"
separator=$'\x1f'

declare -A listed_sessions=()
declare -A project_sessions=()
declare -A session_attached=()
declare -A session_paths=()
declare -a entries=()
declare -a session_names=()

while IFS="$separator" read -r name path attached project; do
  [[ -n "$name" ]] || continue
  [[ "$name" != *$'\t'* && "$name" != *$'\n'* ]] || continue
  session_names+=("$name")
  session_paths["$name"]="$path"
  session_attached["$name"]="$attached"
  if [[ -n "$project" ]]; then
    project_sessions["$project"]="$name"
  fi
done < <(
  tmux list-sessions \
    -F '#{session_name}'"$separator"'#{pane_current_path}'"$separator"'#{session_attached}'"$separator"'#{@project-root}' \
    2>/dev/null || true
)

shopt -s nullglob
for project in "$project_root"/*; do
  [[ -d "$project" ]] || continue
  [[ "$project" != *$'\t'* && "$project" != *$'\n'* && "$project" != *"$separator"* ]] || continue

  name="${project##*/}"
  target="-"
  state="new"
  if [[ -n "${project_sessions[$project]+present}" ]]; then
    target="${project_sessions[$project]}"
    listed_sessions["$target"]=1
    state="running"
    if [[ "${session_attached[$target]}" != 0 ]]; then
      state="attached"
    fi
  fi

  display_path="$project"
  if [[ "$display_path" == "$HOME"* ]]; then
    display_path="~${display_path#"$HOME"}"
  fi
  printf -v label '%-9s %-20s %s' "$state" "$name" "$display_path"
  entries+=("project"$'\t'"$target"$'\t'"$project"$'\t'"$label")
done

for name in "${session_names[@]}"; do
  [[ -z "${listed_sessions[$name]+present}" ]] || continue

  state="session"
  if [[ "${session_attached[$name]}" != 0 ]]; then
    state="attached"
  fi
  path="${session_paths[$name]}"
  display_path="$path"
  if [[ "$display_path" == "$HOME"* ]]; then
    display_path="~${display_path#"$HOME"}"
  fi
  display_path="${display_path//$'\t'/ }"
  display_path="${display_path//$'\n'/ }"
  printf -v label '%-9s %-20s %s' "$state" "$name" "$display_path"
  entries+=("session"$'\t'"$name"$'\t'"-"$'\t'"$label")
done

if ((${#entries[@]} == 0)); then
  exit 0
fi

if ! selection=$(
  printf '%s\n' "${entries[@]}" \
    | fzf \
      --delimiter=$'\t' \
      --with-nth=4 \
      --prompt='tmux> ' \
      --header='Select a project/session; Esc opens a normal shell' \
      --reverse
); then
  exit 0
fi

IFS=$'\t' read -r kind name path _ <<<"$selection"
case "$kind" in
  project)
    if [[ "$name" != "-" ]]; then
      exec tmux attach-session -t "$name"
    fi

    name="${path##*/}"
    name="${name//[^[:alnum:]_-]/-}"
    [[ -n "$name" ]] || name="project"
    candidate="$name"
    suffix=2
    while tmux has-session -t "$candidate" 2>/dev/null; do
      candidate="$name-$suffix"
      ((suffix += 1))
    done

    tmux new-session -d -s "$candidate" -c "$path"
    tmux set-option -t "$candidate" @project-root "$path"
    exec tmux attach-session -t "$candidate"
    ;;
  session)
    exec tmux attach-session -t "$name"
    ;;
esac
