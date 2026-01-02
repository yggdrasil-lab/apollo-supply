# Apollo Supply

This repository initializes the "Download and VPN" layer of the Apollo media stack. It manages VPN connectivity and media acquisition services, designed to integrate with the Apollo Core swarm.

## Stack Overview

-   **Gluetun**: VPN client acting as a gateway for other services. Attached to the external `aether-net` overlay network.
-   **qBittorrent**: Torrent client, routed through Gluetun.
-   **SABnzbd**: Usenet client, routed through Gluetun.

## Networking

This stack is deployed as a **standalone Docker Compose** project (not Swarm mode) to support `network_mode: service:gluetun`.

-   **External Network**: `aether-net` (must exist in Swarm).
-   **VPN Routing**: Services use the Gluetun container's network stack.

## VPN Setup (AirVPN + WireGuard)

This stack is optimized for **AirVPN** using **WireGuard**. Follow these steps to configure your secrets:

1.  **Generate Config**:
    *   Log in to the [AirVPN Client Area](https://airvpn.org/client/).
    *   Go to **Config Generator**.
    *   Select **Linux** -> **WireGuard**.
    *   Choose your desired server location.
    *   Generate and download the configuration file (`.conf`).

2.  **Extract Secrets**:
    Open the `.conf` file and find the following values:
    *   `[Interface] PrivateKey` -> `WIREGUARD_PRIVATE_KEY`
    *   `[Interface] Address` (e.g., `10.128.0.2/32`) -> `WIREGUARD_ADDRESSES`
        > **Important:** If your config includes both IPv4 and IPv6 addresses (e.g., `10.x.x.x/32,fd7d:x:x:x:x/128`), **only use the IPv4 address**. Including the IPv6 address will cause startup errors if the host network does not support IPv6.
    *   `[Peer] PresharedKey` -> `WIREGUARD_PRESHARED_KEY`

3.  **Configure GitHub Secrets**:
    Add the following secrets to your repository:
    *   `VPN_SERVICE_PROVIDER`: `airvpn`
    *   `VPN_TYPE`: `wireguard`
    *   `WIREGUARD_PRIVATE_KEY`: *(Your Private Key)*
    *   `WIREGUARD_PRESHARED_KEY`: *(Your Preshared Key)*
    *   `WIREGUARD_ADDRESSES`: *(Your Address CIDR)*

## Deployment

The stack is deployed via GitHub Actions on a self-hosted runner (`muspelheim`).

### Environment Variables

The following environment variables are passed to the container (handled via GitHub Secrets):

-   `VPN_SERVICE_PROVIDER`
-   `VPN_USER`
-   `VPN_PASSWORD`
-   `WIREGUARD_PRIVATE_KEY` (if using WireGuard)
-   `WIREGUARD_ADDRESSES` (if using WireGuard)

### Manual Deployment

```bash
./start.sh
```

Ensure environment variables are set if running manually without the repository secrets.
