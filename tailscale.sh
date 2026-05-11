#!/bin/bash
set -m

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Prepare run dirs
mkdir -p /var/run/sshd
mkdir -p /var/lib/tailscale

# Set root password if provided
if [ -n "${PASSWORD}" ]; then
  echo "root:${PASSWORD}" | chpasswd
fi

# Install routes to LAN via container gateway
if [ -n "${ADVERTISE_ROUTES}" ] && [ -n "${CONTAINER_GATEWAY}" ]; then
  IFS=',' read -ra SUBNETS <<< "${ADVERTISE_ROUTES}"
  for s in "${SUBNETS[@]}"; do
    ip route add "$s" via "${CONTAINER_GATEWAY}"
  done
fi

# Perform an update if set
if [[ -n "${UPDATE_TAILSCALE}" ]]; then
  /usr/local/bin/tailscale update --yes
fi

# Set login server for tailscale
if [[ -z "${LOGIN_SERVER}" ]]; then
  LOGIN_SERVER=https://controlplane.tailscale.com
fi

# Execute startup script if it exists
if [[ -n "${STARTUP_SCRIPT}" && -f "${STARTUP_SCRIPT}" ]]; then
  bash "${STARTUP_SCRIPT}" || exit $?
fi

# Start tailscaled and bring tailscale up
/usr/local/bin/tailscaled ${TAILSCALED_ARGS} &

until /usr/local/bin/tailscale up \
  --reset --authkey="${AUTH_KEY}" \
  --login-server "${LOGIN_SERVER}" \
  --advertise-routes="${ADVERTISE_ROUTES}" \
  ${TAILSCALE_ARGS}
do
  sleep 1
done
echo "Tailscale started"

# Ensure Tailscale routes exist inside the container
if ! ip route show 100.64.0.0/10 > /dev/null 2>&1; then
  ip route add 100.64.0.0/10 dev tailscale0
fi

if ! ip -6 route show fd7a:115c:a1e0::/48 > /dev/null 2>&1; then
  ip -6 route add fd7a:115c:a1e0::/48 dev tailscale0
fi

# Execute running script if it exists
if [[ -n "${RUNNING_SCRIPT}" && -f "${RUNNING_SCRIPT}" ]]; then
  bash "${RUNNING_SCRIPT}" || exit $?
fi

# Start SSH for management
/usr/sbin/sshd -D &

# Keep the script running
wait
