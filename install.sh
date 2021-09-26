apply() {
  local src="$(pwd)/$1"
  local dest="${HOME}/.$(basename "$1")"

  ln -fns "$src" "$dest"
}

echo "Installing brew apps......"
brew bundle

echo "Applying configs..."
curl -s -o "vimrc" -k "https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim"
cat "vim/vimrc" >> "vimrc"

apply gitconfig
apply vimrc
apply zsh/zplugins
apply zsh/zmodules
apply zsh/zshrc

echo "Done"
