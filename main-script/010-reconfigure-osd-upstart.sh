#!/bin/bash

##### reconfigure osd so can be managed by upstart properly

# modify ceph.conf in primary controller only
# see output 'ceph osd tree' to know where osd exist

ssh node-1 "bash /root/script/osd-print.sh"

# stop osd in ceph node from primary controller node

ssh node-1 "bash /root/script/osd-stop.sh"

# start properly using upstart in ceph node

CEPH=$( fuel node | grep -e ceph | awk '//{print $1}' );
for i in $CEPH; do
	ssh node-$i "stop ceph-all && start ceph-all"
done

# revert ceph.conf in primary controller as before

ssh node-1 "sed -i '/osd\./d' /etc/ceph/ceph.conf"
ssh node-1 "sed -i '/host=node/d' /etc/ceph/ceph.conf"