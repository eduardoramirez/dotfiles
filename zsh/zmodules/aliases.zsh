# Always use color output for `ls`

export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
alias ls='command ls -G'
alias lls='ls -lF -G'

alias grep='grep --color=auto'

# Utilities
alias reload="exec ${SHELL} -l"

# One-word wonders

alias b=bat
alias c=cat
alias g=git
alias v=vim

alias l=exa
alias ll='exa -l'

alias bj='bat -l json'
alias by='bat -l yaml'

alias cc=clear

# Git aliases

alias ga='git add'
alias gaa='git add --all'
alias gau='git add --update'
alias gap='git add --patch'

alias gc='git commit'
alias gca='git commit -a'
alias gcA='git commit --amend'
alias gcm='git commit -m'
alias gcam='git commit -am'

alias gco='git checkout'
alias gcp='git cherry-pick'

alias gd='git diff'
alias gds='git diff --staged'

alias gl="git log --pretty='format:%C(yellow)%h %C(green)%ad %Creset%s%Cblue  [%an]' --decorate --date=relative"

alias gp='git pull --rebase --no-tags'

alias gcr='git rebase -i --autosquash'
alias gcrm='gcr master'
alias gra='git rebase --abort'
alias grc='git add --update && git rebase --continue'

alias gs='git status'

alias gS='git stash'
alias gSp='git stash pop'
alias gSs='git stash show'

alias gre='git reset'
alias greh='git reset HEAD'
alias gre1='git reset HEAD~'

alias gu='git push'
alias guu='git push -u'
