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

