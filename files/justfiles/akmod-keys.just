# Set variables

fedora_version := `rpm -E %fedora`
akmods_keys_version := "0.0.2-8"
akmods_keys_path := "silverblue-akmods-keys"
akmods_keys_rpm := akmods_keys_path + "/akmods-keys-" + akmods_keys_version + ".fc" + fedora_version + ".noarch.rpm"

# Check if akmods-keys is installed

akmods_keys_installed := `rpm -q akmods-keys >/dev/null 2>&1 && echo "true" || echo "false"`

# Build and install akmods-keys package
akmods-keys: build-akmods-keys
    #!/usr/bin/env bash
    if ! rpm -q akmods-keys >/dev/null; then
        sudo rpm-ostree install {{ akmods_keys_rpm }}
    fi
    rm -f {{ akmods_keys_rpm }}

# Build akmods-keys package
build-akmods-keys:
    cd "{{ akmods_keys_path }}" && sudo bash setup.sh
