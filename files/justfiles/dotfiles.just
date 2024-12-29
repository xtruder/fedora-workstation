dotfiles:
    chezmoi init --apply https://github.com/xtruder/fedora-workstation --branch main --prompt
    cd ~/.local/share/chezmoi && git remote set-url origin --push git@github.com:xtruder/fedora-workstation.git
