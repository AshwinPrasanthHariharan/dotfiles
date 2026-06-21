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

# ==============================================================================
# ENVIRONMENT
# ==============================================================================
export PATH="$HOME/.cargo/bin:$PATH"
export TERM=xterm
export TERMINFO="$HOME/.pixi/envs/default/share/terminfo"


# ==============================================================================
# EDITOR
# ==============================================================================
export EDITOR=micro
export VISUAL=micro

# ==============================================================================
# PATHS
# ==============================================================================
export PATH="$HOME/.pixi/bin:$PATH"



# ==============================================================================
# COMPLETION + PLUGINS
# ==============================================================================
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autosuggestion configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#777777'  # Suggestion color set to #777777
bindkey '^ ' autosuggest-accept              # Ctrl+Space to accept suggestion



ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#A277FF'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'



# ==============================================================================
# LOCAL EXTRAS
# ==============================================================================
if [[ -f "$HOME/dotfiles/cmd.sh" ]]; then
  source "$HOME/dotfiles/cmd.sh"
fi

if [[ -f "$HOME/dotfiles/HS202rc" ]]; then
  source "$HOME/dotfiles/HS202rc"
fi

export PATH="/home/ashwin/.pixi/bin:$PATH"

. "$HOME/.local/bin/env"
