# ~/.zprofile

if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

# Homebrew (Apple Silicon: /opt/homebrew, Intel: /usr/local)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# User bins (portable)
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Sublime Text command line tool (macOS)
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"

# User Python scripts (macOS; keep if you use pip --user)
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# Environment Variablesx
