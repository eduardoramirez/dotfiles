#!/usr/bin/env bash
#
# Update dotfiles and system packages
# Usage: ./update.sh [--all|--dotfiles|--brew|--plugins]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }

update_dotfiles() {
    log_info "Updating dotfiles..."
    cd "$DOTFILES_DIR"
    git pull --rebase
    log_success "Dotfiles updated!"
}

update_brew() {
    log_info "Updating Homebrew packages..."
    brew update
    brew upgrade
    brew cleanup
    log_success "Homebrew packages updated!"
}

update_plugins() {
    log_info "Updating shell plugins..."
    if command -v sheldon &> /dev/null; then
        sheldon lock --update
        log_success "Shell plugins updated!"
    else
        echo "Sheldon not found, skipping plugin update"
    fi
}

update_all() {
    update_dotfiles
    update_brew
    update_plugins
}

case "${1:-all}" in
    --all|all)
        update_all
        ;;
    --dotfiles|dotfiles)
        update_dotfiles
        ;;
    --brew|brew)
        update_brew
        ;;
    --plugins|plugins)
        update_plugins
        ;;
    *)
        echo "Usage: $0 [--all|--dotfiles|--brew|--plugins]"
        exit 1
        ;;
esac
