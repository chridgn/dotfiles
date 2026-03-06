files=(".zshrc" ".config/starship.toml")

function setlink {
    local FILE=$1; 

    if [ -f ~/"$FILE" ]; then
	rm ~/"$FILE";
    fi 

    sudo ln $(basename "$FILE") ~/"$FILE";
}

for FILE in "${files[@]}"; do
    setlink $FILE
done

