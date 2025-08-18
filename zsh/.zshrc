
# Zsh configuration
export LC_ALL=en_US.UTF-8

# Only run interactive stuff in interactive shells
[[ $- != *i* ]] && return

# ---- Completions (needed before autosuggestions) ----
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"
autoload -Uz compinit
compinit -d "$ZSH_CACHE_DIR/zcompdump"

# ====================== zoxide · fzf · fzf-tab · starship ======================
# XDG paths + PATH
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$BIN_DIR" "$DATA_DIR" "$CFG_DIR"
export PATH="$BIN_DIR:$PATH"

_has() { command -v "$1" >/dev/null 2>&1; }
_install_pkg() {
  if _has apt-get; then sudo apt-get update && sudo apt-get install -y "$@" || return 1
  elif _has dnf; then sudo dnf install -y "$@" || return 1
  elif _has pacman; then sudo pacman -Sy --noconfirm "$@" || return 1
  elif _has brew; then brew install "$@" || return 1
  else return 1
  fi
}

# ---- zoxide ----
if ! _has zoxide; then
  echo "[setup] Installing zoxide..."
  _install_pkg zoxide || {
    if _has cargo; then cargo install zoxide --locked
    else
      curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$BIN_DIR"
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
    [[ -x "$FZF_DIR/bin/fzf" ]] && ln -sf "$FZF_DIR/bin/fzf" "$BIN_DIR/fzf"
  fi
fi

# fzf defaults (fast source with fd/rg fallback)
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

# fzf keybindings & completion (system paths or git clone)
for base in /usr/share/doc/fzf /usr/share/fzf /usr/local/opt/fzf "$DATA_DIR/fzf"; do
  [[ -r "$base/shell/key-bindings.zsh" ]] && source "$base/shell/key-bindings.zsh"
  [[ -r "$base/shell/completion.zsh"   ]] && source "$base/shell/completion.zsh"
done

# ---- fzf-tab (fzf-powered completion UI) ----
PLUGINDIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
mkdir -p "$PLUGINDIR"
if [[ ! -d "$PLUGINDIR/fzf-tab" ]]; then
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$PLUGINDIR/fzf-tab" >/dev/null 2>&1
fi
source "$PLUGINDIR/fzf-tab/fzf-tab.plugin.zsh"
# optional preview for files in completion menus
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -f $realpath ]] && head -n 200 -- $realpath'

# ---- starship ----
if ! _has starship && [[ ! -x "$BIN_DIR/starship" ]]; then
  echo "[setup] Installing starship..."
  # apt may not have starship on some arches (e.g., Ubuntu aarch64) – fall back cleanly
  if ! _install_pkg starship; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN_DIR"
  fi
fi
eval "$(starship init zsh)"

# --- Starship + vi-mode: safe zle-keymap-select wrapper (no recursion) ---
if [[ -z ${__STARSHIP_ZLE_WRAP_DONE-} ]]; then
  __STARSHIP_ZLE_WRAP_DONE=1
  # Save whatever zle-keymap-select currently is (Starship's widget)
  if zle -l | grep -q '^zle-keymap-select$'; then
    zle -A zle-keymap-select _starship_orig_zle_keymap_select
  fi

  function zle-keymap-select {
    case $KEYMAP in
      vicmd)      RPROMPT="[N]"  ;;
      main|viins) RPROMPT="[I]"  ;;
      *)          RPROMPT=""     ;;
    esac
    [[ -n ${widgets[_starship_orig_zle_keymap_select]} ]] && \
      zle _starship_orig_zle_keymap_select -- "$@"
  }
  zle -N zle-keymap-select
fi

# ==================== end tools block ====================

# Custom aliases
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias nv='nvim'

alias g='g'
alias ga='git add'
alias gA='git add -A'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gcm='git commit -m'
alias gpsh='git push'
alias gpll='git pull'
alias gl='git log --oneline --graph --decorate --all'

alias ls='eza --icons --group-directories-first --color=always'
alias l='eza --icons --group-directories-first --color=always'
alias la='eza --icons --group-directories-first --color=always -a'
alias ll='eza --icons --group-directories-first --color=always -l'
alias lla='eza --icons --group-directories-first --color=always -la'
alias lt='eza --icons --group-directories-first --color=always --tree'

bindkey -v
# --- vi yank -> system clipboard via OSC52 (works over SSH/tmux) ---
_clip() {
  # If inside tmux, use passthrough so the outer terminal receives OSC52
  if [[ -n "$TMUX" ]]; then
    printf '\ePtmux;\e\e]52;c;%s\a\e\\' "$(printf %s "$1" | base64 | tr -d '\n')"
  else
    printf '\e]52;c;%s\a' "$(printf %s "$1" | base64 | tr -d '\n')"
  fi
}

vi_yank_and_clip() { zle vi-yank; _clip "$CUTBUFFER"; }
zle -N vi_yank_and_clip
bindkey -M vicmd 'y'  vi_yank_and_clip
bindkey -M vicmd 'Y'  vi_yank_and_clip
bindkey -M vicmd 'yy' vi_yank_and_clip


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

