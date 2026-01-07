#!/usr/bin/env bash
#
# Dotfiles installation script
# Usage: ./install.sh [options]
#
# Options:
#   --dry-run           Show what would be done without making changes
#   --profile=PROFILE   Use specific profile (personal|work), default: personal
#   --no-backup         Skip backup of existing files
#   --no-brew           Skip Homebrew installation
#   --no-macos          Skip macOS defaults configuration
#   --help              Show this help message

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${DOTFILES_DIR}/.install.log"

# Defaults
DRY_RUN=false
PROFILE="personal"
NO_BACKUP=false
NO_BREW=false
NO_MACOS=false

# ============================================================================
# Colors and Logging
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2; }

# ============================================================================
# Parse Arguments
# ============================================================================

show_help() {
    sed -n '2,/^$/s/^#//p' "$0"
    exit 0
}

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --profile=*)
            PROFILE="${arg#*=}"
            ;;
        --no-backup)
            NO_BACKUP=true
            ;;
        --no-brew)
            NO_BREW=true
            ;;
        --no-macos)
            NO_MACOS=true
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# ============================================================================
# Error Handling
# ============================================================================

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code $exit_code"
        log_error "Check $LOG_FILE for details"
        [[ -d "$BACKUP_DIR" ]] && log_info "Backups at: $BACKUP_DIR"
    fi
}
trap cleanup EXIT

# ============================================================================
# Utility Functions
# ============================================================================

command_exists() {
    command -v "$1" &> /dev/null
}

backup_file() {
    local file="$1"
    if [[ -e "$file" && "$NO_BACKUP" == "false" ]]; then
        mkdir -p "$BACKUP_DIR"
        local rel_path="${file#$HOME/}"
        local backup_path="${BACKUP_DIR}/${rel_path}"
        mkdir -p "$(dirname "$backup_path")"
        cp -RP "$file" "$backup_path"
        log_info "Backed up: $file"
    fi
}

safe_symlink() {
    local src="$1"
    local dest="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would link: $dest -> $src"
        return 0
    fi

    # Already correctly linked
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        log_info "Already linked: $dest"
        return 0
    fi

    backup_file "$dest"
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    ln -s "$src" "$dest"
    log_success "Linked: $dest -> $src"
}

download_file() {
    local url="$1"
    local dest="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would download: $url -> $dest"
        return 0
    fi

    log_info "Downloading: $url"
    if ! curl -fsSL --max-time 30 -o "$dest" "$url"; then
        log_error "Failed to download: $url"
        return 1
    fi
    log_success "Downloaded: $dest"
}

# ============================================================================
# Dependency Checks
# ============================================================================

