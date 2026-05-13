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
    elif command -v xbps-install >/dev/null 2>&1; then
        echo "xbps"
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

        xbps)
            sudo xbps-install -Suv
            sudo xbps-install -y zsh git curl wget base-devel

            # Install Rust if not present
            if ! command -v cargo >/dev/null 2>&1; then
                log_info "Installing Rust..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            fi

            # Install tools via cargo
            log_info "Installing zoxide, bat, and eza via cargo..."
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

# Function to force a symlink, replacing any existing file or symlink
force_symlink() {
    local source_path=$1
    local target_path=$2

    mkdir -p "$(dirname "$target_path")"
    ln -sfn "$source_path" "$target_path"
}

# Function to install waybar based on package manager
install_waybar() {
    local pm=$1

    log_info "Installing waybar using $pm..."

    case $pm in
        apt)
            sudo apt install -y waybar
            ;;

        dnf)
            sudo dnf install -y waybar
            ;;

        pacman)
            sudo pacman -S --noconfirm waybar
            ;;

        xbps)
            sudo xbps-install -y waybar
            ;;

        brew)
            log_warn "waybar is not generally available via Homebrew on Linux. Please install it manually if needed."
            return 0
            ;;

        *)
            log_warn "Unsupported package manager for waybar. Please install it manually."
            return 0
            ;;
    esac

    log_info "waybar is installed"
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

# Function to install niri based on package manager
install_niri() {
    local pm=$1

    log_info "Installing niri using $pm..."

    case $pm in
        apt)
            if ! command -v niri >/dev/null 2>&1; then
                if ! sudo apt install -y niri; then
                    log_warn "niri not available in apt repositories. Please install manually from https://github.com/YaLTeR/niri"
                    return 0
                fi
            fi
            ;;

        dnf)
            if ! command -v niri >/dev/null 2>&1; then
                if ! sudo dnf install -y niri; then
                    log_warn "niri not available in dnf repositories. Please install manually from https://github.com/YaLTeR/niri"
                    return 0
                fi
            fi
            ;;

        pacman)
            if ! command -v niri >/dev/null 2>&1; then
                if command -v yay >/dev/null 2>&1; then
                    log_info "Installing niri from AUR using yay..."
                    yay -S niri --noconfirm
                fi
                if command -v paru >/dev/null 2>&1; then
                    log_info "Installing niri from AUR using paru..."
                    paru -S niri --noconfirm
                else
                    if ! sudo pacman -S --noconfirm niri; then
                        log_warn "niri not available in pacman repositories and yay was not found. Please install manually from AUR or https://github.com/YaLTeR/niri"
                        return 0
                    fi
                fi
            fi
            ;;

        xbps)
            # Void Linux package
            if ! command -v niri >/dev/null 2>&1; then
                if ! sudo xbps-install -y niri; then
                    log_warn "niri not available in xbps repositories. Please install manually from https://github.com/YaLTeR/niri"
                    return 0
                fi
            
            fi
            ;;

        brew)
            # macOS
            if ! command -v niri >/dev/null 2>&1; then
                log_warn "niri is linux wm and not available on macOS."
                return 0
            fi
            ;;
    esac

    log_info "niri is installed"
}
install-waybar() {
    local pm=$1

    log_info "Installing waybar using $pm..."

    case $pm in
        apt)
            sudo apt install -y waybar
            ;;

        dnf)
            sudo dnf install -y waybar
            ;;

        pacman)
            sudo pacman -S --noconfirm waybar
            ;;

        xbps)
            sudo xbps-install -y waybar
            ;;

        brew)
            log_warn "waybar is not generally available via Homebrew on Linux. Please install it manually if needed."
            return 0
            ;;

        *)
            log_warn "Unsupported package manager for waybar. Please install it manually."
            return 0
            ;;
    esac

    log_info "waybar is installed"
}

