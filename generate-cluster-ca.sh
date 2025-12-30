#!/bin/bash

# Cấu hình
CERT_DIR="./cluster-certs"
IP="127.0.0.1"
DAYS=3650
mkdir -p $CERT_DIR
cd $CERT_DIR

generate_ca() {
    local name=$1
    local cn=$2
    openssl genrsa -out "${name}.key" 2048
    openssl req -x509 -new -nodes -key "${name}.key" -sha256 -days $DAYS -out "${name}.crt" -subj "/CN=${cn}"
}

echo "1. Generating 3 pairs of CAs..."
generate_ca "server-ca" "k3s-server-ca"
generate_ca "client-ca" "k3s-client-ca"
generate_ca "request-header-ca" "k3s-request-header-ca"

echo "2. Generating Admin Certificate for kubeconfig..."
# Tạo private key cho admin
openssl genrsa -out admin-client.key 2048
# Tạo Certificate Signing Request (CSR)
openssl req -new -key admin-client.key -out admin-client.csr -subj "/O=system:masters/CN=admin"
# Ký CSR bằng Client CA
openssl x509 -req -in admin-client.csr -CA client-ca.crt -CAkey client-ca.key -CAcreateserial -out admin-client.crt -days $DAYS -sha256

echo "3. Creating kubeconfig (admin.conf)..."
# Chuyển cert sang Base64 để nhúng trực tiếp vào file
SERVER_CA_B64=$(cat server-ca.crt | base64 | tr -d '\n')
ADMIN_CRT_B64=$(cat admin-client.crt | base64 | tr -d '\n')
ADMIN_KEY_B64=$(cat admin-client.key | base64 | tr -d '\n')

cat <<EOF > kubeconfig
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

echo "4. Cleaning up temporary files..."
# Xóa các file trung gian và file serial của OpenSSL
rm admin-client.* client-ca.srl

echo "------------------------------------------"
echo "DONE! When using kubeconfig, you should replace the server IP with the actual control plane IP or control plan VIP."
ls -F