#!/bin/bash

##### modify neutron value to openstack deafult
##### openstack default value will lighten neutron load compared to Mirantis value

CONT=$( fuel node | grep -e controller | awk '//{print $1}' );
for i in $CONT; do
	ssh node-$i "sed -i 's/dhcp_lease_duration = 120/dhcp_lease_duration = 86400/g' /etc/neutron/neutron.conf"
done

# restart neutron service that managed by pacemaker in primary controller
# see output of 'crm status' to make sure openstack service restarted successfully
# SORRY, this step still can't be automated

ssh node-1 "crm resource restart p_neutron-dhcp-agent"