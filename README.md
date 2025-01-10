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
- Setup nextcloud sync

### Setup firefox

Note: most of changes with auto sync on existing account

- Create firefox profiles
- Login with firefox accounts
- Configure basics
  - Reopen windows/tabs on restart
  - Set desktop theme (auto switch)
  - Enable HTTPS only
  - Enable hardware accelerated playback using `media.ffmpeg.vaapi.enabled` (also sync via `services.sync.prefs.sync-seen.media.ffmpeg.vaapi.enabled`)
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

### Setup incus dev container

Add yourself to `incus-admin` group and restart your session.

```sh
grep -E '^incus-admin:' /usr/etc/group | sudo tee -a /etc/group
sudo usermod -a -G incus-admin offlinehq
newgrp incus-admin
```

Setup subid/subgid mappings

```sh
sudo usermod --add-subuids 524288-65536 offlinehq
sudo usermod --add-subuids 1000000-1000000000 root

sudo usermod --add-subgids 524288-65536 offlinehq
sudo usermod --add-subgids 1000000-1000000000 root
```

Create incus dev container

```sh
incus create images:ubuntu/24.04/cloud --profile ubuntu-dev ubuntu-dev
incus start ubuntu-dev
```

Add code directory to container

```sh
incus config device add ubuntu-dev code disk source=/var/home/offlinehq/Code path=/home/offlinehq/Code shift=true
```

Add SSH key to container

```sh
incus file push ~/.ssh/id_ed25519.pub ubuntu-dev/home/offlinehq/.ssh/authorized_keys --create-dirs --mode 0600
```

Add to SSH config

```sh
# Add/update SSH config entry
IP=$(incus list ubuntu-dev -f json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet").address')
cat >> ~/.ssh/config << EOF
Host ubuntu-dev
    HostName $IP
    ForwardAgent yes
    RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra
EOF
```

Login to container

```sh
# Via exec
incus exec ubuntu-dev -- bash

# Or via SSH (after adding SSH key)
ssh ubuntu-dev
```

Test
