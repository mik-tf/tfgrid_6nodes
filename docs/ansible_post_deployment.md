## Kubernetes Cluster Deployment with Ansible

## Inventory Structure
```bash
[control]
node_0 ansible_host=10.1.3.2  # WireGuard IP
node_1 ansible_host=10.1.4.2
node_2 ansible_host=10.1.5.2

[worker]
node_3 ansible_host=10.1.6.2  # Public IP: 185.69.167.158
node_4 ansible_host=10.1.7.2  # Public IP: 185.69.166.173
node_5 ansible_host=10.1.8.2  # Public IP: 185.69.167.196

[kube_control:children]
control

[kube_node:children]
worker
```

## Deployment Process

1. Generate inventory from the `kubernetes` directory
```
cd ../kubernetes
bash ../scripts/generate-inventory.sh
```

2. Verify connectivity:
```bash
ansible all -m ping
```

3. Run the playbook:
```bash
ansible-playbook k8s-cluster.yml -t common,control,worker
```

## Verification

Check cluster status from node_0:
```bash
ansible -i inventory.ini kube_control -m command -a "kubectl get nodes"
```

Expected output:
```text
NAME     STATUS   ROLES           AGE   VERSION   INTERNAL-IP  
node_0   Ready    control-plane   5m    v1.29.0   10.1.3.2
node_1   Ready    control-plane   4m    v1.29.0   10.1.4.2
node_2   Ready    control-plane   4m    v1.29.0   10.1.5.2
node_3   Ready    <none>          3m    v1.29.0   10.1.6.2
node_4   Ready    <none>          3m    v1.29.0   10.1.7.2
node_5   Ready    <none>          3m    v1.29.0   10.1.8.2
```

## Public Worker Configuration

Add node labels for public workers:
```yaml
- name: Label public workers
  command: |
    kubectl label node {{ inventory_hostname }} \
    tf-grid.io/public-ip={{ public_ips[inventory_hostname] }} \
    topology.kubernetes.io/region=global
  vars:
    public_ips:
      node_3: "185.69.167.158"
      node_4: "185.69.166.173"
      node_5: "185.69.167.196"
  when: inventory_hostname in ['node_3', 'node_4', 'node_5']
```

This Ansible configuration provides:
- Idempotent cluster deployment
- HA control plane with 3 nodes
- Worker nodes with public IP labels
- Calico CNI for networking
- Secure WireGuard-based communication

The next step would be configuring ingress using the worker public IPs and preparing for Open edX Tutor deployment.