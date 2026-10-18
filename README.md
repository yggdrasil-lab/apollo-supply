# Apollo Supply

VPN-routed download layer for the Apollo media stack. Companion to apollo-core — handles the secure acquisition pipeline. Deployed as standalone Docker Compose (not Swarm — requires `network_mode: service:gluetun`).

## Services

| Service | Container | Port | Purpose |
|:---|:---|:---|:---|
| Gluetun | `gluetun` | gateway | VPN client (AirVPN/WireGuard). All download traffic routes through it |
| qBittorrent | `qbittorrent` | 8080 | Torrent client, routed through Gluetun |
| SABnzbd | `sabnzbd` | 8085 | Usenet client, routed through Gluetun |
| slskd | `slskd` | 5030 | Soulseek client, routed through Gluetun |

## Documentation

Full stack documentation lives in the vault: `Areas/90-Infrastructure/Apollo/Apollo Stack.md`

Includes VPN setup steps, port forwarding, troubleshooting (Gluetun connection loops, metadata stalls, SABnzbd hostname verification), systemd persistence, and the historical timeline of the supply layer.

## Host Provisioning

Host directories (`/opt/apollo-supply/*`, `/mnt/storage/downloads/slskd/*`), the boot persistence service (`apollo-supply.service`), and the graceful restart tool (`muspelheim-restart-docker.sh`) are centrally managed by [yggdrasil-os](https://github.com/yggdrasil-lab/yggdrasil-os):

```bash
curl -fsSL https://raw.githubusercontent.com/yggdrasil-lab/yggdrasil-os/main/hosts/setup_muspelheim.sh | sudo bash
```

## Deploy

```bash
./start.sh
```

Triggered automatically via GitHub Actions on push to `main` with VPN credentials and environment variables injected from GitHub Secrets. Deploys directly on Muspelheim using standalone Docker Compose, installs `config/slskd.yml` onto the host, and verifies Gluetun VPN health before reporting success.


### Inbound ports

Two ports must be forwarded to this account in the AirVPN client area, and both must be present in the environment:

| Variable | Purpose |
|:---|:---|
| `FIREWALL_VPN_INPUT_PORTS` | qBittorrent's forwarded port (comma-separated if more than one) |
| `SLSKD_LISTEN_PORT` | slskd's peer port. Compose appends it to `FIREWALL_VPN_INPUT_PORTS` and passes it to slskd as `SLSKD_SLSK_LISTEN_PORT`, so the firewall rule cannot drift from the port slskd actually listens on |

AirVPN forwards a given port number to **one account only** — it is opened on every server, so a port another customer already holds is refused with `The requested port is not available`. slskd's own default of 50300 is usually gone for that reason. Reserve any free port >= 2048 (5 per account) and leave AirVPN's "Local" field empty: slskd announces its listen port to the Soulseek network and has no separate public-port setting, so a remap would point peers at a port AirVPN never forwards.

### slskd configuration

slskd's configuration lives in `config/slskd.yml`. `start.sh` installs it at `/opt/apollo-supply/slskd/slskd.yml` on every deploy, which the container reads as `/app/slskd.yml` through the mount it already has; edit the repository file, because the host copy is overwritten each deploy. It exists because slskd only maps an environment variable to an option it explicitly attributes: an option without that attribute has no `SLSKD_*` equivalent and can only be set in the file. Where both exist, the YAML wins — configuration is layered defaults, then environment, then YAML, then command line, and the last layer wins.

Completed downloads keep the peer's folder structure, minus the peer's username: `transfers.download.destination.subdirectory` is `${SOURCE_PATH}`. The default, `${SOURCE_DIRECTORY}`, keeps only the file's immediate parent folder. Downloads started from Browse ignore this — the web UI sends its own destination for those. slskd does not classify content, so music, audiobooks and books are not separated automatically and are moved into the media libraries by hand.

## Related

- `apollo-core` — media servers + content management (companion stack)
- `Areas/90-Infrastructure/Apollo/` — detailed reference docs
