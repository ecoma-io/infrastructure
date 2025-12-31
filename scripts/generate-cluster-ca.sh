#!/usr/bin/env bash
set -euo pipefail

# This script generates CA/key pairs and an admin kubeconfig, but does NOT
# write persistent files to the repository. All artifacts are created in a
# temporary directory and printed to stdout for the admin to copy/save
# securely (or create secrets). The tempdir is removed on exit.

IP="127.0.0.1"
DAYS=3650

TMPDIR=$(mktemp -d)
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "Current system time: $(date)"
echo "Current UTC time: $(date -u)"
echo ""

generate_ca() {
    local name=$1
    local cn=$2
    local cfg="$TMPDIR/${name}.cnf"
    cat > "$cfg" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca

[req_distinguished_name]

[v3_ca]
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

    openssl genrsa -out "$TMPDIR/${name}.key" 2048
    openssl req -x509 -new -nodes -key "$TMPDIR/${name}.key" -sha256 -days $DAYS \
        -out "$TMPDIR/${name}.crt" -subj "/CN=${cn}" -config "$cfg" \
        -extensions v3_ca
    echo "Generated ${name}.crt and ${name}.key (temporary)."
}

echo "1) Generating 3 CA pairs in a temporary directory..."
generate_ca "server-ca" "k3s-server-ca"
generate_ca "client-ca" "k3s-client-ca"
generate_ca "request-header-ca" "k3s-request-header-ca"

echo "2) Generating admin client key and certificate signed by client CA..."
openssl genrsa -out "$TMPDIR/admin-client.key" 2048
openssl req -new -key "$TMPDIR/admin-client.key" -out "$TMPDIR/admin-client.csr" -subj "/O=system:masters/CN=admin"
openssl x509 -req -in "$TMPDIR/admin-client.csr" -CA "$TMPDIR/client-ca.crt" -CAkey "$TMPDIR/client-ca.key" \
    -CAcreateserial -out "$TMPDIR/admin-client.crt" -days $DAYS -sha256

echo
echo "----- BEGIN OUTPUT: CERTS/KEYS -----"

print_file() {
    local title="$1"
    local path="$2"
    echo "--- $title ---"
    sed -n '1,${p;}' "$path" 2>/dev/null || cat "$path"
    echo
}

# Print the CA and keys for manual copy
echo "=== Certificates and keys (PEM) ==="
echo
print_file "server-ca.crt" "$TMPDIR/server-ca.crt"
print_file "server-ca.key" "$TMPDIR/server-ca.key"
print_file "client-ca.crt" "$TMPDIR/client-ca.crt"
print_file "client-ca.key" "$TMPDIR/client-ca.key"
print_file "request-header-ca.crt" "$TMPDIR/request-header-ca.crt"
print_file "request-header-ca.key" "$TMPDIR/request-header-ca.key"
print_file "admin-client.crt" "$TMPDIR/admin-client.crt"
print_file "admin-client.key" "$TMPDIR/admin-client.key"

echo "=== Base64 encodings (useful for Kubernetes secrets) ==="
echo
echo "# server-ca.crt (base64)"
base64 -w0 "$TMPDIR/server-ca.crt" || base64 "$TMPDIR/server-ca.crt"
echo
echo "# admin-client.crt (base64)"
base64 -w0 "$TMPDIR/admin-client.crt" || base64 "$TMPDIR/admin-client.crt"
echo
echo "# admin-client.key (base64)"
base64 -w0 "$TMPDIR/admin-client.key" || base64 "$TMPDIR/admin-client.key"
echo

echo "3) Kubeconfig (printed with embedded certs)"

SERVER_CA_B64=$(base64 -w0 "$TMPDIR/server-ca.crt" || base64 "$TMPDIR/server-ca.crt")
ADMIN_CRT_B64=$(base64 -w0 "$TMPDIR/admin-client.crt" || base64 "$TMPDIR/admin-client.crt")
ADMIN_KEY_B64=$(base64 -w0 "$TMPDIR/admin-client.key" || base64 "$TMPDIR/admin-client.key")

cat <<EOF
--- kubeconfig (copy & save as a file, then replace server address) ---
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${SERVER_CA_B64}
    server: https://${IP}:6443
  name: default
contexts:
- context:
    cluster: default
    user: admin
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: admin
  user:
    client-certificate-data: ${ADMIN_CRT_B64}
    client-key-data: ${ADMIN_KEY_B64}
EOF

echo
echo "----- END OUTPUT: CERTS/KEYS -----"
echo
echo "Notes for the admin:"
echo "- The script did not write persistent files in the repo. Copy the PEM blocks above into files like server-ca.crt, admin-client.crt, admin-client.key and store them securely."
echo "- Use the base64 lines to create Kubernetes TLS secrets, e.g. with kubectl create secret tls <name> --cert=... --key=... (or via secret manifest using the base64 values)."
echo "- Replace the kubeconfig 'server' value with your actual control plane IP or VIP before use."

# cleanup handled by trap