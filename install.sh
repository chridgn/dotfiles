#!/usr/bin/env bash
# =============================================================================
# install.sh — bootstrap a new machine (macOS or Linux)
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS_TYPE="$(uname -s)"  # Darwin | Linux

# Bootstrap Homebrew into PATH early (Apple Silicon or Intel) so that
# `command -v brew` works even when the shell profile hasn't been sourced yet.
if [[ "$OS_TYPE" == "Darwin" ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && export PATH="/opt/homebrew/bin:$PATH"
  [[ -x /usr/local/bin/brew   ]] && export PATH="/usr/local/bin:$PATH"
fi

# --- Colors ------------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[install]${NC} $*"; }
warning() { echo -e "${YELLOW}[warning]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; }

# --- Package installation ----------------------------------------------------
install_packages_mac() {
  if command -v brew &>/dev/null; then
    info "Homebrew already installed — updating"
    brew update
  else
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  local formulae=(
    git
    curl
    wget
    fzf
    ripgrep
    fd
    bat
    jq
    tree
    htop
    tmux
    vim
    neovim
    starship
    nvm
  )

  local casks=(
    # Add GUI apps here, e.g.:
    # iterm2
    # visual-studio-code
  )

  info "Installing brew formulae"
  brew install "${formulae[@]}"

  if [ ${#casks[@]} -gt 0 ]; then
    info "Installing brew casks"
    brew install --cask "${casks[@]}"
  fi
}

install_packages_linux() {
  if ! command -v apt-get &>/dev/null; then
    error "Only apt-based Linux distros are supported (Raspberry Pi OS, Debian, Ubuntu)"
    exit 1
  fi

  info "Updating apt"
  sudo apt-get update -y

  local packages=(
    git
    curl
    wget
    fzf
    ripgrep
    fd-find
    bat
    jq
    tree
    htop
    tmux
    vim
    neovim
  )

  info "Installing apt packages"
  sudo apt-get install -y "${packages[@]}"

  # Some Debian/Ubuntu packages install under different binary names
  # fd-find → fd, batcat → bat — create shims if needed
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    info "Linked fdfind → ~/.local/bin/fd"
  fi
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    info "Linked batcat → ~/.local/bin/bat"
  fi

  # starship — no apt package, use the official installer
  if ! command -v starship &>/dev/null; then
    info "Installing starship"
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # nvm — no apt package, use the official installer
  if [ ! -d "$HOME/.nvm" ]; then
    info "Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
}

# --- fzf shell integration ---------------------------------------------------
setup_fzf() {
  if ! command -v fzf &>/dev/null; then
    warning "fzf not found, skipping shell integration"
    return
  fi

  info "Setting up fzf shell integration"
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
  else
    # On Linux, fzf installs its own integration script
    if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
      mkdir -p "$HOME/.local/share/fzf"
      cp /usr/share/doc/fzf/examples/key-bindings.zsh "$HOME/.fzf.zsh"
      info "Copied fzf key bindings to ~/.fzf.zsh"
    fi
  fi
}

# --- Symlink dotfiles --------------------------------------------------------
link_file() {
  local src="$1" dst="$2"
  if [ -f "$dst" ] && [ ! -L "$dst" ]; then
    warning "Backing up existing $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sf "$src" "$dst"
  info "Linked $dst → $src"
}

symlink_dotfiles() {
  link_file "$DOTFILES_DIR/.zshrc_ext"    "$HOME/.zshrc_ext"
  link_file "$DOTFILES_DIR/.zprofile_ext" "$HOME/.zprofile_ext"
  link_file "$DOTFILES_DIR/.tmux.conf"    "$HOME/.tmux.conf"
}

# --- Patch shell files -------------------------------------------------------
append_if_missing() {
  local file="$1" line="$2"
  touch "$file"
  if ! grep -qF "$line" "$file"; then
    echo "$line" >> "$file"
    info "Added source line to $file"
  else
    info "$file already sources the extension file"
  fi
}

patch_shell_files() {
  append_if_missing "$HOME/.zshrc"    '[ -f ~/.zshrc_ext ] && source ~/.zshrc_ext'
  append_if_missing "$HOME/.zprofile" '[ -f ~/.zprofile_ext ] && source ~/.zprofile_ext'
}

# --- Ensure zsh is installed on Linux ----------------------------------------
ensure_zsh_linux() {
  if ! command -v zsh &>/dev/null; then
    info "Installing zsh"
    sudo apt-get install -y zsh
  fi
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    info "Changing default shell to zsh"
    chsh -s "$(command -v zsh)"
  fi
}

# --- Main --------------------------------------------------------------------
main() {
  info "Starting dotfiles install (OS: $OS_TYPE)"

  if [[ "$OS_TYPE" == "Darwin" ]]; then
    install_packages_mac
  elif [[ "$OS_TYPE" == "Linux" ]]; then
    ensure_zsh_linux
    install_packages_linux
  else
    error "Unsupported OS: $OS_TYPE"
    exit 1
  fi

  symlink_dotfiles
  patch_shell_files
  setup_fzf
  info "Done! Restart your shell or run: source ~/.zshrc"
}

main "$@"
