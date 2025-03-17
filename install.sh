#!/bin/sh



ROOT_DIR=$(dirname "$0")
CONFIG_FILE="$(pwd)/grafana.conf"
CERT_FILE="$(pwd)/cert.pem"
KEY_FILE="$(pwd)/key.pem"


echo "🚀 Installing Helm..."
if ! helm version --short; then
    echo "Helm is not installed. Installing now..."
    set -e
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    set +e
else
    echo "Helm is already installed: $(helm version --short)"
fi

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update sealed-secrets
helm repo add traefik https://traefik.github.io/charts
helm repo update traefik



set -e


echo "🚀 Installing Metrics Server..."
helm dependency update --skip-refresh --debug "$ROOT_DIR/src/infrastructure/metrics-server"
helm upgrade metrics-server "$ROOT_DIR/src/infrastructure/metrics-server" \
    --debug \
    --install \
    --wait \
    --namespace kube-system


echo "🚀 Installing Grafana Cloud Agent..."
#!/bin/sh

# Check if the file exists
echo "Checking configuration file..."
echo "Configuration file: $CONFIG_FILE"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file grafana.conf does not exist." >&2
    exit 1
fi

# Initialize empty variables
LOGS_ID=""
METRICS_ID=""
API_KEY=""

# Read each line of the file
while IFS= read -r line; do
    case "$line" in
        LOGS_ID=*) LOGS_ID=$(echo "$line" | cut -d'=' -f2) ;;
        METRICS_ID=*) METRICS_ID=$(echo "$line" | cut -d'=' -f2) ;;
        API_KEY=*) API_KEY=$(echo "$line" | cut -d'=' -f2) ;;
    esac
done < "$CONFIG_FILE"

# Check if any value is missing
MISSING=0
if [ -z "$LOGS_ID" ]; then
    echo "Error: grafana.conf missing LOGS_ID" >&2
    MISSING=1
fi
if [ -z "$METRICS_ID" ]; then
    echo "Error: grafana.conf missing METRICS_ID" >&2
    MISSING=1
fi
if [ -z "$API_KEY" ]; then
    echo "Error: grafana.conf missing API_KEY" >&2
    MISSING=1
fi

# Exit if there are errors
if [ "$MISSING" -eq 1 ]; then
    exit 1
fi
kubectl create namespace monitoring --dry-run=client -o yaml| kubectl apply -f -
kubectl create secret generic grafana-cloud-credentials \
  --namespace monitoring \
  --from-literal=loki-username=$LOGS_ID \
  --from-literal=prom-username=$METRICS_ID \
  --from-literal=access-token=$API_KEY \
  --dry-run=client -o yaml | kubectl apply -f -
helm dependency update --skip-refresh --debug "$ROOT_DIR/src/infrastructure/grafana-cloud-agent"
helm upgrade grafana-cloud-agent "$ROOT_DIR/src/infrastructure/grafana-cloud-agent" \
    --debug \
    --install \
    --wait \
    --namespace monitoring


echo "🚀 Installing SealedSecrets..."
if kubectl get secret sealed-secrets-key -n kube-system >/dev/null 2>&1; then
    echo "🔐 SealedSecrets key already exists."
else
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
        echo "🔐 Generating sealed-secrets key..."
        kubectl create secret tls sealed-secrets-key \
            --namespace=kube-system \
            --cert=$(pwd)/cert.pem \
            --key=$(pwd)/key.pem
    else
        echo "❌ Missing cert.pem and/or key.pem files."
        exit 1
    fi
fi
helm dependency update --skip-refresh --debug "$ROOT_DIR/src/infrastructure/sealed-secrets"
helm upgrade sealed-secrets "$ROOT_DIR/src/infrastructure/sealed-secrets" \
    --debug \
    --install \
    --wait \
    --namespace kube-system 


echo "🚀 Installing CertManager..."
helm dependency update --skip-refresh --debug "$ROOT_DIR/src/infrastructure/cert-manager"
helm upgrade cert-manager "$ROOT_DIR/src/infrastructure/cert-manager" \
    --debug \
    --install \
    --wait \
    --namespace kube-system 
kubectl apply -f "$ROOT_DIR/src/infrastructure/cluster-issuer/cluster-issuer.yaml"

echo "🚀 Installing Traefik..."
helm dependency update --skip-refresh --debug  "$ROOT_DIR/src/infrastructure/traefik"
helm upgrade  traefik "$ROOT_DIR/src/infrastructure/traefik" \
    --debug \
    --install \
    --wait \
    --namespace kube-system 

echo "🚀 Installing Cloudflare Tunnel..."
kubectl apply -f "$ROOT_DIR/src/infrastructure/cloudflare-tunnel/manifests/" 


echo "🚀 Installing ArgoCD..."
kubectl kustomize --enable-helm "$ROOT_DIR/src/applications/argo-cd" | kubectl apply -f -

echo "⏳ Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=server -n argocd --timeout=300s
echo "🚀 ArgoCD is ready!"

echo "🚀 Creating ArgoCD resources..."
kubectl apply -f "$ROOT_DIR/bootstrap/root.yaml"

echo "🚀 ArgoCD is installed!"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo ""