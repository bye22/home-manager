# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.


if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ================================
# 基础配置
# ================================
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export EDITOR='vim'
unsetopt PROMPT_CR
# ================================
# 历史记录配置
# ================================
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_VERIFY

# ================================
# 自动补全和补全缓存
# ================================
autoload -Uz compinit
compinit -C
zstyle ':completion:*' rehash true
zstyle ':completion:*' menu select

# ================================
# 插件管理：使用 Zinit
# ================================
export ZINIT_HOME=$HOME/.zinit
source $ZINIT_HOME/zinit.zsh

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-syntax-highlighting
zinit light romkatv/powerlevel10k

# ================================
# 自定义命令别名与函数
# ================================
alias e='exit'
alias r='ranger --cmd="ls -a"'
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias cls='clear'
alias gs='git status'
alias gl='git log'
alias gd='git diff'
alias ga='git add '
alias gr='git rm -rf --cached '
alias gl='git ls-files --cached '
alias gco='git checkout'
alias docs='cd ~/Documents'
alias proj='cd ~/Projects'

function ..() { cd .. }
function cd..() { cd .. }

function gitrepos() {
  find . -name ".git" -type d -exec dirname {} \;
}

# ================================
# 终端提示符配置
# ================================
autoload -U colors && colors
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time)
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(user dir vcs)

PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '

# ================================
# 启动时的异步操作与插件管理
# ================================
#zinit delay 10  # 延迟加载插件

# ================================
# 快捷键绑定与高效输入
# ================================
bindkey "^I" complete-word
bindkey '^R' history-incremental-search-backward

# ================================
# 其他配置
# ================================
alias mkdir='mkdir -p'
export PROMPT_COMMAND="echo -n 'Current directory: '; pwd"


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# [ -f "/home/bye22/.ghcup/env" ] && . "/home/bye22/.ghcup/env" # ghcup-env
