#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <tf_output.json> <output_inventory_file>"
  exit 2
fi

TF_JSON="$1"
OUT="$2"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed. Aborting." >&2
  exit 3
fi

# Load JSON and try to normalize wrapper (some terraform outputs include a top-level "value")
INVENTORY_JSON=$(jq 'if type=="object" and has("value") then .value else . end' "$TF_JSON")

# Extract username/password (try a few common keys present in some outputs)
SSH_USER=$(echo "$INVENTORY_JSON" | jq -r '(.username // .user // .ssh_user // .value.username // .value.user) // empty')
SSH_PASS=$(echo "$INVENTORY_JSON" | jq -r '(.password // .pass // .ssh_password // .value.password) // empty')

# Fallback: also check top-level tf json
if [ -z "$SSH_USER" ] || [ "$SSH_USER" = "null" ]; then
  SSH_USER=$(jq -r '(.username // .user // .ssh_user) // empty' "$TF_JSON")
fi
if [ -z "$SSH_PASS" ] || [ "$SSH_PASS" = "null" ]; then
  SSH_PASS=$(jq -r '(.password // .pass // .ssh_password) // empty' "$TF_JSON")
fi

# Write a complete YAML inventory (overwrite or create)
python3 - "$TF_JSON" "$OUT" <<'PY'
import sys, json
tf = sys.argv[1]
out = sys.argv[2]
data = json.load(open(tf))
inv = data
if isinstance(data, dict) and 'value' in data and isinstance(data['value'], dict):
    inv = data['value']

# Pull username/password if present
user = inv.pop('username', None) or inv.pop('user', None) or inv.pop('ssh_user', None) or data.get('username') or (data.get('value') or {}).get('username') or ''
passwd = inv.pop('password', None) or inv.pop('pass', None) or inv.pop('ssh_password', None) or data.get('password') or (data.get('value') or {}).get('password') or ''

def write_line(f, s):
    f.write(s + '\n')

with open(out, 'w') as f:
    write_line(f, 'all:')
    write_line(f, '  vars:')
    write_line(f, f'    ansible_user: "{user}"')
    write_line(f, f'    ansible_become_password: "{passwd}"')
    write_line(f, '    ansible_python_interpreter: "/usr/bin/python3.11"')
    write_line(f, '    ansible_connect_timeout: 60')
    write_line(f, '    control_plane_cluster_cert_root: "/tmp/cluster_certs"')
    write_line(f, '  children:')

    # inv should now contain groups
    for group, hosts in inv.items():
        if group in ('username','password','user','pass','ssh_user','ssh_password'):
            continue
        write_line(f, f'    {group}:')
        write_line(f, '      hosts:')

        # hosts may be a mapping or a list
        if isinstance(hosts, dict):
            for h, attrs in hosts.items():
                write_line(f, f'        {h}:')
                if isinstance(attrs, dict):
                    for k, v in attrs.items():
                        write_line(f, f'          {k}: {v}')
        elif isinstance(hosts, list):
            for item in hosts:
                if isinstance(item, str):
                    write_line(f, f'        {item}:')
                    write_line(f, f'          ansible_host: {item}')
                elif isinstance(item, dict):
                    name = item.get('name') or item.get('hostname') or item.get('host') or item.get('ansible_host')
                    if name:
                        write_line(f, f'        {name}:')
                        for k, v in item.items():
                            if k in ('name','hostname','host'):
                                continue
                            write_line(f, f'          {k}: {v}')
                    else:
                        # fallback: dump the dict as key-value under a generated host name
                        # create a simple generated name
                        gen = 'host_' + str(abs(hash(str(item))) % 100000)
                        write_line(f, f'        {gen}:')
                        for k, v in item.items():
                            write_line(f, f'          {k}: {v}')
        else:
            # unknown format, write it as a single host entry
            write_line(f, f'        unknown_host:')
            write_line(f, f'          raw: "{hosts}"')
PY

echo "Generated inventory at: $OUT"
#!/bin/bash
# Generate Ansible inventory from Terraform output
# This script converts Terraform JSON output into Ansible YAML inventory format

set -e

TF_OUTPUT_FILE="$1"
INVENTORY_FILE="$2"

jq -r '
  .vms 
  | to_entries[] 
  | "    " + .key + ":\n      hosts:\n" + (
      [
        .value[] 
        | "        " + .hostname + ":\n" +
          "          ansible_host: " + .ip + "\n" +
          "          provider: " + .provider + "\n" +
          "          region: " + .region + "\n" +
          "          zone: " + .zone + "\n" +
          "          disks:\n" + (
            [
              .disks[] 
              | "            - name: \"" + .name + "\"\n" +
                "              tier: \"" + .tier + "\""
            ] 
            | join("\n")
          )
      ] 
      | join("\n")
    )
' "$TF_OUTPUT_FILE" >> "$INVENTORY_FILE"
