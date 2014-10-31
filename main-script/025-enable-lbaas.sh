#!/bin/bash

##### enable LBaaS in controller node
##### MAKE SURE to use package from nailgun repo

CONT=$( fuel node | grep -e controller | awk '//{print $1}' );
for i in $CONT; do
	rsync -avz ../script/sources.list.nailgun node-$i:/etc/apt/sources.list
	ssh node-$i "apt-get update && apt-get install neutron-lbaas-agent && service neutron-lbaas-agent stop"
	ssh node-$i "cp /etc/init/neutron-l3-agent.override /etc/init/neutron-lbaas-agent.override"

# add service_plugins in /etc/neutron/neutron.conf
	ssh node-$i "sed -i 's/.MeteringPlugin/.MeteringPlugin,neutron.services.loadbalancer.plugin.LoadBalancerPlugin/g' /etc/neutron/neutron.conf"

# modify /etc/neutron/lbaas_agent.ini
	ssh node-$i "sed -i '2iuse_namespaces = True' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# periodic_interval = 10/periodic_interval = 10/g' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/g' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# device_driver = neutron./device_driver = neutron./g' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# user_group = nogroup/user_group = nogroup/g' /etc/neutron/lbaas_agent.ini"

# modify enable_lb in /etc/openstack-dashboard/local_settings.py to 'True' value
	ssh node-$i "bash /root/script/enable-lb.sh"

# modify /etc/apache2/conf.d/zzz_performance_tuning.conf to proper value
# so apache doesnt thow warning
	ssh node-$i "sed -i 's/6436/6425/g' /etc/apache2/conf.d/zzz_performance_tuning.conf"

# restart service in controller node
	ssh node-$i "apachectl graceful"
	ssh node-$i "bash /root/script/restart-neutron.sh"
done

# start lbaas agent on specific node only

ssh node-2 "service neutron-lbaas-agent start"