ARG FEDORA_MAJOR_VERSION=40
FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION}

# copy yum repos
ADD /repos /etc/yum.repos.d/

# install pacakges
RUN rpm-ostree install --idempotent \
    # tools \
        htop \
        vim-common \
        ncdu \
        unrar \
        unzip \
        p7zip \
        procps \
        akmods \
        bcc \
        strace \
        nmap \
        smartmontools \
        wireguard-tools \
        android-tools \
        python3-pip \
    # bench \
        stress-ng \
        s-tui \
    # gui \
        NetworkManager-l2tp \
        NetworkManager-l2tp-gnome \
        gnome-tweak-tool \
        ulauncher \
        gnome-shell-extension-pop-shell \
        simple-scan \
    # fs \
        fscrypt \
        davfs2 \
        sirikali \
    # networking \
        tailscale \
    # system \
        usbguard \
        usbguard-dbus \
        powertop \
    # virt / containers \
        incus \
        edk2-ovmf \
        edk2-aarch64 \
        qemu-img \
        qemu-kvm \
        podman \
        podman-compose \
        containernetworking-plugins \
    # cypto \
        pcsc-tools \
        libykneomgr \
        pam_yubico \
        nyx \
        tor \
    # password manager \
        1password \
        1password-cli \
        pass \
        qtpass \
    # dev \
        code \
    # ml \
        rocm-clinfo rocminfo rocm-smi

# sync rootfs
ADD /rootfs /

# add scripts
ADD /scripts /tmp/scripts


RUN rm -rf /tmp/* /var/* &&
    rpm-ostree cleanup -m &&
    ostree container commit
