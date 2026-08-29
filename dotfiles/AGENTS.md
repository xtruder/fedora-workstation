# Dotfiles guidance

- Declare shared Homebrew formulae in `Brewfile`, not one-off `brew install`
  scripts. `Brewfile` is source-only; keep it in `.chezmoiignore.tmpl` and keep
  its checksum embedded in `run_onchange_install-brew-packages.sh.tmpl`.
- `hermes = true` installs the Agent/API profile. `hermes_web = true` is a
  superset that also installs WebUI and its Traefik route.
- Keep `hermes-webui.service` and `traefik.service` disabled by default. Users
  enable them manually after configuration; only the Hermes API unit is linked
  into a target by chezmoi.
- Keep Traefik's Cloudflare token in `~/.config/traefik/traefik.env`; do not
  couple Traefik to `~/.config/hermes/services.env`.
- Keep the Hermes WebUI hostname based on the `base_domain` chezmoi value rather
  than hardcoding a deployment domain.
