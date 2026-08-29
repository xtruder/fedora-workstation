# Dotfiles guidance

- Declare shared Homebrew formulae in `Brewfile`, not one-off `brew install`
  scripts. `Brewfile` is source-only; keep it in `.chezmoiignore.tmpl` and keep
  its checksum embedded in `run_onchange_install-brew-packages.sh.tmpl`.
- Homebrew's GCC formula provides version-suffixed compiler commands on Linux
  (`gcc-<major>` and `g++-<major>`). Use `CC` and `CXX` when a build expects
  unversioned compiler names; do not layer `gcc-c++` solely for Hermes builds.
- `hermes = true` installs the Agent/API profile. `hermes_web = true` is a
  superset that also installs WebUI and its Traefik route.
- The Hermes browser must be a visible Google Chrome Flatpak launched by GNOME
  autostart with a dedicated CDP profile. Keep `BROWSER_CDP_URL` pointed at its
  loopback endpoint so Hermes does not launch a headless browser; do not replace
  this with the Weston-specific service used on headless servers.
- Keep `hermes-webui.service` and `traefik.service` disabled by default. Users
  enable them manually after configuration; only the Hermes API unit is linked
  into a target by chezmoi.
- Keep Traefik's Cloudflare token in `~/.config/traefik/traefik.env`; do not
  couple Traefik to `~/.config/hermes/services.env`.
- Keep the Hermes WebUI hostname based on the `base_domain` chezmoi value rather
  than hardcoding a deployment domain.
- Cua Driver has no Homebrew formula or official tap. Keep using the pinned,
  checksum-verified upstream installer unless upstream publishes one.
