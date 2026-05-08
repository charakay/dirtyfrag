#!/bin/bash
set -e

echo "=== Dirty Frag (CVE Pending) Detector ==="
echo "[*] Kernel: $(uname -r)"
echo "[*] Arch: $(uname -m)"
echo "[*] Date: $(date -u)"
echo ""

# Check if rxrpc module is loadable
echo "[*] Checking rxrpc module..."
if modprobe rxrpc 2>/dev/null; then
    echo "[+] rxrpc module loadable - RxRPC path precondition met"
    RXRPC_OK=1
else
    echo "[-] rxrpc module not loadable - RxRPC path blocked"
    RXRPC_OK=0
fi

# Check if unprivileged user namespaces are available (ESP path)
echo "[*] Checking unprivileged user namespace support..."
if unshare --user --map-root-user echo ok 2>/dev/null; then
    echo "[+] Unprivileged user namespaces available - ESP path precondition met"
    USERNS_OK=1
else
    echo "[-] Unprivileged user namespaces blocked - ESP path blocked"
    USERNS_OK=0
fi

# Check esp4/esp6 modules
echo "[*] Checking esp4/esp6 modules..."
if modprobe esp4 2>/dev/null && modprobe esp6 2>/dev/null; then
    echo "[+] esp4/esp6 modules loadable - ESP path precondition met"
    ESP_OK=1
else
    echo "[-] esp4/esp6 modules not loadable - ESP path blocked"
    ESP_OK=0
fi

echo ""
echo "=== RESULT ==="

if [ "$RXRPC_OK" -eq 1 ]; then
    echo "[!] POTENTIALLY VULNERABLE via RxRPC path"
    echo "[!] rxrpc module is loadable - mitigation not applied"
elif [ "$USERNS_OK" -eq 1 ] && [ "$ESP_OK" -eq 1 ]; then
    echo "[!] POTENTIALLY VULNERABLE via ESP path"
    echo "[!] Unprivileged namespaces + esp4/esp6 available"
else
    echo "[+] Preconditions NOT met - not exploitable via known Dirty Frag paths"
    echo "[+] Either rxrpc is blocked AND (namespaces or esp4/esp6 are blocked)"
fi

echo ""
echo "[*] Module status:"
echo "    rxrpc:  $(lsmod | grep -c rxrpc || echo 0) instance(s) loaded"
echo "    esp4:   $(lsmod | grep -c '^esp4' || echo 0) instance(s) loaded"
echo "    esp6:   $(lsmod | grep -c '^esp6' || echo 0) instance(s) loaded"
echo ""
echo "[*] Mitigation check:"
grep -l "esp4\|esp6\|rxrpc" /etc/modprobe.d/*.conf 2>/dev/null && \
    echo "    Modprobe blacklist files found" || \
    echo "    No modprobe blacklist found"
echo ""
echo "=== Done ==="
