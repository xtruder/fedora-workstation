# Variables
image_name := ghcr.io/offlinehacker/fedora-workstation:latest
bin_dir := $(HOME)/.local/bin
fedora_version := $(shell rpm -E %fedora)

akmods_keys_version := 0.0.2-8
akmods_keys_path := silverblue-akmods-keys
akmods_keys_rpm := $(akmods_keys_path)/akmods-keys-$(akmods_keys_version).fc$(fedora_version).noarch.rpm
akmods_keys_installed := $(shell rpm -q akmods-keys >/dev/null 2>&1 && echo "true" || echo "false")
akmods_keys_built := $(shell [ -f "$(akmods_keys_path)/$(akmods_keys_rpm)" ] && echo "true" || echo "false")

cmd_chezmoi:= $(bin_dir)/chezmoi

ifeq (, $(shell echo "$$PATH" | tr ':' '\n' | grep  "$(HOME)/.local/bin"))
$(error "No ~/.local/bin in $$PATH, please export PATH="$$HOME/.local/bin:$$PATH"")
endif

# Default target
.PHONY: all
all:
	@echo "Available targets:"
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/  /'

## build-image: Build the Docker image
.PHONY: build-image
build-image:
	podman build -t $(image_name) .

## chezmoi-install: Install Chezmoi if not already installed
$(cmd_chezmoi): $(bin_dir)
	sh -c "$$(curl -fsLS get.chezmoi.io)" -- -b $(bin_dir)

## chezmoi-init: Initialize chezmoi config
.PHONY: chezmoi-init
chezmoi-init: $(cmd_chezmoi)
	$(cmd_chezmoi) init --apply --verbose "--source=$(shell pwd)/dotfiles"

## install-tuxedo: Install and configure Tuxedo software
.PHONY: install-tuxedo
install-tuxedo:
	sudo rpm-ostree install --idempotent tuxedo-control-center tuxedo-drivers
	sudo mkdir -p /etc/xdg/autostart
	sudo ln -fs /usr/etc/skel/.config/autostart/tuxedo-control-center-tray.desktop \
		/etc/xdg/autostart/tuxedo-control-center-tray.desktop
	sudo systemctl mask power-profiles-daemon.service

## build-akmods-keys: Build akmods-keys package
$(akmods_keys_rpm):
	cd "$(akmods_keys_path)" && sudo bash setup.sh

## akmods-keys: Build and install akmods-keys package
.PHONY: akmods-keys
akmods-keys: $(akmods_keys_rpm)
	rpm -q akmods-keys >/dev/null || \
		sudo rpm-ostree install $(akmods_keys_rpm)
	-rm -f $(akmods_keys_rpm)

# Helper targets
$(bin_dir):
	mkdir -p $(bin_dir)
