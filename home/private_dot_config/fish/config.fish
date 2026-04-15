source /usr/share/cachyos-fish-config/cachyos-config.fish

# Secrets loaded from ~/.config/fish/conf.d/secrets.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
fnm env --use-on-cd --shell fish | source
zoxide init fish | source

# Abbreviations
abbr --add vim -- nvim
