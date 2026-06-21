
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
  eval "$(pixi shell-hook)"
  echo $XDG_DATA_DIRS
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

git-to-ssh() {
    local current_url
    current_url=$(git remote get-url origin 2>/dev/null)

    if [ -z "$current_url" ]; then
        echo "Error: Not a git repository or no 'origin' remote found."
        return 1
    fi

    # Check if it's already an SSH URL
    if [[ "$current_url" == git@* ]]; then
        echo "Remote 'origin' is already using SSH: $current_url"
        return 0
    fi

    # Universal string manipulation (Works in Zsh and Bash)
    if [[ "$current_url" == https://* ]]; then
        # Strip the 'https://' prefix
        local temp="${current_url#https://}"
        
        # Grab everything before the first slash (github.com)
        local domain="${temp%%/*}"
        
        # Grab everything after the first slash (User/Repo.git)
        local path="${temp#*/}"
        
        local new_url="git@${domain}:${path}"

        # Apply the new URL
        git remote set-url origin "$new_url"
        echo "Successfully swapped origin to SSH!"
        echo "Old: $current_url"
        echo "New: $new_url"
    else
        echo "Error: Could not parse HTTPS URL format ($current_url)."
        return 1
    fi
}
