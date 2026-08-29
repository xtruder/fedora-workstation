# Hermes optional profile

The profile has two options in the local chezmoi config:

- `hermes = true` installs the Agent API, Cua Driver, and API user service.
- `hermes_web = true` installs that complete Hermes profile plus the WebUI,
  Traefik configuration, and disabled WebUI and Traefik user services.

When enabling `hermes_web`, also set `base_domain = "x-truder.net"`. The WebUI
hostname is `web.hermes.<base_domain>`.

The Agent API unit is enabled for either profile and reads
`~/.config/hermes/services.env`. Create that file with the Agent API and
dashboard values before starting a graphical session, then restrict its
permissions:

```bash
chmod 600 ~/.config/hermes/services.env
```

The WebUI unit is installed but not enabled by chezmoi and does not load the
Hermes environment file. It starts without password authentication by default;
configure a password through the WebUI when desired. Enable the unit manually
when ready:

```bash
systemctl --user enable --now hermes-webui.service
```

The profile downloads the installer from the stable official endpoint,
`https://hermes-agent.nousresearch.com/install.sh`, while `--commit` keeps the
Agent version pinned. Do not use the former repository-root `install.sh` raw
URL: upstream moved that file and the old URL returns 404. After updating the
dotfile source, rerun `chezmoi apply`; the `run_onchange` template retries when
its content changes. Cua Driver has no Homebrew formula or official tap, so the
profile uses its pinned, checksum-verified upstream installer.

Create one item named `Hermes` in the `Private` vault with these fields:

- `API_SERVER_KEY`
- `DASHBOARD_USERNAME`
- `DASHBOARD_PASSWORD`
- `DASHBOARD_SECRET`
- `CF_DNS_API_TOKEN`

The services listen only on `127.0.0.1:8642` and `127.0.0.1:8787`. Traefik
itself is installed unconditionally with Homebrew. With `hermes_web = true`,
chezmoi deploys a default HTTPS route from `web.hermes.<base_domain>` to the
WebUI and installs `traefik.service` without enabling it.

Create Traefik's environment file before manually enabling the service:

```bash
cp ~/.config/traefik/traefik.env.example ~/.config/traefik/traefik.env
chmod 600 ~/.config/traefik/traefik.env
# Set CF_DNS_API_TOKEN in ~/.config/traefik/traefik.env.
systemctl --user enable --now traefik.service
```

The service is installed but not enabled by chezmoi. It uses that separate file
only for the Cloudflare DNS-01 challenge and does not read Hermes'
`services.env`. The Traefik files in this directory remain a reference for also
exposing the Hermes gateway.

Nextcloud synchronization uses the Nextcloud Desktop Flatpak installed by the
`work` profile. The earlier `nextcloudcmd` timer design is intentionally not
carried forward.
