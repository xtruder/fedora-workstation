#!/usr/bin/env bash

set -euo pipefail

readonly gid_onepassword=1500
readonly gid_onepassword_cli=1600
readonly browser_support_path=/opt/1Password/1Password-BrowserSupport

mkdir -p /var/opt
install -m0644 "${CONFIG_DIRECTORY}/rpm-ostree/1password.repo" /etc/yum.repos.d/1password.repo
rpm --import https://downloads.1password.com/linux/keys/1password.asc
rpm-ostree install 1password 1password-cli
rm -f /etc/yum.repos.d/1password.repo

chmod 4755 /opt/1Password/chrome-sandbox
install -Dm0644 \
  /opt/1Password/resources/com.onepassword.OnePassword.desktop \
  /usr/share/applications/com.onepassword.OnePassword.desktop
cp -a /opt/1Password/resources/icons/. /usr/share/icons/
gtk-update-icon-cache -f -t /usr/share/icons/hicolor/

# Fixed GIDs preserve helper ownership when the image is deployed.
chgrp "${gid_onepassword}" "${browser_support_path}"
chmod g+s "${browser_support_path}"
chgrp "${gid_onepassword_cli}" /usr/bin/op
chmod g+s /usr/bin/op

printf 'g onepassword %s\n' "${gid_onepassword}" > /usr/lib/sysusers.d/onepassword.conf
printf 'g onepassword-cli %s\n' "${gid_onepassword_cli}" > /usr/lib/sysusers.d/onepassword-cli.conf
rm -f \
  /usr/lib/sysusers.d/30-rpmostree-pkg-group-onepassword.conf \
  /usr/lib/sysusers.d/30-rpmostree-pkg-group-onepassword-cli.conf
