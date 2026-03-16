#!/bin/bash

# Dotfiles Installation Script
# This script sets up the zsh configuration and installs required dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect package manager
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Function to install packages based on package manager
install_packages() {
    local pm=$1

    log_info "Installing packages using $pm..."

    case $pm in
        apt)
            sudo apt update
            sudo apt install -y zsh git curl wget

            # Install Rust if not present
            if ! command -v cargo >/dev/null 2>&1; then
                log_info "Installing Rust..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            fi

            # Install tools via cargo
            log_info "Installing zoxide, bat, and eza via cargo..."
            cargo install zoxide bat eza

            # Note: On some systems, bat might be installed as batcat
            if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
                sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
            fi
            ;;

        dnf)
            sudo dnf install -y zsh git curl wget

            # Install Rust
            if ! command -v cargo >/dev/null 2>&1; then
                log_info "Installing Rust..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            fi

            # Install tools
            cargo install zoxide bat eza
            ;;

        pacman)
            sudo pacman -Syu --noconfirm zsh git curl wget rustup

            # Install Rust if not present
            if ! command -v cargo >/dev/null 2>&1; then
                rustup install stable
                rustup default stable
            fi

            cargo install zoxide bat eza
            ;;

        brew)
            brew install zsh git curl wget rustup-init

            # Install Rust
            if ! command -v cargo >/dev/null 2>&1; then
                rustup-init -y
                source "$HOME/.cargo/env"
            fi

            cargo install zoxide bat eza
            ;;

        *)
            log_error "Unsupported package manager. Please install manually:"
            log_error "  - zsh, git, curl, wget"
            log_error "  - Rust (https://rustup.rs/)"
            log_error "  - zoxide, bat, eza (via cargo install)"
            exit 1
            ;;
    esac
}

# Function to backup existing .zshrc
backup_zshrc() {
    if [ -f "$HOME/.zshrc" ]; then
        local backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.zshrc" "$backup_file"
        log_info "Backed up existing .zshrc to $backup_file"
    fi
}

# Function to symlink .zshrc
symlink_zshrc() {
    local dotfiles_dir
    dotfiles_dir=$(pwd)
    ln -sf "$dotfiles_dir/.zshrc" "$HOME/.zshrc"
    log_info "Symlinked .zshrc from $dotfiles_dir/.zshrc"
}

# Function to change shell to zsh
change_shell() {
    local zsh_path
    zsh_path=$(which zsh)

    if [ "$SHELL" != "$zsh_path" ]; then
        log_info "Changing shell to zsh..."
        chsh -s "$zsh_path"
        log_warn "Shell changed to zsh. Please restart your terminal or run 'exec zsh'."
    else
        log_info "Shell is already set to zsh"
    fi
}

# Main installation function
main() {
    log_info "Starting dotfiles installation..."

    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root. It will use sudo when necessary."
        exit 1
    fi

    # Detect package manager
    local pm
    pm=$(detect_package_manager)

    if [ "$pm" = "unknown" ]; then
        log_warn "Could not detect package manager. Attempting manual installation..."
        log_error "Please install required packages manually and re-run this script."
        exit 1
    else
        log_info "Detected package manager: $pm"
        install_packages "$pm"
    fi

    # Backup and symlink
    backup_zshrc
    symlink_zshrc

    # Change shell
    change_shell

    log_info "Installation complete!"
    log_info "Run 'source ~/.zshrc' or restart your terminal to apply changes."
    log_info "You may need to install a Nerd Font for proper icon display in the terminal."
}

# Run main function
main "$@"