dotfiles=(
    ".zshrc"
    ".zprofile"
    ".tmux.conf"
    ".config/neofetch/config.conf"
    ".config/starship.toml"
)

function setlink {
    local FILE=$1; 

    if [ -f ~/"$FILE" ]; then
	rm ~/"$FILE";
    fi 

    sudo ln "$FILE" ~/"$FILE";
    echo "symlinked ~/$FILE to $FILE"
}

for FILE in "${dotfiles[@]}"; do
    setlink $FILE
done

