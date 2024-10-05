#!/usr/bin/bash -xe

rpm-ostree install tuxedo-control-center tuxedo-drivers

# add tuxedo control center to autostart
mkdir -p /etc/xdg/autostart
ln -s /usr/etc/skel/.config/autostart/tuxedo-control-center-tray.desktop \
    /etc/xdg/autostart/tuxedo-control-center-tray.desktop

# disables power-profiles-daemon
systemctl disable power-profiles-daemon.service
