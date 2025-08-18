
# Zsh configuration
export LC_ALL=en_US.UTF-8

# Only run interactive stuff in interactive shells
[[ $- != *i* ]] && return

# ---- Completions (needed before autosuggestions) ----
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"
autoload -Uz compinit
compinit -d "$ZSH_CACHE_DIR/zcompdump"

# ====================== Tools: zoxide, fzf, starship ======================
# XDG-friendly bins
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$BIN_DIR" "$DATA_DIR" "$CFG_DIR"

_has() { command -v "$1" >/dev/null 2>&1; }

_install_pkg() {
  # $1 = package name(s)
  if _has apt-get; then sudo apt-get update && sudo apt-get install -y "$@"
  elif _has dnf;     then sudo dnf install -y "$@"
  elif _has pacman;  then sudo pacman -Sy --noconfirm "$@"
  elif _has brew;    then brew install "$@"
  else return 1
  fi
}

# ---- zoxide ----
if ! _has zoxide; then
  echo "[setup] Installing zoxide..."
  _install_pkg zoxide || {
    if _has cargo; then cargo install zoxide --locked
    else
      curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -s -- --bin-dir "$BIN_DIR"
    fi
  }
fi
eval "$(zoxide init zsh)"

# ---- fzf (core) ----
if ! _has fzf; then
  echo "[setup] Installing fzf..."
  if ! _install_pkg fzf; then
    FZF_DIR="$DATA_DIR/fzf"
    [[ -d "$FZF_DIR" ]] || git clone --depth=1 https://github.com/junegunn/fzf "$FZF_DIR" >/dev/null 2>&1
    # expose fzf binary if provided (Linux packages usually build; git repo has scripts)
    [[ -x "$FZF_DIR/bin/fzf" ]] && ln -sf "$FZF_DIR/bin/fzf" "$BIN_DIR/fzf"
  fi
fi

# fzf defaults & fast file source (fd/rg fallback)
if _has fd; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
elif _has rg; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow -g "!{.git,node_modules,target}"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
else
  export FZF_DEFAULT_COMMAND='find -L . -type f 2>/dev/null'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# fzf keybindings & completion (works for both package and git install)
# Try system paths first, then the git clone
for base in /usr/share/doc/fzf /usr/share/fzf /usr/local/opt/fzf "$DATA_DIR/fzf"; do
  [[ -r "$base/shell/key-bindings.zsh" ]] && source "$base/shell/key-bindings.zsh"
  [[ -r "$base/shell/completion.zsh"   ]] && source "$base/shell/completion.zsh"
done

# ---- fzf integration for Zsh completions (fzf-tab) ----
# Load after compinit, before syntax highlighting
PLUGINDIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
mkdir -p "$PLUGINDIR"
if [[ ! -d "$PLUGINDIR/fzf-tab" ]]; then
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$PLUGINDIR/fzf-tab" >/dev/null 2>&1
fi
source "$PLUGINDIR/fzf-tab/fzf-tab.plugin.zsh"

# Optional: nicer preview for files in completion menus
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -f $realpath ]] && head -n 200 -- $realpath'

# ---- starship prompt ----
if ! _has starship; then
  echo "[setup] Installing starship..."
  if ! _install_pkg starship; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN_DIR"
  fi
fi

# ensure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"
eval "$(starship init zsh)"

# Create a minimal Starship config if you don't have one yet
STAR_CFG="$CFG_DIR/starship.toml"
if [[ ! -f "$STAR_CFG" ]]; then
  cat > "$STAR_CFG" <<'EOF'
# ~/.config/starship.toml
add_newline = false
format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$character"

[character]
success_symbol = "❯"
error_symbol = "❯"
vimcmd_symbol = "❮"

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
symbol = " "
style = "purple"

[cmd_duration]
min_time = 200
show_milliseconds = true
EOF
fi
# ==================== end tools block ====================

# Custom aliases
alias vim='nvim'
alias vi='nvim'
alias v='nvim'

# ---- Lightweight plugin bootstrap (no framework) ----
command -v git >/dev/null || { echo "git not found; skipping plugin setup"; return; }
PLUGINDIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
mkdir -p "$PLUGINDIR"

_zsh_plugin() {
  local repo="$1" dest="$2" file="$3"
  [[ -d "$dest" ]] || git clone --depth=1 "https://github.com/${repo}" "$dest" >/dev/null 2>&1
  source "$dest/$file"
}

# zsh-autosuggestions
# (Load after compinit; set style and a handy accept binding)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'   # subtle grey suggestion
_zsh_plugin "zsh-users/zsh-autosuggestions" \
            "$PLUGINDIR/zsh-autosuggestions" \
            "zsh-autosuggestions.zsh"
bindkey '^f' autosuggest-accept            # Ctrl+F to accept suggestion

# zsh-syntax-highlighting (MUST be last)
_zsh_plugin "zsh-users/zsh-syntax-highlighting" \
            "$PLUGINDIR/zsh-syntax-highlighting" \
            "zsh-syntax-highlighting.zsh"