# Function to install rofi based on package manager
install_rofi() {
    local pm=$1

    log_info "Installing rofi using $pm..."

    case $pm in
        apt)
            sudo apt install -y rofi
            ;;

        dnf)
            sudo dnf install -y rofi
            ;;

        pacman)
            sudo pacman -S --noconfirm rofi
            ;;

        xbps)
            sudo xbps-install -y rofi
            ;;

        brew)
            brew install rofi
            ;;

        *)
            log_warn "Unsupported package manager for rofi. Please install it manually."
            return 0
            ;;
    esac

    log_info "rofi is installed"
}

# Function to configure rofi
configure_rofi() {
    local dotfiles_dir
    local rofi_config_dir
    dotfiles_dir=$(pwd)
    rofi_config_dir="$HOME/.config/rofi"

    mkdir -p "$rofi_config_dir"

    force_symlink "$dotfiles_dir/rofi/config.rasi" "$rofi_config_dir/config.rasi"
    force_symlink "$dotfiles_dir/rofi/squared-everforest.rasi" "$rofi_config_dir/squared-everforest.rasi"

    log_info "Symlinked rofi config files into $rofi_config_dir"
}

# Function to configure waybar
configure_waybar() {
    local dotfiles_dir
    local waybar_config_dir
    dotfiles_dir=$(pwd)
    waybar_config_dir="$HOME/.config/waybar"

    mkdir -p "$waybar_config_dir"

    force_symlink "$dotfiles_dir/waybar/config.jsonc" "$waybar_config_dir/config.jsonc"
    force_symlink "$dotfiles_dir/waybar/style.css" "$waybar_config_dir/style.css"
    force_symlink "$dotfiles_dir/waybar/power_menu.xml" "$waybar_config_dir/power_menu.xml"

    log_info "Symlinked waybar config files into $waybar_config_dir"
}

# Function to configure niri
configure_niri() {
    local dotfiles_dir
    local niri_config_dir
    dotfiles_dir=$(pwd)
    niri_config_dir="$HOME/.config/niri"

    if [ ! -d "$niri_config_dir" ]; then
        mkdir -p "$niri_config_dir"
        log_info "Created $niri_config_dir"
    fi

    # Backup existing config if it exists
    if [ -f "$niri_config_dir/config.kdl" ]; then
        local backup_file="$niri_config_dir/config.kdl.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$niri_config_dir/config.kdl" "$backup_file"
        log_info "Backed up existing niri config to $backup_file"
    fi

    # Symlink config
    ln -sf "$dotfiles_dir/niri/config.kdl" "$niri_config_dir/config.kdl"
    log_info "Symlinked niri config.kdl from $dotfiles_dir/niri/config.kdl"
}

# Function to setup niri startup scripts
setup_niri_startup() {
    local dotfiles_dir
    dotfiles_dir=$(pwd)

    if [ -f "$dotfiles_dir/niri/install.sh" ]; then
        log_info "Setting up niri startup scripts..."
        bash "$dotfiles_dir/niri/install.sh"
    else
        log_warn "niri/install.sh not found, skipping startup setup"
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

    # Install and configure waybar and niri
    install_waybar "$pm"
    configure_waybar

    install_rofi "$pm"
    configure_rofi

    install_niri "$pm"
    if command -v niri >/dev/null 2>&1; then
        configure_niri
        setup_niri_startup
    else
        log_warn "niri is not available yet. Please install it manually if you want the compositor setup."
    fi

    log_info "Installation complete!"
    log_info "Run 'source ~/.zshrc' or restart your terminal to apply changes."
    log_info "You may need to install a Nerd Font for proper icon display in the terminal."
    if command -v waybar >/dev/null 2>&1; then
        log_info "To start waybar, use your compositor or run: waybar"
    fi
    if command -v rofi >/dev/null 2>&1; then
        log_info "To launch rofi, use: rofi -show drun"
    fi
    if command -v niri >/dev/null 2>&1; then
        log_info "To start niri, run: niri"
    fi
}

# Run main function
main "$@"