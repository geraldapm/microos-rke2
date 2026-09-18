#!/bin/bash

PATH=$PATH:$(pwd)

source hostlist.sh

# Define the VM names array
vms=($(echo "$hostlist" | awk '{print $2}'))

### Define the first controlplane IP to init the kubeadm cluster
IP_RANGE_CONTROLPLANE1=192.168.100.101

### Define the default directory gen
CURRENT_DIR=$(pwd)

BUTANE_AUTOGEN_DIR=$CURRENT_DIR/butane-autogen
BUTANE_STATIC_DIR=$CURRENT_DIR/butane-config
BUTANE_GENERATED_DIR=$CURRENT_DIR/butane-generated
IGNITION_DIR=$CURRENT_DIR/ignition

### POD and service CIDR
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/12

### Versioning used in the provisioning scripts
RKE2_VERSION="v1.35.4+rke2r1"

if [[ $1 == "--generate" ]];
then
# create the generated butane directory
mkdir -p $BUTANE_GENERATED_DIR $IGNITION_DIR

### Generate ssh butane config
bash ./scripts/ssh-generator.sh

### Generate hosts butane config
bash ./scripts/hosts-generator.sh

### Generate haproxy butane config
floating_ip=$IP_FLOATING hostlist="$hostlist" bash ./scripts/haproxy-generator.sh
fi

RKE2_TOKEN="RKE2_SECRET_TOKEN"

cert_dir="$CURRENT_DIR/certs"

# Change the CNI provider to match requirement. available: cilium, calico
CNI_PROVIDER=cilium

# RKE2_BINARY_URL="https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/rke2.linux-amd64"
# RKE2_IMAGE_URL="https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/rke2-images.linux-amd64.tar.zst"
# RKE2_CNI_URL="https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/rke2-images-${CNI_SELECTION}.linux-amd64.tar.zst"

RKE2_BINARY_URL='http://192.168.100.1:8080/rke2/${RKE2_VERSION}/rke2.linux-amd64'
RKE2_IMAGE_URL='http://192.168.100.1:8080/rke2/${RKE2_VERSION}/rke2-images.linux-amd64.tar.zst'
RKE2_CNI_URL='http://192.168.100.1:8080/rke2/${RKE2_VERSION}/rke2-images-${CNI_SELECTION}.linux-amd64.tar.zst'


for vm in ${vms[*]}; do 
    IP_ADDR="$(echo "$hostlist" | grep $vm | awk '{print $1}')"
    CIDR="$(echo $IP_SUBNET | cut -d'/' -f2)"

    echo "Generating ignition config for VM $vm with IP Address $IP_ADDR/$CIDR gateway $IP_GATEWAY"

    # Set node role to controlplane/worker
    K8S_SERVER_STRING="controlplane"
    K8S_MODE="controlplane"

    if [[ "$vm" == *"$K8S_SERVER_STRING"*  ]]; then
    echo "Generating ignition config for $vm as kubernetes $K8S_MODE node"
    else
    K8S_MODE="worker"
    echo "Generating ignition config for $vm as kubernetes $K8S_MODE node"
    fi

    if [[ "$IP_ADDR" == "$IP_RANGE_CONTROLPLANE1" ]]; then
        cat << EOF > $BUTANE_GENERATED_DIR/butane-$vm.yaml
        variant: fcos
        version: 1.5.0
        ignition:
            config:
                merge:
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-common.yaml \
                        | sed "s+###IP_GATEWAY###+$IP_GATEWAY+g" \
                        | sed "s+/###CIDR###+/$CIDR+g" \
                        | sed "s+###HOSTNAME###+$vm+g" \
                        | sed "s+###IP_ADDRESS###+$IP_ADDR+g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-ssh.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-hosts.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-keepalived.yaml \
                        | sed "s+###FLOATINGIP###+$IP_FLOATING+g" \
                        | sed "s+###KEEPALIVED_PRIORITY###+200+g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-haproxy.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-rke2-installer.yaml \
                        | sed "s+###RKE2_BINARY_URL###+$RKE2_BINARY_URL+g" \
                        | sed "s+###RKE2_IMAGE_URL###+$RKE2_IMAGE_URL+g" \
                        | sed "s+###RKE2_CNI_URL###+$RKE2_CNI_URL+g" \
                        | sed "s:###RKE2_VERSION###:$RKE2_VERSION:g" \
                        | sed "s:###CNI_SELECTION###:$CNI_PROVIDER:g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-rke2-server.yaml \
                        | sed "s+###CLUSTERMODE###+$CLUSTERMODE+g" \
                        | sed "s+###CNIMODE###+$CNI_PROVIDER+g" \
                        | sed "s+###FLOATINGIP###+$IP_FLOATING+g" \
                        | sed "s+###POD_CIDR###+$POD_CIDR+g" \
                        | sed "s+###SERVICE_CIDR###+$SERVICE_CIDR+g" \
                        | sed "s+###IP_ADDRESS###+$IP_ADDR+g" \
                        | sed "s+###RKE2_TOKEN###+$RKE2_TOKEN+g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-$CNI_PROVIDER.yaml \
                        | butane)
