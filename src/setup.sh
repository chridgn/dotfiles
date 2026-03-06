#!/bin/bash

cd src

programs=(
    "zsh:.zshrc"
    "zsh:.zprofile"
    "tmux:.tmux.conf"
    "neofetch:.config/neofetch/config.conf"
    "starship:.config/starship.toml"
    "neovim:.config/nvim/init.lua"
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
        brew install "${arr[0]}"
    fi
    setlink "${arr[1]}"
done

