#!/bin/bash

##### reconfigure osd so can be managed by upstart properly

# modify ceph.conf in primary controller only
# see output 'ceph osd tree' to know where osd exist
# set noout so ceph not rebalancing data while maintenence

ssh node-1 "ceph osd set noout"
ssh node-1 "bash /root/script/osd-print.sh"

# stop osd in ceph node from primary controller node
# start properly using upstart in ceph node

CEPH=$( fuel node | grep -e ceph | awk '//{print $1}' );
for i in $CEPH; do
	ssh node-$i "bash /root/script/osd-get-id.sh"
		ID=$(ssh node-$i cat /root/part.txt)
		for x in $ID; do
			ssh node-1 service ceph -a stop osd.$x
		done
	ssh node-$i "stop ceph-all && start ceph-all"
done

# revert ceph.conf to original config
# unset noout and make sure ceph cluster in health state

ssh node-1 "rm -f /etc/ceph/ceph.conf && mv /etc/ceph/ceph.conf.bak /etc/ceph/ceph.conf"
ssh node-1 "ceph osd unset noout"