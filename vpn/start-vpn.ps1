# Run on the desktop. Advertises the home LAN over Tailscale and accepts
# routes back. See docs/vpn-plan.md for the full build log and reasoning.
#
# MANUAL EDIT: replace YOUR_LAN_SUBNET with your real subnet, e.g. 192.168.1.0/24
# (same value as LAN_SUBNET in your local .env).
#
# IMPORTANT: always run via this script, or with the full flags typed out -
# Tailscale does NOT remember flags between "tailscale down"/"tailscale up"
# runs. A bare "tailscale up" after "tailscale down" reconnects but silently
# drops the advertised route - it will show "connected" while forwarding
# nothing to the LAN.

tailscale up --advertise-routes=YOUR_LAN_SUBNET --accept-routes
tailscale status