# Directory navigation helpers.
#
# `j` is supplied by autojump; it learns directories as you visit them.
# `pd` is the short form from the previous Fish configuration and moves to the
# preceding entry in Fish's directory history. `...` and longer forms go up
# multiple parent directories.

if test -f "$HOME/.autojump/share/autojump/autojump.fish"
    source "$HOME/.autojump/share/autojump/autojump.fish"
end

alias pd prevd
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'
