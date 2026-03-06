files=(
    ".zshrc"
    ".zprofile"
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

for FILE in "${files[@]}"; do
    setlink $FILE
done

