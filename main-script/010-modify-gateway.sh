#!/bin/bash

##### modify default gateway for compute and ceph node
##### change to internal router CMP (192.168.101.1)
##### since MOS 5.1, we can set IP Public to controller & zabbix node only
##### Actually, compute node also doesn't need br-storage

COMP_CEPH=$( fuel node | grep -e compute -e ceph | awk '//{print $1}' );
for i in $COMP_CEPH; do
	ssh node-$i "sed -i '/gateway/d' /etc/network/interfaces.d/ifcfg-br-fw-admin"
	ssh node-$i "echo 'gateway 192.168.101.1' >> /etc/network/interfaces.d/ifcfg-br-mgmt"
	ssh node-$i "route delete default && route add default gw 192.168.101.1"
done