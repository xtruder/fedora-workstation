# This stage is responsible for holding onto
# your config without copying it directly into
# the final image
FROM scratch AS stage-files
COPY ./files /files

# Copy modules
# The default modules are inside blue-build/modules
# Custom modules overwrite defaults
FROM scratch AS stage-modules
COPY --from=ghcr.io/blue-build/modules:latest /modules /modules
# Bins to install
# These are basic tools that are added to all images.
# Generally used for the build process. We use a multi
# stage process so that adding the bins into the image
# can be added to the ostree commits.
FROM scratch AS stage-bins
COPY --from=gcr.io/projectsigstore/cosign /ko-app/cosign /bins/cosign
COPY --from=ghcr.io/blue-build/cli:latest-installer /out/bluebuild /bins/bluebuild

# Keys for pre-verified images
# Used to copy the keys into the final image
# and perform an ostree commit.
#
# Currently only holds the current image's
# public key.
FROM scratch AS stage-keys
# Stage for AKmod main
FROM scratch as stage-akmods-main
COPY --from=ghcr.io/ublue-os/akmods:main-41 /rpms /rpms
COPY --from=ghcr.io/ublue-os/akmods-extra:main-41 /rpms /rpms

# Main image
FROM ghcr.io/ublue-os/silverblue-main@sha256:eb5dc471819a791bcdec7013df32a035181911a566f5de3b250fcdbe3ffe637f AS fedora-workstation
ARG RECIPE=./recipes/recipe.yml
ARG IMAGE_REGISTRY=localhost
ARG CONFIG_DIRECTORY="/tmp/files"
ARG MODULE_DIRECTORY="/tmp/modules"
ARG IMAGE_NAME="fedora-workstation"
ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
ARG FORCE_COLOR=1
ARG CLICOLOR_FORCE=1
ARG RUST_LOG_STYLE=always
# Key RUN
RUN --mount=type=bind,from=stage-keys,src=/keys,dst=/tmp/keys \
  mkdir -p /etc/pki/containers/ \
  mkdir -p /usr/etc/pki/containers/ \
  && cp /tmp/keys/* /etc/pki/containers/ \
  && cp /tmp/keys/* /usr/etc/pki/containers/ \
  && ostree container commit

# Bin RUN
RUN --mount=type=bind,from=stage-bins,src=/bins,dst=/tmp/bins \
  mkdir -p /usr/bin/ \
  && cp /tmp/bins/* /usr/bin/ \
  && ostree container commit

RUN --mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/scripts/ \
  /scripts/pre_build.sh

# Module RUNs
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'files' '{"type":"files","files":[{"source":"system","destination":"/"}]}' \
  && ostree container commit
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'rpm-ostree' '{"type":"rpm-ostree","repos":["tuxedo.repo","microsoft-vscode.repo","ganto-lxc4-incus.repo","tuxedo.repo","tuxedo-drivers-kmod.repo"],"install":["htop","vim-common","ncdu","unrar","unzip","p7zip","procps","akmods","bcc","strace","nmap","smartmontools","wireguard-tools","android-tools","python3-pip","make","gnupg2","stress-ng","s-tui","NetworkManager-l2tp","NetworkManager-l2tp-gnome","gnome-tweak-tool","ulauncher","gnome-shell-extension-pop-shell","simple-scan","fscrypt","davfs2","sirikali","tailscale","usbguard","usbguard-dbus","powertop","incus","edk2-ovmf","edk2-aarch64","qemu-img","qemu-kvm","podman","podman-compose","containernetworking-plugins","pcsc-tools","libykneomgr","pam_yubico","nyx","tor","python3-devel","python3-tkinter","libusb1-devel","libudev-devel","gcc","pass","qtpass","code","rocminfo","rocm-smi"],"remove":["firefox","firefox-langpacks"]}' \
  && ostree container commit
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'bling' '{"type":"bling","install":["1password","dconf-update-service"]}' \
  && ostree container commit
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'default-flatpaks' '{"type":"default-flatpaks","notify":true,"system":{"install":["org.mozilla.firefox","org.gnome.Loupe"],"remove":["org.gnome.eog"]},"user":{}}' \
  && ostree container commit
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'systemd' '{"type":"systemd","system":{"disabled":["flatpak-system-update.timer"],"enabled":["usbguard.service","usbguard-dbus.service","incus.socket"]}}' \
  && ostree container commit
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=stage-akmods-main,src=/rpms,dst=/tmp/rpms,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'akmods' '{"type":"akmods","base":"main","install":[]}' \
  && ostree container commit
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'justfiles' '{"type":"justfiles","validate":true,"include":["akmod-keys.just","install-tuxedo.just"]}' \
  && ostree container commit
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/tmp/scripts/ \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-fedora-workstation-41,sharing=locked \
  --mount=type=cache,dst=/var/cache/libdnf5,id=dnf-cache-fedora-workstation-41,sharing=locked \
  /tmp/scripts/run_module.sh 'signing' '{"type":"signing"}' \
  && ostree container commit

RUN --mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:v0.9.0,src=/scripts/,dst=/scripts/ \
  /scripts/post_build.sh

# Labels are added last since they cause cache misses with buildah
LABEL org.blue-build.build-id="1b899541-a201-4777-b04a-0f2fc01d945c"
LABEL org.opencontainers.image.title="fedora-workstation"
LABEL org.opencontainers.image.description="This is my personal OS image."
LABEL org.opencontainers.image.source=""
LABEL org.opencontainers.image.base.digest="sha256:eb5dc471819a791bcdec7013df32a035181911a566f5de3b250fcdbe3ffe637f"
LABEL org.opencontainers.image.base.name="ghcr.io/ublue-os/silverblue-main:41"
LABEL org.opencontainers.image.created="2024-12-15T04:11:59.239656981+00:00"
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/blue-build/cli/main/README.md