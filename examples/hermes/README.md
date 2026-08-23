# Hermes optional profile

Set `hermes = true` in the local chezmoi config only after signing in to the
1Password desktop app and enabling CLI integration. Applying chezmoi then
installs the pinned Hermes compatibility set, reads `op://Private/Hermes`,
configures shared-session GNOME RDP, and starts the loopback-only API and WebUI
user services.

Create one item named `Hermes` in the `Private` vault with these fields:

- `API_SERVER_KEY`
- `WEBUI_PASSWORD`
- `DASHBOARD_USERNAME`
- `DASHBOARD_PASSWORD`
- `DASHBOARD_SECRET`
- `RDP_USERNAME`
- `RDP_PASSWORD`
- `CF_API_EMAIL` (reserved for the manual Traefik example)
- `CF_DNS_API_TOKEN` (reserved for the manual Traefik example)

Refresh secrets or RDP credentials later with:

```shell
~/.local/bin/configure-hermes
```

The services listen only on `127.0.0.1:8642` and `127.0.0.1:8787`. Public
exposure is intentionally not part of the profile. The Traefik files in this
directory are reference configuration for a later manual setup; chezmoi does
not install or enable them.

Nextcloud synchronization uses the Nextcloud Desktop Flatpak installed by the
profile. The earlier `nextcloudcmd` timer design is intentionally not carried
forward.
