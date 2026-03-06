#!/bin/bash

cd src

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

    if [ -f ~/"$FILE" ]; then
	rm ~/"$FILE";
    fi 

    ln "$FILE" ~/"$FILE";
    echo "symlinked ~/$FILE to $FILE"
}

for PROGRAM in "${programs[@]}"; do
    IFS=":" read -r -a arr <<< "$PROGRAM"
    if [ "${arr[0]}" != "zsh" ]; then
        if ! command -v "${arr[0]}" &> /dev/null; then
	    brew install "${arr[0]}"
	    else echo "${arr[0]} already installed."
        fi
    fi
    setlink "${arr[1]}"
done

# Custom installs
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code"
    curl -fsSL httpsL//claude.ai/install.sh | bash
else echo "Claude Code already installed."
fi

