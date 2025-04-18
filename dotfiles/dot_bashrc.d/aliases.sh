alias mpv='flatpak run io.mpv.Mpv'

alias butane='podman run --rm --interactive         \
              --security-opt label=disable          \
              --volume "${PWD}:/pwd" --workdir /pwd \
              quay.io/coreos/butane:release'