check_dependencies() {
    log_info "Checking dependencies..."

    local missing=()

    if ! command_exists git; then
        log_error "Git is required"
        missing+=("git")
    fi

    if ! command_exists brew; then
        log_warning "Homebrew not found"
        missing+=("brew")
        if [[ "$NO_BREW" == "false" ]]; then
            log_info "Install with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        fi
    fi

    if [[ ${#missing[@]} -gt 0 && " ${missing[*]} " =~ " git " ]]; then
        log_error "Cannot continue without git"
        return 1
    fi

    log_success "Dependencies checked"
}

# ============================================================================
# Template Handling
# ============================================================================

create_from_template() {
    local template="$1"
    local dest="$2"

    if [[ ! -f "$template" ]]; then
        return 0
    fi

    if [[ -f "$dest" ]]; then
        log_info "Config exists: $dest (keeping existing)"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would create: $dest from template"
        return 0
    fi

    cp "$template" "$dest"
    log_success "Created from template: $dest"
    log_warning "  -> Edit this file with your settings"
}

setup_profile_templates() {
    log_info "Setting up ${PROFILE} profile templates..."

    # Git profile config
    create_from_template \
        "${DOTFILES_DIR}/config/git/config.${PROFILE}.template" \
        "${DOTFILES_DIR}/config/git/config.${PROFILE}"

    # Brewfile profile
    create_from_template \
        "${DOTFILES_DIR}/Brewfile.${PROFILE}.template" \
        "${DOTFILES_DIR}/Brewfile.${PROFILE}"
}

# ============================================================================
# Installation Steps
# ============================================================================

install_brew_packages() {
    if [[ "$NO_BREW" == "true" ]] || ! command_exists brew; then
        log_warning "Skipping Homebrew packages"
        return 0
    fi

    log_info "Installing Homebrew packages..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: brew bundle"
        return 0
    fi

    # Install base packages
    brew bundle --file="${DOTFILES_DIR}/Brewfile"

    # Install profile-specific packages
    local profile_brewfile="${DOTFILES_DIR}/Brewfile.${PROFILE}"
    if [[ -f "$profile_brewfile" ]]; then
        log_info "Installing ${PROFILE} profile packages..."
        brew bundle --file="$profile_brewfile"
    fi

    log_success "Homebrew packages installed"
}

setup_vim() {
    log_info "Setting up Vim configuration..."

    local vimrc_dest="${DOTFILES_DIR}/vimrc"

    # Download base vimrc (securely)
    download_file \
        "https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim" \
        "$vimrc_dest"

    # Append custom settings
    if [[ "$DRY_RUN" == "false" && -f "${DOTFILES_DIR}/vim/vimrc" ]]; then
        cat "${DOTFILES_DIR}/vim/vimrc" >> "$vimrc_dest"
    fi

    safe_symlink "$vimrc_dest" "${HOME}/.vimrc"

    log_success "Vim configured"
}

setup_git() {
    log_info "Setting up Git configuration..."

    # Main gitconfig
    safe_symlink "${DOTFILES_DIR}/config/git/config" "${HOME}/.gitconfig"

    # Profile-specific git config
    local git_profile="${DOTFILES_DIR}/config/git/config.${PROFILE}"
    if [[ -f "$git_profile" ]]; then
        safe_symlink "$git_profile" "${HOME}/.gitconfig.local"
    fi

    log_success "Git configured"
}

setup_zsh() {
    log_info "Setting up Zsh configuration..."

    safe_symlink "${DOTFILES_DIR}/zsh/zshrc" "${HOME}/.zshrc"
    safe_symlink "${DOTFILES_DIR}/zsh/zmodules" "${HOME}/.zmodules"

    # Sheldon configuration
    mkdir -p "${HOME}/.config/sheldon"
    safe_symlink "${DOTFILES_DIR}/config/sheldon/plugins.toml" "${HOME}/.config/sheldon/plugins.toml"

    log_success "Zsh configured"
}

setup_sheldon() {
    if ! command_exists sheldon; then
        log_warning "Sheldon not found, skipping plugin lock"
        return 0
    fi

    log_info "Initializing Sheldon plugins..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: sheldon lock"
        return 0
    fi

    sheldon lock

    log_success "Sheldon plugins initialized"
}

apply_macos_defaults() {
    if [[ "$NO_MACOS" == "true" ]]; then
        log_info "Skipping macOS defaults"
        return 0
    fi

    if [[ "$(uname)" != "Darwin" ]]; then
        log_info "Not macOS, skipping defaults"
        return 0
    fi

    local macos_script="${DOTFILES_DIR}/macos/defaults.sh"
    if [[ ! -f "$macos_script" ]]; then
        log_info "No macOS defaults script found"
        return 0
    fi

    log_info "Applying macOS defaults..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: $macos_script"
        return 0
    fi

    bash "$macos_script"

    log_success "macOS defaults applied"
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "=========================================="
    echo "  Dotfiles Installation"
    echo "  Profile: ${PROFILE}"
    [[ "$DRY_RUN" == "true" ]] && echo "  Mode: DRY RUN"
    echo "=========================================="
    echo ""

    # Initialize log
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "Installation started: $(date)" > "$LOG_FILE"
    echo "Profile: $PROFILE" >> "$LOG_FILE"

    check_dependencies
    setup_profile_templates
    install_brew_packages
    setup_vim
    setup_git
    setup_zsh
    setup_sheldon
    apply_macos_defaults

    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Review any warnings above"
    [[ -d "$BACKUP_DIR" ]] && echo "  3. Backups saved to: $BACKUP_DIR"
    echo ""
}

main
