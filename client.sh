#!/bin/bash
read -r -a array <<< $(ip addr |grep 192.168.1.17)
cat >> /etc/sysconfig/network-scripts/ifcfg-${array[7]} << EOF
GATEWAY=192.168.1.100
DNS1=192.168.1.17
DNS2=8.8.8.8
EOF
sed -i 's/search lab.local/search lab.local\nnameserver 192.168.1.17\nnameserver 8.8.8.8/g' /etc/resolv.conf
