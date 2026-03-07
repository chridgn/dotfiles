# ~/.zshrc

export ZSH="$HOME/.oh-my-zsh"

# Theme + plugins
ZSH_THEME=""
eval "$(starship init zsh)"
plugins=(git)

source "$ZSH/oh-my-zsh.sh"

setopt autocd              # cd by typing a directory name
setopt hist_ignore_dups    # don't store duplicate history entries
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

nvim() {
  if [[ -n "$TMUX" && $# -eq 1 && -d "$1" ]]; then
    local dir session_name
    dir="$(cd "$1" && pwd)"
    session_name="nvim_$(basename "$dir")"
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
      local width height
      width="$(tmux display-message -p '#{window_width}')"
      height="$(tmux display-message -p '#{window_height}')"
      tmux new-session -d -s "$session_name" -c "$dir" -x "$width" -y "$height"
      tmux send-keys -t "$session_name" "command nvim ." Enter
    fi
    tmux switch-client -t "$session_name"
  else
    command nvim "$@"
  fi
}

v() {
  local file=""

  if [[ $# -gt 0 ]]; then
    file="$1"
  elif command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
      file="$(fd --type f --hidden --follow --exclude .git . | fzf --prompt='open> ')"
    else
      file="$(find . -type f -not -path '*/.git/*' 2>/dev/null | fzf --prompt='open> ')"
    fi
  else
    echo "Usage: v <file> (or install fzf for interactive picker)" >&2
    return 1
  fi

  [[ -z "$file" ]] && return 0
  bash "$HOME/.local/bin/tmux-open-file-pane" "$file"
}

# Start or attach to a named tmux session (skip when running inside nvim)
if [ -z "$NVIM" ]; then
  if [ -z "$TMUX" ]; then
    exec tmux new-session -A -s "${TMUX_SESSION_NAME:-$(basename "$PWD")}"
  elif [ -n "$TMUX_SESSION_NAME" ]; then
    tmux switch-tmux new-session -A -s "${TMUX_SESSION_NAME:-$(basename "$PWD")}"
    client -t "$TMUX_SESSION_NAME"
  fi
fi
