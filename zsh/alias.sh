
# ==============================================================================
# ALIASES
# ==============================================================================
alias src="source"
alias cat="bat"
alias wr="pkill waybar > /dev/null 2>&1 || true; waybar -c $HOME/dotfiles/waybar/config.jsonc -s $HOME/dotfiles/waybar/style.css > /dev/null 2>&1 & disown"
alias zu="SSH_CONNECTION=\"1 2 3 4\""
alias zuc="unset SSH_CONNECTION "
alias zz="source ~/.zshrc"
alias nglook="nwg-look"
alias zcode='code $(zoxide query)'
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
alias gisw="git switch"
alias girl="git log --oneline --graph --decorate -20"
