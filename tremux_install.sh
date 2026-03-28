#!/data/data/com.termux/files/usr/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

install_packages() {
    log_info "Updating Termux packages..."
    pkg update -y && pkg upgrade -y

    log_info "Installing dependencies..."
    pkg install -y zsh git curl wget clang make

    # Install Rust (needed for cargo tools)
    if ! command -v cargo >/dev/null 2>&1; then
        log_info "Installing Rust..."
        pkg install -y rust
    fi

    log_info "Installing tools via cargo..."
    cargo install zoxide bat eza
}

backup_zshrc() {
    if [ -f "$HOME/.zshrc" ]; then
        backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.zshrc" "$backup_file"
        log_info "Backed up existing .zshrc to $backup_file"
    fi
}

symlink_zshrc() {
    dotfiles_dir=$(pwd)
    ln -sf "$dotfiles_dir/.zshrc" "$HOME/.zshrc"
    log_info "Symlinked .zshrc"
}

setup_zsh() {
    log_info "Setting zsh as default shell..."

    # Termux way (NOT chsh)
    echo "exec zsh" >> ~/.bashrc

    log_warn "Restart Termux or run: exec zsh"
}

main() {
    log_info "Starting Termux dotfiles setup..."

    install_packages
    backup_zshrc
    symlink_zshrc
    setup_zsh

    log_info "Done 🚀"
}

main