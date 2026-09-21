# RKE2 openSUSE Leap Micro provisioning with Ignition way
openSUSE Leap Micro Installation with RKE2 Cluster provisioning
This repository contains the quick way to deploy a RKE2 basic HA cluster with openSUSE Leap Micro. It is intended to be recycleable and minimizing the requirement to intervene manually during RKE2 installation. Just sit down, grab some drinks, and enjoy the process. Easily creatable and destroyable RKE2 cluster.

## Prerequisites

- An Installed Linux System with KVM capabilities
- Then download the correspoding openSUSE LEAP Micro Image from This URL -> https://download.opensuse.org/distribution/leap-micro/6.2/appliances/openSUSE-Leap-Micro.x86_64-Default-qcow.qcow2 and store in in the ./images folder
```bash
mkdir -p deployments/images
wget -c https://download.opensuse.org/distribution/leap-micro/6.2/appliances/openSUSE-Leap-Micro.x86_64-Default-qcow.qcow2 -O images/
```

- Butane binary executable to convert butane definition into ignition file. Download it from there -> https://github.com/coreos/butane/releases and install with this command

```bash
wget -c https://github.com/coreos/butane/releases/download/v0.25.1/butane-x86_64-unknown-linux-gnu -O butane
chmod +x butane
```

- Allocatable IP Addresses for each vms
- FAST Internet connection for downloading required binaries

- If you want to serve your own installer, use nginx instead:
```bash
podman run --replace -d \
  --name nginx-static \
  -p 8080:80 \
  -v /home/gerald/Documents/kubernetes/nginx/:/usr/share/nginx/html:Z \
  docker.io/library/nginx:latest
```

TODO: fix etcd join problem

## Environments

3 Control Plane Nodes and 2 Worker Nodes installed with Flatcar Linux and Kubernetes v1.35 cluster with Calico CNI v3.31.5. The spec is 2 vCPU, 2GB Memory and 20GB Stoage (in rootfs). It also has the Floating IP for kubernetes api server reachability and enabling High-Availability, Edit the subnet, ip and hostnames in file [hostlist.sh](./hostlist.sh).

```
floatingip 192.168.122.99

gpmcontrolplane1 192.168.122.101
gpmcontrolplane2 192.168.122.102
gpmcontrolplane3 192.168.122.103
gpmworker1 192.168.122.104
gpmworker2 192.168.122.105
```

## Pre-provisioning

1. Ensure that the latest image is downloaded and inside into the Linux Hypervisor.

2. Generate ignition scripts and other resources with this command:

```shell
bash generate-ignition.sh --generate
```

3. When needed, you can delete all ignition scripts and other resources with this command:

```shell
bash reset-ignition.sh --destroy
```

## Provisioning

Provision the VMs with this command:

```shell
bash start-vm.sh --provision
```

When needed, you can stop the VM with this command:

```shell
bash stop-vm.sh
```

and starting it once again with this command:

```shell
bash start-vm.sh
```

## Cleanup

If you need to stop the VMs and deleting all provisioned VMs, use this command

```shell
bash stop-vm.sh --destroy
```
