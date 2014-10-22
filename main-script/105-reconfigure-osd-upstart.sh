#!/bin/bash

##### reconfigure osd so can be managed by upstart properly

# modify ceph.conf in primary controller only
# see output 'ceph osd tree' to know where osd exist
# set noout so ceph not rebalancing data while maintenence

ssh node-1 "ceph osd set noout"
ssh node-1 "bash /root/script/osd-print.sh"

# stop osd in ceph node from primary controller node

ssh node-1 "bash /root/script/osd-stop.sh"

# start properly using upstart in ceph node

CEPH=$( fuel node | grep -e ceph | awk '//{print $1}' );
for i in $CEPH; do
	ssh node-$i "stop ceph-all && start ceph-all"
done

# unset noout and make sure ceph cluster in health state

ssh node-1 "ceph osd unset noout"

##### actually, proper way to reconfigure is not as desribed before
##### we must stop all osd in one node,
##### then start all osd in that node,
##### after make sure all osd in one node up, we can move to other node