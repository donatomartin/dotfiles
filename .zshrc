
# Zsh configuration
export LC_ALL=en_US.UTF-8
export ZSH=/home/$USER/.oh-my-zsh
ZSH_THEME=robbyrussell
plugins=(git sudo zsh-syntax-highlighting zsh-autosuggestions)
source /home/$USER/.oh-my-zsh/oh-my-zsh.sh

# Only attach if not already inside tmux
if [[ -z "$TMUX" ]]; then
    tmux attach-session -t def || tmux new-session -s def
fi

# NVM initialization
source /usr/share/nvm/init-nvm.sh

# Conda initialization
__conda_setup="$('/home/donato/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/donato/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/donato/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/donato/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# Zoxide initialization
eval "$(zoxide init zsh)"

# Custom aliases
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
