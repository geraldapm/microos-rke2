#!/bin/bash
set -e

mkdir -p butane-autogen
output_yaml="butane-autogen/butane-hosts.yaml"
indent="          "

### Edit with list of hosts that will be inserted into /etc/hosts

source hostlist.sh

hostlist_parsed=$(echo "$hostlist" | sed "s/^/${indent}/")

# Write the header to the output YAML file
cat > "$output_yaml" <<-EOF
variant: fcos
version: 1.5.0
storage:
  files:
    - path: /etc/hosts
      mode: 0644
      overwrite: true
      contents:
        inline: |
          127.0.0.1 localhost localhost.localdomain
          ::1		localhost localhost.localdomain ipv6-localhost ipv6-loopback

          ###IP_ADDRESS### ###HOSTNAME### ###HOSTNAME###.local ###HOSTNAME###.gpm.my.id
$hostlist_parsed
EOF

echo "/etc/hosts have been generated successfully!"
echo "YAML file '$output_yaml' has been successfully overwritten!"