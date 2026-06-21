
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

  print -P "%F{#A277FF} $branch%f$indicators"
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
