#!/bin/bash

##### patch keystone based on this review: https://review.openstack.org/#/c/42967/
##### backport in icehouse based on this bug: https://bugs.launchpad.net/openstack-manuals/+bug/1217357
##### patch file can be found in here: https://launchpadlibrarian.net/179898469/keystone-multiple-workers.icehouse-backport.inplace.patch
##### NOTE: nova, glance and neutron already have 32 worker by default (auto)
##### 32 is number of cpu in controller node, change this value to suit your environment

# execute patch.sh in controller node to overwrite existing keystone file

CONT=$( fuel node | grep -e controller | awk '//{print $1}' );
for i in $CONT; do
	ssh node-$i "bash /root/script/patch-keystone.sh"
done