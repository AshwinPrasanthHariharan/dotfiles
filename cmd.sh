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
    "Noto Sans Tamil",
    "Noto Serif Tamil",
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
    "Noto Sans Tamil",
    "Noto Serif Tamil",
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

unalias ff 2>/dev/null

function ff {
  emulate -L zsh

  case "$1" in
    -l|--long)
      shift
      fastfetch --config "$HOME/dotfiles/fastfetch/config-long.jsonc" "$@"
      ;;
    *)
      fastfetch --config "$HOME/dotfiles/fastfetch/config-short.jsonc" "$@"
      ;;
  esac
}
