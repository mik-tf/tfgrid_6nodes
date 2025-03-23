<h1> ThreeFold Grid 6-Node Open Tofu Deployment</h1>

<h2>Table of Contents</h2>

- [Overview](#overview)
- [Key Components](#key-components)
  - [Network Architecture](#network-architecture)
  - [Node Configuration](#node-configuration)
- [Quick Deployment](#quick-deployment)
  - [1. Initialize Deployment](#1-initialize-deployment)
  - [2. Apply Configuration](#2-apply-configuration)
  - [3. Set WireGuard](#3-set-wireguard)
  - [4. Network Validation](#4-network-validation)
- [Customization Guide](#customization-guide)
  - [Network Testing](#network-testing)
  - [Resource Profiles](#resource-profiles)
- [Operational Management](#operational-management)
  - [Infrastructure Scaling](#infrastructure-scaling)
  - [Secure Teardown](#secure-teardown)
- [Building On This Foundation](#building-on-this-foundation)
  - [Common Next Steps](#common-next-steps)
- [License](#license)

---

## Overview

This OpenTofu project establishes a production-ready foundation for decentralized infrastructure deployments on the ThreeFold Grid, featuring:

- 6-node base infrastructure (3 control + 3 workers)
- Triple-layer networking:
  - **Mycelium** IPv6 overlay network
  - **WireGuard** private mesh VPN
  - Public IPv4 for worker nodes
- Customizable resource profiles
- Network validation template script

This project is designed as the essential first layer for building Kubernetes clusters, distributed storage systems, or HA application deployments.

## Key Components

### Network Architecture
| Layer           | Scope        | Protocol | Use Case                  |
|-----------------|--------------|----------|---------------------------|
| Mycelium        | All nodes    | IPv6     | Decentralized peer routing|
| WireGuard       | All nodes    | IPv4     | Secure control plane      |
| Public IPv4     | Worker nodes | IPv4     | External accessibility    |

### Node Configuration
```bash
├── Control Nodes (3)
│   ├── Dedicated private networking
│   └── Resource profile: 2vCPU/2GB RAM/10GB Disk
└── Worker Nodes (3)
    ├── Public + private networking
    └── Resource profile: 4vCPU/4GB RAM/20GB Disk
```

## Quick Deployment

### 1. Initialize Deployment
```bash
git clone https://github.com/mik-tf/tfgrid_6nodes
cd tfgrid_6nodes/deployment
cp credentials.auto.tfvars.example credentials.auto.tfvars
```

Edit `credentials.auto.tfvars` with:
- ThreeFold Mnemonic
- SSH Public Key
- Node IDs from TF Dashboard
- Resource allocations

### 2. Apply Configuration
```bash
cd deployments
tofu init
tofu apply -auto-approve
```

### 3. Set WireGuard

```
cd ../scripts
bash wg.sh
```

### 4. Network Validation

Check the IP addresses with `tofu show` and update the script template then run the script to generate a log.

```bash
bash ../scripts/ping.sh > network-test-$(date +%s).log
```

Sample output verifies connectivity across all layers:
```text
=== Mycelium (node_0: 42f:208e:987:118e:ff0f:89b4:bacb:e678) ===
64 bytes from 42f:208e:987:118e:ff0f:89b4:bacb:e678: icmp_seq=1 ttl=64 time=1.23 ms

=== WireGuard (node_0: 10.1.3.2) ===
64 bytes from 10.1.3.2: icmp_seq=1 ttl=64 time=1.05 ms

=== Public IP (node_3: 185.69.167.158) ===
64 bytes from 185.69.167.158: icmp_seq=1 ttl=64 time=15.3 ms
```

## Customization Guide

### Network Testing
Modify `scripts/ping.sh` for advanced validation:
```bash
# Change ping parameters
ping -c 10 -i 0.5 "${wireguard_ips[$node]}"  # 10 pings @500ms interval

# Add latency statistics
ping -c 20 "${public_ips[$node]}" | grep 'min/avg/max'
```

### Resource Profiles
Adjust in `credentials.auto.tfvars`:
```hcl
control_cpu = 4       # vCPU count
control_mem = 4096    # Memory in MB
control_disk = 50     # Storage in GB

worker_cpu = 8
worker_mem = 16384
worker_disk = 500
```

## Operational Management

### Infrastructure Scaling
1. Update node counts in `credentials.auto.tfvars`
2. Reapply configuration:
```bash
tofu apply -refresh=false
```

### Secure Teardown
```bash
tofu destroy -auto-approve
wg-quick down tfgrid
rm /etc/wireguard/tfgrid.conf
```

## Building On This Foundation

### Common Next Steps
1. **Kubernetes Deployment**
```bash
ansible-playbook -i wireguard_ips k8s-cluster.yml
```

2. **Distributed Storage**
```bash
ssh 10.1.3.2 "ceph-deploy new node_{0..5}"
```

3. **HA Application Stack**
```bash
docker stack deploy -c traefik.yml public_nodes
```

## License

**Apache 2.0** - Full text in [LICENSE](./LICENSE) 

---

> **Important**: This deployment establishes the infrastructure layer only.  
> Subsequent application layers should maintain separate state management.
> Consult the [docs](./docs/ansible_post_deployment.md) for more information.