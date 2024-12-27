# fedora-workstation

## Install on laptop with Fedora 41 Silverblue installed

```sh
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/xtruder/fedora-workstation:41
sudo systemctl reboot
sudo rpm-ostree rebase ostree-image-signed:ghcr.io/xtruder/fedora-workstation:41
```
