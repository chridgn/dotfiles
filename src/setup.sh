#!/bin/bash

cd "$(dirname "$0")"

ZSH="$HOME/.oh-my-zsh"
if [ ! -d "$ZSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "oh-my-zsh already installed."
fi

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
brew update

programs=(
    "zsh:.zshrc"
    "zsh:.zprofile"
    "tmux:.tmux.conf"
    "neofetch:.config/neofetch/config.conf"
    "starship:.config/starship.toml"
    "nvim:.config/nvim/init.lua"
)

function setlink {
    local FILE=$1;

    if [ -f ~/"$FILE" ] || [ -L ~/"$FILE" ]; then
	rm ~/"$FILE";
    fi

    ln -s "$(pwd)/$FILE" ~/"$FILE";
    echo "symlinked ~/$FILE -> $(pwd)/$FILE"
}

for PROGRAM in "${programs[@]}"; do
    prog="${PROGRAM%%:*}"
    file="${PROGRAM#*:}"
    if [ "$prog" != "zsh" ]; then
        if ! command -v "$prog" &> /dev/null; then
            if command -v brew &> /dev/null; then
                brew install "$prog"
            elif command -v apt-get &> /dev/null; then
                sudo apt-get install -y "$prog"
            else
                echo "No package manager found to install $prog"
            fi
        else echo "$prog already installed."
        fi
    fi
    mkdir -p ~/$(dirname "$file")
    setlink "$file"
done

# Custom installs
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
else echo "Claude Code already installed."
fi

