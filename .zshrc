# Zsh configuration

# ==============================================================================
# INIT
# ==============================================================================
eval "$(zoxide init zsh)"
setopt interactivecomments

if [[ -f "$HOME/dotfiles/zsh/alias.sh" ]]; then
  source "$HOME/dotfiles/zsh/alias.sh"
fi


if [[ -f "$HOME/dotfiles/zsh/func.sh" ]]; then
  source "$HOME/dotfiles/zsh/func.sh"
fi

if [[ -f "$HOME/dotfiles/zsh/prompt.zsh" ]]; then
  source "$HOME/dotfiles/zsh/prompt.zsh"
fi


if [[ -f "$HOME/dotfiles/zsh/plugins.zsh" ]]; then
  source "$HOME/dotfiles/zsh/plugins.zsh"
fi


# ==============================================================================
# ENVIRONMENT
# ==============================================================================
export PATH="$HOME/.cargo/bin:$PATH"
export TERM=xterm
export TERMINFO="$HOME/.pixi/envs/default/share/terminfo"

# ==============================================================================
# EDITOR
# ==============================================================================
export EDITOR=nvim
export VISUAL=nvim

# ==============================================================================
# PATHS
# ==============================================================================
export PATH="$HOME/.pixi/bin:$PATH"

# ==============================================================================
# LOCAL EXTRAS
# ==============================================================================
if [[ -f "$HOME/dotfiles/cmd.sh" ]]; then
  source "$HOME/dotfiles/cmd.sh"
fi

if [[ -f "$HOME/dotfiles/HS202rc" ]]; then
  source "$HOME/dotfiles/HS202rc"
fi


. "$HOME/.local/bin/env"
