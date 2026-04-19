#!/usr/bin/env bash
# safe-deploy.sh — deploy nixgate with automatic rollback on connectivity loss
#
# Uses "colmena apply" in test mode first (non-persistent), waits for
# confirmation, then makes it permanent. If the gateway becomes unreachable
# after test apply, it automatically reboots into the previous generation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$(nix eval --raw --file "$SCRIPT_DIR/../hosts/nixgate/secrets/config.nix" gatewayAddress)}"
TIMEOUT="${2:-60}"

echo "==> Building and applying configuration in TEST mode..."
echo "    Target: $TARGET"
echo "    Rollback timeout: ${TIMEOUT}s"
echo ""

# Apply in test mode (does NOT update boot default)
colmena apply --on nixgate --impure -- test

echo ""
echo "==> Test apply complete. Verifying connectivity..."

if ! ssh -o ConnectTimeout=10 "root@${TARGET}" "echo 'SSH OK'" 2>/dev/null; then
    echo "!!! Lost SSH connectivity via LAN. Waiting for automatic reboot..."
    echo "    (The machine will boot into the previous generation)"
    echo ""
    echo "    If tailscale is available, try: ssh root@nixgate"
    exit 1
fi

echo "==> LAN connectivity confirmed."
echo ""
echo "    The test configuration will revert on reboot."
echo "    You have ${TIMEOUT}s to confirm, or it will be left as test-only."
echo ""
read -t "$TIMEOUT" -p "==> Make this configuration permanent? [y/N] " confirm || true

if [[ "${confirm:-n}" =~ ^[Yy]$ ]]; then
    echo "==> Applying permanently (switch mode)..."
    colmena apply --on nixgate --impure
    echo "==> Deploy complete. New configuration is now the boot default."
else
    echo "==> NOT made permanent. Configuration will revert on next reboot."
    echo "    To revert now: ssh root@${TARGET} reboot"
fi
