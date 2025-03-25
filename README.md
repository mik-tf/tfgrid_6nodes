<h1> ThreeFold Grid 6-Node Open Tofu Deployment</h1>

<h2>Table of Contents</h2>

- [Overview](#overview)
- [Quick Deployment](#quick-deployment)
- [Key Components](#key-components)
  - [Network Architecture](#network-architecture)
  - [Node Configuration](#node-configuration)
- [Detailed Deployment Steps](#detailed-deployment-steps)
  - [1. Initialize Deployment](#1-initialize-deployment)
  - [2. Deploy Everything](#2-deploy-everything)
  - [3. Manual Deployment Options](#3-manual-deployment-options)
- [Customization Guide](#customization-guide)
  - [Network Testing](#network-testing)
  - [Resource Profiles](#resource-profiles)
  - [OpenEdX Configuration](#openedx-configuration)
- [Operational Management](#operational-management)
  - [Infrastructure Scaling](#infrastructure-scaling)
  - [Secure Teardown](#secure-teardown)
- [License](#license)
- [Clean Up Tofu](#clean-up-tofu)

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
- High-availability Kubernetes cluster
- OpenEdX platform deployment with Tutor

This project is designed as the essential first layer for building Kubernetes clusters, distributed storage systems, or HA application deployments.

## Quick Deployment

For a complete end-to-end deployment including infrastructure, Kubernetes, and OpenEdX:

```bash
# Deploy with default domain (onlineschool.com)
bash scripts/deploy.sh

# Deploy with custom domain
bash scripts/deploy.sh yourdomain.com
```

This single command will:
1. Deploy the infrastructure with Tofu
2. Configure WireGuard networking
3. Deploy Kubernetes across all 6 nodes
4. Deploy OpenEdX with Tutor using your domain
5. Provide DNS configuration guidance

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

## Detailed Deployment Steps

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

### 2. Deploy Everything

Run the deployment script with an optional custom domain:

```bash
# Deploy with default domain (onlineschool.com)
bash scripts/deploy.sh

# Deploy with custom domain
bash scripts/deploy.sh yourdomain.com
```

The script will automatically:
- Deploy the infrastructure with Tofu
- Set up WireGuard networking
- Generate the Ansible inventory
- Deploy Kubernetes across all nodes
- Deploy OpenEdX with Tutor
- Configure DNS settings for your domain

After deployment completes, you'll see:
- OpenEdX URL: https://yourdomain.com
- Studio URL: https://studio.yourdomain.com
- Admin credentials

### 3. Manual Deployment Options

If you prefer to run steps individually:

```bash
# Deploy infrastructure only
cd deployment
tofu init && tofu apply -auto-approve

# Set up WireGuard
bash scripts/wg.sh

# Generate inventory
bash scripts/generate-inventory.sh

# Deploy Kubernetes only
cd kubernetes
ansible-playbook -i inventory.ini k8s-cluster.yml --tags common,control,worker

# Deploy OpenEdX only with custom domain
ansible-playbook -i inventory.ini k8s-cluster.yml --tags tutor -e "openedx_domain=yourdomain.com"

# Configure DNS
bash scripts/configure-dns.sh yourdomain.com
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

### OpenEdX Configuration

Customize OpenEdX deployment by passing parameters:

```bash
# Using deploy.sh with custom domain
bash scripts/deploy.sh yourdomain.com

# Using Ansible directly with custom domain and admin password
ansible-playbook -i inventory.ini k8s-cluster.yml --tags tutor \
  -e "openedx_domain=yourdomain.com" \
  -e "admin_password=your_secure_password"
```

You can also edit the default values in `kubernetes/k8s-cluster.yml`:

```yaml
vars:
  openedx_domain: "{{ openedx_domain | default('onlineschool.com') }}"  # Default domain
  admin_password: "{{ admin_password | default('securepassword') }}"    # Default password
```

Additional Tutor configurations can be added to the `tutor` role:

```bash
# Edit Tutor configuration
vi kubernetes/roles/tutor/tasks/main.yml

# Apply changes
ansible-playbook -i inventory.ini k8s-cluster.yml --tags tutor
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

## License

**Apache 2.0** - Full text in [LICENSE](./LICENSE) 

## Clean Up Tofu

``` 
bash scripts/cleantf.sh
```

---

> **Important**: This deployment establishes the infrastructure layer only.  
> Subsequent application layers should maintain separate state management.
> Consult the [docs](./docs/ansible_post_deployment.md) for more information.