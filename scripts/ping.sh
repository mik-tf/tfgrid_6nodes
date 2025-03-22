#!/bin/bash

declare -A mycelium_ips=(
    ["node_0"]="42f:208e:987:118e:ff0f:89b4:bacb:e678"
    ["node_1"]="451:39dd:daf9:1c4f:ff0f:bc:c1e3:fb62"
    ["node_2"]="59e:dac6:610a:681d:ff0f:667f:8bd3:4ab7"
    ["node_3"]="4ed:302b:6602:c6b8:ff0f:7f96:9811:8a48"
    ["node_4"]="420:b71c:3b5a:e0dc:ff0f:b756:acc:90c5"
    ["node_5"]="546:cd0:ef75:3815:ff0f:ef34:481e:1504"
)

declare -A wireguard_ips=(
    ["node_0"]="10.1.3.2"
    ["node_1"]="10.1.4.2"
    ["node_2"]="10.1.5.2"
    ["node_3"]="10.1.6.2"
    ["node_4"]="10.1.7.2"
    ["node_5"]="10.1.8.2"
)

declare -A public_ips=(
    ["node_3"]="185.69.167.158"
    ["node_4"]="185.69.166.173"
    ["node_5"]="185.69.167.196"
)

for node in "${!mycelium_ips[@]}"; do
    echo "=== Pinging Mycelium (${node}) ${mycelium_ips[$node]} ==="
    ping6 -c 5 "${mycelium_ips[$node]}"
    
    echo -e "\n=== Pinging WireGuard (${node}) ${wireguard_ips[$node]} ==="
    ping -c 5 "${wireguard_ips[$node]}"
    
    if [ "${public_ips[$node]+exists}" ]; then
        echo -e "\n=== Pinging Public (${node}) ${public_ips[$node]} ==="
        ping -c 5 "${public_ips[$node]}"
    fi
    
    echo -e "\n"
done