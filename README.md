# Apollo Supply

VPN-routed download layer for the Apollo media stack. Companion to apollo-core — handles the secure acquisition pipeline. Deployed as standalone Docker Compose (not Swarm — requires `network_mode: service:gluetun`).

## Services

| Service | Container | Port | Purpose |
|:---|:---|:---|:---|
| Gluetun | `gluetun` | gateway | VPN client (AirVPN/WireGuard). All download traffic routes through it |
| qBittorrent | `qbittorrent` | 8080 | Torrent client, routed through Gluetun |
| SABnzbd | `sabnzbd` | 8085 | Usenet client, routed through Gluetun |

## Documentation

Full stack documentation lives in the vault: `Areas/90-Infrastructure/Apollo/Apollo Stack.md`

Includes VPN setup steps, port forwarding, troubleshooting (Gluetun connection loops, metadata stalls, SABnzbd hostname verification), systemd persistence, and the historical timeline of the supply layer.

## Deploy

```bash
./start.sh
```

Requires: muspelheim host, `aether-net` overlay network, VPN secrets in environment/GitHub Secrets, systemd service for boot persistence.

## Related

- `apollo-core` — media servers + content management (companion stack)
- `Areas/90-Infrastructure/Apollo/` — detailed reference docs
