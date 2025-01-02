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

## Post install

- Login to 1password
- Setup firefox (most of changes with auto sync on existing account)
  - Create firefox profiles
  - Login with firefox accounts
  - Configure basics
  - Install extensions:
    - [multi-account-containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/)
    - darkreader
    - ublock origin
    - 1password
    - window titler
    - ClearURLs
    - Link to text Fragment
  - Enable auto switching on dark reader
  - Create containers Work/Personal
  - Login to websites (in Persona/Work profiles and associated containers): Mail, Youtube, Youtube music
- Setup nextcloud sync
