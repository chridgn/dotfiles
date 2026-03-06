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

# with all things configured, start tmux
