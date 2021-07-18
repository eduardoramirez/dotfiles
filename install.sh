apply() {
  local src="$(pwd)/$1"
  local dest="${HOME}/.$(basename "$1")"

  ln -fns "$src" "$dest"
}

echo "Installing brew apps..."
brew bundle

echo "Applying configs..."
apply gitconfig
apply zsh/zplugins
apply zsh/zmodules
apply zsh/zshrc

mkdir -p ~/.config
ln -fns "$(pwd)/nvim" ~/.config/nvim

echo "Done"
