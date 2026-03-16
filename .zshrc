# Zsh Configuration File
# This file contains customizations for the Z shell (zsh) environment.

# ==============================================================================
# INITIALIZATION
# ==============================================================================

# Initialize zoxide for intelligent directory navigation
eval "$(zoxide init zsh)"

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# Add Cargo bin directory to PATH for Rust tools
export PATH="$HOME/.cargo/bin:$PATH"

# ==============================================================================
# ALIASES
# ==============================================================================

# Enhanced cat command using bat for syntax highlighting
alias cat="bat"

# Improved ls commands using eza with icons and directory grouping
alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --icons"
alias la="eza -lha --icons"

# Clear screen aliases
alias clr="clear"
alias c="clear"

# Quick open current directory in VS Code
alias code.="code ."

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Convenience function to create a directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ==============================================================================
# PROMPT CONFIGURATION
# ==============================================================================

# Enable colors and prompt substitution
autoload -U colors && colors
setopt PROMPT_SUBST

# SSH prompt function - displays user@host when connected via SSH
ssh_prompt() {
  [[ -n "$SSH_CONNECTION" ]] || return
  print -P "%F{blue}%n@%m%f"
}

# Git prompt function - displays git branch and status indicators
git_prompt() {
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local ahead=0
  local behind=0
  local staged=0
  local dirty=0

  # Calculate ahead/behind commits
  read behind ahead <<< $(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)

  # Count staged changes
  staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  # Check for unstaged changes
  [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty=1

  local indicators=""

  (( ahead > 0 )) && indicators+=" %F{blue}⇡$ahead%f"
  (( behind > 0 )) && indicators+=" %F{cyan}⇣$behind%f"
  (( staged > 0 )) && indicators+=" %F{green}±$staged%f"
  (( dirty > 0 )) && indicators+=" %F{yellow}✗%f"

  print -P "%F{magenta} $branch%f$indicators"
}

# Python/Pixi prompt function - displays Python version or Pixi environment
python_prompt() {
  if [[ -n "$PIXI_ENVIRONMENT_NAME" ]]; then
    print -P "%F{yellow}📦 $PIXI_ENVIRONMENT_NAME%f"
    return
  fi

  [[ -n "$VIRTUAL_ENV" ]] || return

  local pyver=$(python -V 2>&1 | cut -d' ' -f2 | cut -d. -f1,2)

  print -P "%F{yellow}🐍 $pyver%f"
}

# Command timer - tracks execution time for commands taking longer than 2 seconds
preexec() {
  CMD_START=$SECONDS
}

cmd_timer() {
  (( CMD_START )) || return
  local elapsed=$((SECONDS - CMD_START))
  (( elapsed > 2 )) && echo "%F{blue}took ${elapsed}s%f"
}

# Main prompt builder function
build_prompt() {
  local sshpart=""
  local gitpart=""
  local pypart=""
  local timer=""

  sshpart=$(ssh_prompt)

  [[ -n "$ZGIT" ]] && gitpart=" $(git_prompt)"
  [[ -n "$ZPY" ]] && pypart=" $(python_prompt)"

  timer=$(cmd_timer)

  local charcolor="%F{green}"
  [[ $? -ne 0 ]] && charcolor="%F{red}"

  PROMPT=""

  [[ -n "$timer" ]] && PROMPT+="$timer"$'\n'
  [[ -n "$sshpart" ]] && PROMPT+="$sshpart"$'\n'

  PROMPT+="%F{cyan}%~%f$gitpart$pypart"$'\n'"${charcolor}❯%f "
}

# Set the custom prompt
PROMPT='$(build_prompt)'
precmd() {build_prompt}
# ---------- toggles ----------
zdev() {
  export ZGIT=1
  export ZPY=1
}

zclean() {
  unset ZGIT
  unset ZPY
}
#--------changing editor---------
export EDITOR=micro
export VISUAL=micro
#-------SSH Agent----------------

#------------PATHS----------------
export PATH="$HOME/.pixi/bin:$PATH"
#------------keep at end-------------
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#-----------syntax colours----------
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
