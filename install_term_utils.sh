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
            sudo pacman -Syu --noconfirm zsh git curl wget rustup base-devel

            # Install Rust if not present
            if ! command -v cargo >/dev/null 2>&1; then
                rustup install stable
                rustup default stable
            fi

            # Install tools
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

