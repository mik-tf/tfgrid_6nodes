# ThreeFold Grid 6-Node Open Tofu Deployment

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

### 1. Prerequisites
```bash
curl -fsSL https://get.opentofu.org | bash
sudo apt install wireguard-tools jq
```

### 2. Initialize Deployment
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

### 3. Apply Configuration
```bash
tofu init
tofu apply -auto-approve
```

### 4. Network Validation

Check the IP addresses with `tofu show` and update the script template then run the script to generate a log.

```bash
../scripts/ping.sh > network-test-$(date +%s).log
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

## License & Support

**Apache 2.0** - Full text in [LICENSE](./LICENSE) 

---

> **Important**: This deployment establishes the infrastructure layer only.  
> Subsequent application layers should maintain separate state management.