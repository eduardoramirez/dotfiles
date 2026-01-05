# FZF Configuration
# Supports both Intel (/usr/local) and Apple Silicon (/opt/homebrew)

_fzf_base=""
if [[ -d "/opt/homebrew/opt/fzf" ]]; then
    _fzf_base="/opt/homebrew/opt/fzf"
elif [[ -d "/usr/local/opt/fzf" ]]; then
    _fzf_base="/usr/local/opt/fzf"
fi

if [[ -n "$_fzf_base" ]]; then
    # Auto-completion
    [[ $- == *i* ]] && source "${_fzf_base}/shell/completion.zsh" 2> /dev/null

    # Key bindings
    source "${_fzf_base}/shell/key-bindings.zsh"
fi

# FZF Options
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Use fd for FZF if available (faster than find)
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

unset _fzf_base
