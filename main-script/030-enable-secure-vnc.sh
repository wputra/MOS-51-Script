#!/bin/bash

###### enable secure vnc console and restart nova in controller node

CONT=$( fuel node | grep -e controller | awk '//{print $1}' );
for i in $CONT; do
	rsync -avz /root/cbncloudstack node-$i:/etc/ssl
	ssh node-$i "sed -i '2issl_only=true' /etc/nova/nova.conf"
	ssh node-$i "sed -i '3icert=/etc/ssl/cbncloudstack/wildcard.crt' /etc/nova/nova.conf"
	ssh node-$i "sed -i '4ikey=/etc/ssl/cbncloudstack/wildcard.key' /etc/nova/nova.conf"
	ssh node-$i "bash /root/script/restart-nova.sh"
done
	
# update vnc setting and restart nova in compute node

COMP=$( fuel node | grep -e compute | awk '//{print $1}' );
for i in $COMP; do
	ssh node-$i "sed -i 's|start_guests_on_host_boot|resume_guests_state_on_host_boot|g' /etc/nova/nova.conf"
	ssh node-$i "sed -i 's|http://103.24.12.2|https://indigo.cbncloudstack.com|g' /etc/nova/nova.conf"
	ssh node-$i "bash /root/script/restart-nova.sh"
done