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

kubectl create secret generic kratos-secret \
  --namespace ory \
  --from-literal='dsn=postgres://kratos:GKS6rPp1qsQiIgU88azbO5r6jpWiSiCiLgXj@postgresql-hl:5432/kratos?sslmode=disable' \
  --from-literal='secretsDefault=vbMpslHWebFOTLf9VHukpNsJzc6DN2SWf6ghXNyoJKDzHF4WaG' \
  --from-literal='secretsCookie=ViKzkNxnRr02SZA6xBa9cuZXa5Yf35FzThUKUyholKJMnvBybq' \
  --from-literal='secretsCipher=yB2bej27y0DzBgTFcL9jq7yh2iMrS5El1yaD6l1cdG2r82X3Dh' \
  --from-literal='smtpConnectionURI=smtps://foo:bar@my-mailserver:1234/?skip_ssl_verify=false' \
  --dry-run=client -o yaml | kubeseal \
  --cert=cert.pem --format=yaml \
  > my-sealed-secret.yaml