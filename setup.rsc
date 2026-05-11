# setup.rsc - MikroTik Tailscale Setup for SD Card (disk1)
# 
# This script automates the creation of the container environment.
# It assumes you have uploaded tailscale.tar to disk1/tailscale.tar

:local containerName "tailscale"
:local vethInterface "veth-tailscale"
:local bridgeName "br-tailscale"
:local containerAddress "172.17.0.2/24"
:local gatewayAddress "172.17.0.1"
:local diskPath "disk1"
:local authKey "tskey-auth-xxxxxxxxxxxx"
:local lanSubnet "192.168.88.0/24"

# MCP Server Settings
:local enableMcp "true"
:local mcpUser "admin"
:local mcpPassword ""

# 1. Enable container mode (requires physical access and reboot if not already enabled)
/system/device-mode/update container=yes

# 2. Create VETH
/interface/veth add name=$vethInterface address=$containerAddress gateway=$gatewayAddress

# 3. Create Bridge and add VETH
/interface/bridge add name=$bridgeName
/ip/address add address=($gatewayAddress . "/24") interface=$bridgeName
/interface/bridge/port add bridge=$bridgeName interface=$vethInterface

# 4. Configure NAT
/ip/firewall/nat add chain=srcnat action=masquerade src-address="172.17.0.0/24" comment="NAT for Tailscale container"

# 5. Add static route for Tailscale network
/ip/route add dst-address=100.64.0.0/10 gateway=$containerAddress comment="Route to Tailscale network"

# 6. Enable API Service (required for MCP)
/ip/service set api disabled=no port=8728

# 7. Set Environment Variables
/container/envs
add name=tailscale_envs key="AUTH_KEY" value=$authKey
add name=tailscale_envs key="ADVERTISE_ROUTES" value=$lanSubnet
add name=tailscale_envs key="CONTAINER_GATEWAY" value=$gatewayAddress
add name=tailscale_envs key="PASSWORD" value="tailscale123"
add name=tailscale_envs key="ENABLE_MCP" value=$enableMcp
add name=tailscale_envs key="MCP_USER" value=$mcpUser
add name=tailscale_envs key="MCP_PASSWORD" value=$mcpPassword

# 8. Define Mounts (using SD card)
/container/mounts
add name="tailscale_config" src=($diskPath . "/tailscale/config") dst="/var/lib/tailscale"

# 9. Create and Start Container
/container add \
    file=($diskPath . "/tailscale.tar") \
    interface=$vethInterface \
    envlist=tailscale_envs \
    root-dir=($diskPath . "/containers/tailscale") \
    mounts=tailscale_config \
    start-on-boot=yes \
    hostname=$containerName \
    logging=yes \
    cmd="/usr/local/bin/tailscale.sh"

:put "Setup complete. Please verify the container status with '/container/print'"