EOF
     elif [[ "$K8S_MODE" == "controlplane"  ]]; then
        CLUSTERMODE="server: https://###FLOATINGIP###:9345"
        cat << EOF > $BUTANE_GENERATED_DIR/butane-$vm.yaml
        variant: fcos
        version: 1.5.0
        ignition:
            config:
                merge:
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-common.yaml \
                        | sed "s+###IP_GATEWAY###+$IP_GATEWAY+g" \
                        | sed "s+/###CIDR###+/$CIDR+g" \
                        | sed "s+###HOSTNAME###+$vm+g" \
                        | sed "s+###IP_ADDRESS###+$IP_ADDR+g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-ssh.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-hosts.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-keepalived.yaml \
                        | sed "s+###FLOATINGIP###+$IP_FLOATING+g" \
                        | sed "s+###KEEPALIVED_PRIORITY###+100+g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-haproxy.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-rke2-installer.yaml \
                        | sed "s+###RKE2_BINARY_URL###+$RKE2_BINARY_URL+g" \
                        | sed "s+###RKE2_IMAGE_URL###+$RKE2_IMAGE_URL+g" \
                        | sed "s+###RKE2_CNI_URL###+$RKE2_CNI_URL+g" \
                        | sed "s:###RKE2_VERSION###:$RKE2_VERSION:g" \
                        | sed "s:###CNI_SELECTION###:$CNI_PROVIDER:g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-rke2-server.yaml \
                        | sed "s+###CLUSTERMODE###+$CLUSTERMODE+g" \
                        | sed "s+###CNIMODE###+$CNI_PROVIDER+g" \
                        | sed "s+###FLOATINGIP###+$IP_FLOATING+g" \
                        | sed "s+###POD_CIDR###+$POD_CIDR+g" \
                        | sed "s+###SERVICE_CIDR###+$SERVICE_CIDR+g" \
                        | sed "s+###IP_ADDRESS###+$IP_ADDR+g" \
                        | sed "s+###RKE2_TOKEN###+$RKE2_TOKEN+g" \
                        | butane)
EOF
    else
        CLUSTERMODE='server: https://###FLOATINGIP###:9345'
        cat << EOF > $BUTANE_GENERATED_DIR/butane-$vm.yaml
        variant: fcos
        version: 1.5.0
        ignition:
            config:
                merge:
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-common.yaml \
                        | sed "s+###IP_GATEWAY###+$IP_GATEWAY+g" \
                        | sed "s+/###CIDR###+/$CIDR+g" \
                        | sed "s+###HOSTNAME###+$vm+g" \
                        | sed "s+###IP_ADDRESS###+$IP_ADDR+g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-ssh.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_AUTOGEN_DIR/butane-hosts.yaml \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-rke2-installer.yaml \
                        | sed "s+###RKE2_BINARY_URL###+$RKE2_BINARY_URL+g" \
                        | sed "s+###RKE2_IMAGE_URL###+$RKE2_IMAGE_URL+g" \
                        | sed "s+###RKE2_CNI_URL###+$RKE2_CNI_URL+g" \
                        | sed "s:###RKE2_VERSION###:$RKE2_VERSION:g" \
                        | sed "s:###CNI_SELECTION###:$CNI_PROVIDER:g" \
                        | butane)
                - inline: |-
                    $(cat $BUTANE_STATIC_DIR/butane-rke2-agent.yaml \
                        | sed "s+###CLUSTERMODE###+$CLUSTERMODE+g" \
                        | sed "s+###CNIMODE###+$CNI_PROVIDER+g" \
                        | sed "s+###FLOATINGIP###+$IP_FLOATING+g" \
                        | sed "s+###IP_ADDRESS###+$IP_ADDR+g" \
                        | sed "s+###RKE2_TOKEN###+$RKE2_TOKEN+g" \
                        | butane)
EOF
    fi

    # Generate ignition file from compiled butane files
    butane --pretty $BUTANE_GENERATED_DIR/butane-$vm.yaml > $IGNITION_DIR/$vm.ign

    #Remove unused butane generated file
    rm -f $BUTANE_GENERATED_DIR/butane-$vm.yaml
done