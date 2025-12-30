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
