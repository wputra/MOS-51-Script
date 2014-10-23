#!/bin/bash

##### update oslo.messaging in controller and compute node to increase openstack service performance
##### this step will solve reconnecting amqp log in nova, cinder and other.
##### see Mirantis Support ticket no 2950 for detail
##### make sure all openstack service can be started again successfully, :-) state

COMP_CONT=$( fuel node | grep -e compute -e controller | awk '//{print $1}' );
for i in $COMP_CONT; do
	ssh node-$i "dpkg -i /root/patch/python-oslo.messaging_1.3.0-fuel5.1~mira5_all.deb"
	ssh node-$i "bash /root/script/restart-all.sh"
done

# restart openstack service that managed by pacemaker in primary controller
# see output of 'crm status' to make sure openstack service restarted successfully
# make sure metadata service in qrouter running properly

ssh node-1 "crm resource restart p_heat-engine"
ssh node-1 "crm resource restart p_ceilometer-alarm-evaluator"
ssh node-1 "crm resource restart p_ceilometer-agent-central"
ssh node-1 "crm resource restart clone_p_neutron-metadata-agent"
ssh node-1 "crm resource restart clone_p_neutron-plugin-openvswitch-agent"
ssh node-1 "crm resource restart p_neutron-dhcp-agent"
ssh node-1 "crm resource restart p_neutron-l3-agent"