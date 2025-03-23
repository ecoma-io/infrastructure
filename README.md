# infrastructure


## Install on cluster

In the cluster node (helm installed and kubectl has access to the cluster)
1. Copy 2 files cert.pem & key.pem to cluster node 
2. Create grafana.confg

```
LOGS_ID=xxxxxx
METRICS_ID=xxxxxx
API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
3. Run command for install/reinstall

``` Shell
git clone https://github.com/ecoma-io/infrastructure.git
sh infrastructure/install.sh
```

Note: Delete the private key immediately after generating the secret for security reasons


## Development

Let's use public key file `cert.pem` for generate sealed secrets

Example code
```
kubectl create secret generic my-secret \
  --namespace default \
  --from-literal=username=admin \
  --from-literal=password=supersecret \
  --dry-run=client -o yaml | kubeseal \
  --cert=cert.pem --format=yaml \
  > my-sealed-secret.yaml
```


kubectl create secret generic keycloak-clientid-secret \
  --namespace argocd \
  --from-literal=clientid=exh0jNQPF5NKI4GKS6rPp1qsQiIgU88azbO5r6jpWiSiCiLgXj \
  --dry-run=client -o yaml | kubeseal \
  --cert=cert.pem --format=yaml \
  > my-sealed-secret.yaml
