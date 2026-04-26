# Zsh configuration

# ==============================================================================
# INIT
# ==============================================================================
eval "$(zoxide init zsh)"
setopt interactivecomments

# ==============================================================================
# ENVIRONMENT
# ==============================================================================
export PATH="$HOME/.cargo/bin:$PATH"
export TERM=xterm
export TERMINFO="$HOME/.pixi/envs/default/share/terminfo"

# ==============================================================================
# ALIASES
# ==============================================================================
alias cat="bat"
alias wr="pkill waybar || true; waybar -c $HOME/dotfiles/waybar/config.jsonc -s $HOME/dotfiles/waybar/style.css & disown"
alias zu="SSH_CONNECTION=\"1 2 3 4\""
alias zuc="unset SSH_CONNECTION "
alias zz="source ~/.zshrc"
alias nglook="nwg-look"

alias ls="eza --colour=always --icons=always --group-directories-first"
alias ll="eza -lh --colour=always --icons=always"
alias la="eza -lha --colour=always --icons=always"
alias lg="eza -la --git --git-repos --icons=always --colour=always"
alias gtree="eza --tree --git-ignore --colour=always --icons=always --sort=extension"
alias tree="eza --tree --colour=always --icons=always"

alias clr="clear"
alias c="clear"
alias code.="code ."

# Quick git shortcuts via "gir"
alias g="git"
alias gst="git status -sb"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit -m"
alias gca="git commit --amend"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpl="git pull --rebase"
alias gb="git branch"
alias gco="git checkout"
alias girsw="git switch"
alias girl="git log --oneline --graph --decorate -20"

# ==============================================================================
# FUNCTIONS
# ==============================================================================
mkcd() {
  mkdir -p "$1" && cd "$1"
}

kural() {
  if [[ -z "$1" ]]; then
    echo "Usage: kural <number>"
    return 1
  fi

  if command -v pixi >/dev/null 2>&1; then
    if pixi run python "$HOME/dotfiles/thirukkural/kural_cli.py" "$@"; then
      return 0
    fi

    echo "pixi run failed, using system python3..."
  fi

  python3 "$HOME/dotfiles/thirukkural/kural_cli.py" "$@"
}

pxa() {
  export _OLD_PIXI_PATH="$PATH"
  eval "$(pixi shell-hook)"echo $XDG_DATA_DIRS

~
❯ 
}

pxd() {
  # Backup original PATH if not already saved.
  if [[ -n "$_OLD_PIXI_PATH" ]]; then
    export PATH="$_OLD_PIXI_PATH"
    unset _OLD_PIXI_PATH
  else
    PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '\.pixi' | paste -sd ':' -)
  fi

  unset PIXI_ENVIRONMENT_NAME PIXI_PROJECT_NAME CONDA_PREFIX
  hash -r
}

zdev() {
  export ZGIT=1
  export ZPY=1
}

zclean() {
  unset ZGIT
  unset ZPY
}

mkagent() {
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
}

# ==============================================================================
# PROMPT
# ==============================================================================
autoload -U colors && colors
autoload -Uz add-zsh-hook
setopt PROMPT_SUBST

ssh_prompt() {
  [[ -n "$SSH_CONNECTION" ]] || return
  print -P "%F{blue}%n@%m%f"
}

git_prompt() {
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local ahead=0
  local behind=0
  local staged=0
  local dirty=0

  read behind ahead <<< $(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
  staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty=1

  local indicators=""
  (( ahead > 0 )) && indicators+=" %F{blue}⇡$ahead%f"
  (( behind > 0 )) && indicators+=" %F{cyan}⇣$behind%f"
  (( staged > 0 )) && indicators+=" %F{green}±$staged%f"
  (( dirty > 0 )) && indicators+=" %F{yellow}✗%f"

  print -P "%F{magenta} $branch%f$indicators"
}

python_prompt() {
  if [[ -n "$PIXI_PROJECT_NAME" || -n "$PIXI_ENVIRONMENT_NAME" ]]; then
    local proj="${PIXI_PROJECT_NAME:-pixi}"
    local env="${PIXI_ENVIRONMENT_NAME:-default}"
    print -P "%F{green}${proj}:${env}%f"
    return
  fi

  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_name="${VIRTUAL_ENV:t}"
    print -P "%F{green}🐍 ${venv_name}%f"
    return
  fi
}

timer_preexec() {
  CMD_START=$SECONDS
}

cmd_timer() {
  CMD_TIMER_TEXT=""
  (( CMD_START )) || return
  local elapsed=$((SECONDS - CMD_START))
  CMD_START=0
  (( elapsed > 2 )) && CMD_TIMER_TEXT="%F{blue}took ${elapsed}s%f"
}

build_prompt() {
  local last_status=$?
  local sshpart=""
  local gitpart=""
  local pypart=""
  local timer=""

  sshpart=$(ssh_prompt)

  [[ -n "$ZGIT" ]] && gitpart=" $(git_prompt)"
  [[ -n "$ZPY" ]] && pypart=" $(python_prompt)"

  cmd_timer
  timer="$CMD_TIMER_TEXT"

  local charcolor="%F{green}"
  [[ $last_status -ne 0 ]] && charcolor="%F{red}"

  PROMPT=""
  [[ -n "$timer" ]] && PROMPT+="$timer"$'\n'
  [[ -n "$sshpart" ]] && PROMPT+="$sshpart"$'\n'
  PROMPT+="%F{cyan}%~%f$gitpart$pypart"$'\n'"${charcolor}❯%f "
}

timer_precmd() {
  build_prompt
}

add-zsh-hook -D preexec timer_preexec >/dev/null 2>&1 || true
add-zsh-hook -D precmd timer_precmd >/dev/null 2>&1 || true
add-zsh-hook preexec timer_preexec
add-zsh-hook precmd timer_precmd
true
build_prompt

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
ZSH_AUTOSUGGES66T_HIGHLIGHT_STYLE='fg=#99999'  # Dark grey with hex code
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
