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

## Connecting to Prowlarr / Arr Stack

Since `qBittorrent` and `SABnzbd` are routed through the `gluetun` container, they share its IP address. When configuring download clients in Prowlarr, Sonarr, or Radarr (running in the `apollo-core` stack), use the following details:

*   **Hostname**: `gluetun` (Addressable via the `aether-net` overlay network)
*   **qBittorrent Port**: `8080`
*   **SABnzbd Port**: `8081`

### qBittorrent Default Password

On the first start, qBittorrent generates a temporary password printed in the container logs.

1.  **View Logs**:
    ```bash
    docker logs qbittorrent
    ```
    Look for a line containing `The temporary password is:`.

2.  **Change Password**:
    *   Log in to the Web UI at `http://<your-server-ip>:8080` using `admin` and the temporary password.
    *   Go to **Tools** -> **Options** -> **Web UI**.
    *   Under **Authentication**, change the username and password to your preference.
    *   (Optional) Disable CSRF protection if you encounter API issues with Prowlarr.

### SABnzbd Configuration

SABnzbd usually starts without a password by default, but follows a setup wizard on first access.

1.  **Access Wizard**:
    *   Go to `http://<your-server-ip>:8081`.
    *   Follow the **Quick Start Wizard**.

2.  **API Key**:
    *   Once configured, go to **Config** (gear icon) -> **General**.
    *   Copy the **API Key**. You will need this to connect Prowlarr, Sonarr, and Radarr.

3.  **Security (Optional but Recommended)**:
    *   In **Config** -> **General** -> **Security**, you can set a username and password if desired.

    *   Go to **Tools** -> **Options** -> **Web UI**.
    *   Under **Authentication**, change the username and password to your preference.
    *   (Optional) Disable CSRF protection if you encounter API issues with Prowlarr.
