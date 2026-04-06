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
# Add Term
export TERM=xterm
export TERMINFO="$HOME/.pixi/envs/default/share/terminfo"
# ==============================================================================
# ALIASES
# ==============================================================================

# Enhanced cat command using bat for syntax highlighting
alias cat="bat"

alias ff="fastfetch"

alias zu="SSH_CONNECTION=\"1 2 3 4\""
alias zuc="unset SSH_CONNECTION "
alias zz="source ~/.zshrc"
# Improved ls commands using eza with icons and directory grouping
alias ls="eza --colour=always --icons=always --group-directories-first"
alias ll="eza -lh --colour=always --icons=always"
alias la="eza -lha --colour=always --icons=always"
alias lg="eza -la --git --git-repos --icons=always --colour=always"
# tree for git cache only
alias gtree="eza --tree --git-ignore --colour=always --icons=always --sort=extension"
alias tree="eza --tree --colour=always --icons=always"
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
    eval "$(pixi shell-hook)"
}

pxd() {
    exec "$SHELL"
}


# ==============================================================================
# PROMPT CONFIGURATION
# ==============================================================================

# Enable colors and prompt substitution
autoload -U colors && colors
setopt PROMPT_SUBST
# ...existing code...

cmd2pdf() {
  emulate -L zsh
  setopt pipefail

  if [[ -z "$1" ]]; then
    echo "Usage: cmd2pdf '<command>' [output.pdf]"
    return 1
  fi

  local cmd="$1"
  local out="${2:-output.pdf}"
  local tmp_html
  local python_cmd
  local nerd_font_file
  local renderer=()
  tmp_html="$(mktemp /tmp/cmd2pdf.XXXXXX.html)"

  python_cmd="$(command -v python3)"
  if [[ -z "$python_cmd" ]]; then
    rm -f "$tmp_html"
    echo "cmd2pdf: python3 is required" >&2
    return 1
  fi

  if ! command -v aha >/dev/null 2>&1; then
    rm -f "$tmp_html"
    echo "cmd2pdf: aha is required" >&2
    return 1
  fi

  nerd_font_file="$(fc-match -f '%{file}\n' 'JetBrainsMono Nerd Font Mono' 2>/dev/null | head -n 1)"
  if [[ -z "$nerd_font_file" ]]; then
    nerd_font_file="$(fc-match -f '%{file}\n' 'JetBrainsMono Nerd Font' 2>/dev/null | head -n 1)"
  fi

  if ! TERM=xterm-256color COLORTERM=truecolor CLICOLOR_FORCE=1 FORCE_COLOR=3 \
    "$python_cmd" -c 'import os, pty, subprocess, sys
master_fd, slave_fd = pty.openpty()
proc = subprocess.Popen(
    ["zsh", "-ic", sys.argv[1]],
    stdin=slave_fd,
    stdout=slave_fd,
    stderr=slave_fd,
    env=os.environ,
)
os.close(slave_fd)
try:
    while True:
        try:
            chunk = os.read(master_fd, 4096)
        except OSError:
            break
        if not chunk:
            break
        sys.stdout.buffer.write(chunk)
        sys.stdout.buffer.flush()
finally:
    os.close(master_fd)

raise SystemExit(proc.wait())' "$cmd" \
    | aha --black --title "cmd2pdf" > "$tmp_html"; then
    rm -f "$tmp_html"
    echo "cmd2pdf: failed to capture command output" >&2
    return 1
  fi

  if ! "$python_cmd" - "$tmp_html" "$nerd_font_file" <<'PY'
from pathlib import Path
import sys

html_file = Path(sys.argv[1])
font_file = Path(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else None
html = html_file.read_text(encoding="utf-8")

font_face = ""
if font_file and font_file.exists():
    font_face = f"""
@font-face {{
  font-family: "Cmd2PdfNerdFont";
  src: url("{font_file.as_uri()}") format("truetype");
}}
"""

css = """
<meta charset="UTF-8">
<style>
{font_face}
body, pre {{
  background: #1e1e2e !important;
  color: #cdd6f4 !important;
  font-size: 15px;
  line-height: 1.45;
  padding: 20px;
  white-space: pre-wrap;
  word-break: break-word;
}}

pre, code, span {{
  font-family:
    "Cmd2PdfNerdFont",
    "JetBrainsMono Nerd Font Mono",
    "JetBrainsMono Nerd Font",
    "JetBrainsMono NFM",
    "JetBrainsMono NF",
    "Noto Sans Symbols 2",
    "Noto Sans Symbols",
    "JetBrains Mono",
    monospace !important;
  }}
</style>
""".format(font_face=font_face)

html = html.replace("<head>", f"<head>{css}", 1)
html_file.write_text(html, encoding="utf-8")
PY
  then
    rm -f "$tmp_html"
    echo "cmd2pdf: failed to prepare HTML" >&2
    return 1
  fi

  if command -v chromium >/dev/null 2>&1; then
    renderer=(chromium --headless --disable-gpu --allow-file-access-from-files "--print-to-pdf=$out" "file://$tmp_html")
  elif command -v google-chrome >/dev/null 2>&1; then
    renderer=(google-chrome --headless --disable-gpu --allow-file-access-from-files "--print-to-pdf=$out" "file://$tmp_html")
  elif command -v wkhtmltopdf >/dev/null 2>&1; then
    renderer=(wkhtmltopdf --enable-local-file-access --encoding utf-8 "$tmp_html" "$out")
  else
    rm -f "$tmp_html"
    echo "cmd2pdf: install chromium, google-chrome, or wkhtmltopdf" >&2
    return 1
  fi

  if ! "${renderer[@]}" >/dev/null 2>&1; then
    rm -f "$tmp_html"
    rm -f "$out"
    echo "cmd2pdf: PDF rendering failed" >&2
    return 1
  fi

  if [[ ! -s "$out" ]]; then
    rm -f "$tmp_html"
    rm -f "$out"
    echo "cmd2pdf: PDF was not created" >&2
    return 1
  fi

  rm -f "$tmp_html"
  echo "📄 Saved to $out"
}

cmd2md() {
  emulate -L zsh
  setopt pipefail

  if [[ -z "$1" ]]; then
    echo "Usage: cmd2md '<command>' [output.md]"
    return 1
  fi

  local cmd="$1"
  local out="${2:-output.md}"
  local tmp_txt
  local tmp_html
  local python_cmd
  local nerd_font_file
  tmp_txt="$(mktemp /tmp/cmd2md.XXXXXX.txt)"
  tmp_html="$(mktemp /tmp/cmd2md.XXXXXX.html)"

  python_cmd="$(command -v python3)"
  if [[ -z "$python_cmd" ]]; then
    rm -f "$tmp_txt"
    rm -f "$tmp_html"
    echo "cmd2md: python3 is required" >&2
    return 1
  fi

  if ! command -v aha >/dev/null 2>&1; then
    rm -f "$tmp_txt"
    rm -f "$tmp_html"
    echo "cmd2md: aha is required" >&2
    return 1
  fi

  nerd_font_file="$(fc-match -f '%{file}\n' 'JetBrainsMono Nerd Font Mono' 2>/dev/null | head -n 1)"
  if [[ -z "$nerd_font_file" ]]; then
    nerd_font_file="$(fc-match -f '%{file}\n' 'JetBrainsMono Nerd Font' 2>/dev/null | head -n 1)"
  fi

  if ! TERM=xterm-256color COLORTERM=truecolor CLICOLOR_FORCE=1 FORCE_COLOR=3 \
    "$python_cmd" -c 'import os, pty, subprocess, sys
master_fd, slave_fd = pty.openpty()
proc = subprocess.Popen(
    ["zsh", "-ic", sys.argv[1]],
    stdin=slave_fd,
    stdout=slave_fd,
    stderr=slave_fd,
    env=os.environ,
)
os.close(slave_fd)
try:
    while True:
        try:
            chunk = os.read(master_fd, 4096)
        except OSError:
            break
        if not chunk:
            break
        sys.stdout.buffer.write(chunk)
        sys.stdout.buffer.flush()
finally:
    os.close(master_fd)

raise SystemExit(proc.wait())' "$cmd" > "$tmp_txt"; then
    rm -f "$tmp_txt"
    rm -f "$tmp_html"
    echo "cmd2md: failed to capture command output" >&2
    return 1
  fi

  if ! aha --black --word-wrap --no-header --ignore-cr < "$tmp_txt" > "$tmp_html"; then
    rm -f "$tmp_txt"
    rm -f "$tmp_html"
    echo "cmd2md: failed to convert output to HTML" >&2
    return 1
  fi

  if ! "$python_cmd" - "$cmd" "$tmp_txt" "$tmp_html" "$out" "$nerd_font_file" <<'PY'
from pathlib import Path
import html
import re
import sys

command = sys.argv[1]
captured_file = Path(sys.argv[2])
html_file = Path(sys.argv[3])
output_file = Path(sys.argv[4])
font_file = Path(sys.argv[5]) if len(sys.argv) > 5 and sys.argv[5] else None
text = captured_file.read_text(encoding="utf-8", errors="replace")
text = text.replace("\r\n", "\n").replace("\r", "\n")
plain_text = re.sub(r"\x1b(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])", "", text)
plain_text = "".join(ch for ch in plain_text if ch == "\n" or ch == "\t" or ord(ch) >= 32)
plain_text = plain_text.rstrip("\n")

html_fragment = html_file.read_text(encoding="utf-8")

font_face = ""
if font_file and font_file.exists():
    font_face = f"""
@font-face {{
  font-family: "Cmd2MdNerdFont";
  src: url("{font_file.as_uri()}") format("truetype");
}}
"""

style_block = """
<!-- FONT: paste this once per page, inside a <head> or at the top of your MD -->
<style>
{font_face}
.cmd2md-output, .cmd2md-output pre, .cmd2md-output code, .cmd2md-output span {{
  font-family:
    "Cmd2MdNerdFont",
    "JetBrainsMono Nerd Font Mono",
    "JetBrainsMono Nerd Font",
    "JetBrainsMono NFM",
    "JetBrainsMono NF",
    "Noto Sans Symbols 2",
    "Noto Sans Symbols",
    "JetBrains Mono",
    monospace !important;
}}

.cmd2md-output pre {{
  background: #1e1e2e !important;
  color: #cdd6f4 !important;
  padding: 16px;
  border-radius: 8px;
  overflow-x: auto;
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 15px;
  line-height: 1.45;
}}
</style>
""".format(font_face=font_face)

markdown = (
    "# Command Output\n\n"
    f"Command: `{command}`\n\n"
    "<!-- STYLE BLOCK: copy the <style>...</style> block below for font/colour support -->\n"
    f"{style_block}"
    "<!-- OUTPUT BLOCK: copy the <div>...</div> block below to embed the terminal output -->\n"
    "<div class=\"cmd2md-output\">"
    f"<pre>\n{html_fragment}</pre>"
    "</div>\n"
)

output_file.write_text(markdown, encoding="utf-8")
PY
  then
    rm -f "$tmp_txt"
    rm -f "$tmp_html"
    rm -f "$out"
    echo "cmd2md: failed to prepare markdown" >&2
    return 1
  fi

  if [[ ! -s "$out" ]]; then
    rm -f "$tmp_txt"
    rm -f "$tmp_html"
    rm -f "$out"
    echo "cmd2md: Markdown was not created" >&2
    return 1
  fi

  rm -f "$tmp_txt"
  rm -f "$tmp_html"
  echo "📝 Saved to $out"
}

# ...existing code...
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
mkagent() {
    eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
}
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
source ~/HS202_repo/.HS202rc
