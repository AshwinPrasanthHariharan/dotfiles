# Dotfiles

This repository contains my personal dotfiles configuration, primarily focused on a customized Zsh setup with useful aliases, functions, and a feature-rich prompt.

## Features

- **Zsh Configuration**: Custom prompt with Git status, Python environment, SSH indicator, and command timing
- **Aliases**: Enhanced commands using modern tools (bat for cat, eza for ls, etc.)
- **Navigation**: zoxide for intelligent directory jumping
- **Productivity**: Convenience functions and aliases for common tasks

## Installation

### Prerequisites

- Bash (for running the install script)
- Internet connection (for downloading dependencies)

### Automatic Installation

Run the installation script:

```bash
./install.sh
```

This script will:
- Detect your package manager (apt, dnf, pacman, or brew)
- Install required dependencies (zsh, git, curl, Rust, zoxide, bat, eza)
- Backup your existing `.zshrc` (if any)
- Symlink the new `.zshrc` to your home directory
- Change your default shell to zsh (requires password)

### Manual Installation

If the automatic script fails:

1. Install zsh and make it your default shell:
   ```bash
   # Ubuntu/Debian
   sudo apt install zsh
   chsh -s $(which zsh)

   # Fedora
   sudo dnf install zsh
   chsh -s $(which zsh)

   # Arch Linux
   sudo pacman -S zsh
   chsh -s $(which zsh)

   # macOS
   brew install zsh
   chsh -s $(which zsh)
   ```

2. Install Rust (if not already installed):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source ~/.cargo/env
   ```

3. Install required tools:
   ```bash
   cargo install zoxide bat eza
   ```

4. Backup your existing `.zshrc` and symlink the new one:
   ```bash
   [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup
   ln -s $(pwd)/.zshrc ~/.zshrc
   ```

5. Restart your terminal or run `exec zsh`

## Post-Installation

- **Fonts**: For proper icon display, install a Nerd Font (e.g., FiraCode Nerd Font)
- **VS Code**: The `code.` alias requires VS Code to be installed with `code` in PATH
- **Pixi**: Python environment detection works with Pixi (https://pixi.sh/)

## Customization

### Prompt Components

The prompt includes several components that can be toggled:

- **Git Status**: Shows branch name, ahead/behind commits, staged changes, and dirty status
- **Python Environment**: Displays active virtualenv or Pixi environment
- **SSH Indicator**: Shows user@host when connected via SSH
- **Command Timer**: Displays execution time for commands > 2 seconds

### Environment Variables

- `ZGIT`: Set to enable Git prompt (default: enabled if in Git repo)
- `ZPY`: Set to enable Python prompt (default: enabled if in virtualenv/Pixi)

## Included Tools

- **zoxide**: Smart directory navigation
- **bat**: Cat with syntax highlighting
- **eza**: Modern ls replacement with icons
- **pixi**: Fast Python package and environment manager
- **fzf**: Fuzzy finder for command-line
- **ripgrep**: Fast text search tool
- **fd**: Simple, fast and user-friendly alternative to find
- **Git**: Version control with enhanced prompt integration

## Troubleshooting

- If icons don't display properly, install a Nerd Font
- If tools aren't found, ensure they're in your PATH
- Check the backed-up `.zshrc` if you need to restore previous settings

## License

This configuration is provided as-is. Feel free to use and modify for your own setup.