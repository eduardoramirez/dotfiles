#!/usr/bin/env bash
#
# Backup and Restore utility for dotfiles
# Usage:
#   ./scripts/backup-restore.sh backup [destination]
#   ./scripts/backup-restore.sh restore <backup_dir>
#   ./scripts/backup-restore.sh list

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_BACKUP_BASE="${HOME}/.dotfiles_backup"

# Files/dirs to backup
BACKUP_TARGETS=(
    ".zshrc"
    ".zshenv"
    ".zmodules"
    ".zplugins"
    ".gitconfig"
    ".gitconfig.local"
    ".vimrc"
    ".config/sheldon"
)

backup() {
    local dest="${1:-${DEFAULT_BACKUP_BASE}/$(date +%Y%m%d_%H%M%S)}"
    mkdir -p "$dest"

    echo "Creating backup in $dest..."

    for target in "${BACKUP_TARGETS[@]}"; do
        local src="${HOME}/${target}"
        if [[ -e "$src" ]]; then
            local target_dir
            target_dir="$(dirname "${dest}/${target}")"
            mkdir -p "$target_dir"
            cp -RP "$src" "${dest}/${target}"
            echo "  Backed up: $target"
        fi
    done

    # Save metadata
    {
        echo "Backup created: $(date)"
        echo "Dotfiles version: $(cd "$DOTFILES_DIR" && git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    } > "${dest}/.backup_info"

    echo "Backup complete: $dest"
}

restore() {
    local src="${1:-}"

    if [[ -z "$src" ]]; then
        echo "Usage: $0 restore <backup_dir>"
        exit 1
    fi

    if [[ ! -d "$src" ]]; then
        echo "Error: Backup directory not found: $src"
        exit 1
    fi

    echo "Restoring from $src..."

    for target in "${BACKUP_TARGETS[@]}"; do
        local backup_file="${src}/${target}"
        local dest="${HOME}/${target}"
        if [[ -e "$backup_file" ]]; then
            local target_dir
            target_dir="$(dirname "$dest")"
            mkdir -p "$target_dir"
            cp -RP "$backup_file" "$dest"
            echo "  Restored: $target"
        fi
    done

    echo "Restore complete!"
}

list_backups() {
    echo "Available backups in ${DEFAULT_BACKUP_BASE}:"
    if [[ -d "$DEFAULT_BACKUP_BASE" ]]; then
        for backup in "${DEFAULT_BACKUP_BASE}"/*/; do
            if [[ -d "$backup" ]]; then
                echo "  $(basename "$backup")"
                if [[ -f "${backup}/.backup_info" ]]; then
                    sed 's/^/    /' "${backup}/.backup_info"
                fi
            fi
        done
    else
        echo "  No backups found"
    fi
}

case "${1:-}" in
    backup)
        backup "${2:-}"
        ;;
    restore)
        restore "${2:-}"
        ;;
    list)
        list_backups
        ;;
    *)
        echo "Usage: $0 {backup|restore|list} [path]"
        exit 1
        ;;
esac
