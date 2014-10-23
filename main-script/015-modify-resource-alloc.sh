#!/bin/bash

##### modify resource allocation ratio to suit our needs
##### based on openstack docs, we can oversubscibe CPU up to 4 times
##### and RAM up to 1,5 times

CONT=$( fuel node | grep -e controller | awk '//{print $1}' );
for i in $CONT; do
	ssh node-$i "sed -i 's/ram_allocation_ratio=1.0/ram_allocation_ratio=1.1/g' /etc/nova/nova.conf"
	ssh node-$i "sed -i 's/cpu_allocation_ratio=8.0/cpu_allocation_ratio=4.0/g' /etc/nova/nova.conf"
	ssh node-$i "bash /root/script/restart-nova.sh"
done