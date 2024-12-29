# fedora-workstation

## ISO

```sh
sudo bluebuild generate-iso --iso-name fedoraw-workstation.iso image ghcr.io/xtruder/fedora-workstation:41
```

## Install on laptop with Fedora 41 Silverblue installed

```sh
sudo rpm-ostree rebase --reboot ostree-unverified-registry:ghcr.io/xtruder/fedora-workstation:41
sudo rpm-ostree rebase --reboot ostree-image-signed:docker://ghcr.io/xtruder/fedora-workstation:41
```

## Dotfiles

```sh
ujust dotfiles
```

This will run `chezmoi init`, which will clone dotfiles to `~/.local/share/chezmoi` and run
initial apply.

To update dotfiles after you can run:

```sh
chezmoi update
```
