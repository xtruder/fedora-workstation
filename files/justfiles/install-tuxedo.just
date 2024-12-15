# Install and configure Tuxedo software
install-tuxedo:
    sudo rpm-ostree install --idempotent tuxedo-control-center akmod-tuxedo-drivers
    sudo mkdir -p /etc/xdg/autostart
    sudo ln -fs /usr/etc/skel/.config/autostart/tuxedo-control-center-tray.desktop \
        /etc/xdg/autostart/tuxedo-control-center-tray.desktop
