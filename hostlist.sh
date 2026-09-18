#!/bin/bash

### Define IP Subnet for CIDR assignment including floating IP and gateway IP

IP_SUBNET=192.168.100.0/24

### Set IP Subnet Gateway
IP_GATEWAY="$(echo $IP_SUBNET | cut -d. -f1-3).1"

### Define the Virtual IP or Floating IP
IP_FLOATING="$(echo $IP_SUBNET | cut -d. -f1-3).99"

### Define cluster member list
### Ensure that the hostname has "wontrol" and "worker" inside for node role filtering
hostlist=$(cat <<EOF
192.168.100.101     gpmrke2controlplane1
192.168.100.102     gpmrke2controlplane2
192.168.100.103     gpmrke2controlplane3
EOF
)
# hostlist=$(cat <<EOF
# 192.168.100.101     gpmrke2controlplane1
# 192.168.100.102     gpmrke2controlplane2
# 192.168.100.103     gpmrke2controlplane3
# 192.168.100.104     gpmrke2worker1    
# 192.168.100.105     gpmrke2worker2
# EOF
# )