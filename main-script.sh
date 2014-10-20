#!/bin/bash


##### intial preparation
##### store all needed file under /root directory

# define node role
ALL=$( fuel node | grep -e compute -e ceph -e controller | awk '//{print $1}' );
CONT=$( fuel node | grep -e controller | awk '//{print $1}' );
COMP=$( fuel node | grep -e compute | awk '//{print $1}' );
CEPH=$( fuel node | grep -e ceph | awk '//{print $1}' );

# rsync patch & script folder to all node
for i in $ALL; do
	rsync -avz patch node-$i:/root/
	rsync -avz script node-$i:/root/
done


##### patch keystone based on this review: https://review.openstack.org/#/c/42967/
##### backport in icehouse based on this bug: https://bugs.launchpad.net/openstack-manuals/+bug/1217357
##### patch file can be found in here: https://launchpadlibrarian.net/179898469/keystone-multiple-workers.icehouse-backport.inplace.patch
##### increase worker for keystone, cinder, heat and ceilometer
##### and then restart the associated service 
##### NOTE: nova, glance and neutron already have 32 worker by default (auto)
##### 32 is number of cpu in controller node

# execute patch.sh in controller node to overwrite keystone and enable multiple worker
for i in $CONT; do
	ssh node-$i "bash /root/script/patch-keystone.sh"

# add keystone and cinder worker under [DEFAULT] directive in controller
	ssh node-$i "sed -i '2ipublic_workers=16' /etc/keystone/keystone.conf"
	ssh node-$i "sed -i '3iadmin_workers=16' /etc/keystone/keystone.conf"
	ssh node-$i "sed -i '2iosapi_volume_workers=32' /etc/cinder/cinder.conf"

# increase worker for heat and ceilometer in controller
	ssh node-$i "sed -i 's/workers=0/workers=32/g' /etc/heat/heat.conf"
	ssh node-$i "sed -i 's/#collector_workers=1/collector_workers=32/g' /etc/ceilometer/ceilometer.conf"
	ssh node-$i "sed -i 's/#notification_workers=1/notification_workers=32/g' /etc/ceilometer/ceilometer.conf"

# restart all keystone, cinder, heat and ceilometer service in controller
	ssh node-$i "bash /root/script/restart-keystone.sh"
	ssh node-$i "bash /root/script/restart-cinder.sh"
	ssh node-$i "bash /root/script/restart-heat.sh"
	ssh node-$i "bash /root/script/restart-ceilometer.sh"
done



##### reconfigure osd so can be managed by upstart properly
##### SORRY, this step still can't be automated

# modify ceph.conf in primary controller
# see output 'ceph osd tree' to know where osd exist
# you can use this to generate the conf file
# ceph osd tree | awk '/host/{host=$4};/osd/{print "["$3"]\n" "host = "host"\n";}'
[osd.0]
host = node-5

# stop osd in ceph node from primary controller node
# ceph osd tree | awk '/osd/{print $1};'
service ceph -a stop osd.0

# start properly using upstart in ceph node

for i in $CONT; do
	ssh node-$i "stop ceph-all && start ceph-all"
done



##### reconfigure ceph journal to nvme disk
##### in all ceph node
##### SORRY, this step still can't be automated

# make sure nvme partitioned properly
#lsblk | grep nvme | grep 10G

# if not partitioned yet, we must copy partition table
#sgdisk --load-backup=/root/patch/table /dev/nvme0n1
#sgdisk -G /dev/nvme0n1

# we can start to move journal
# set noout flag so ceph cluster not balanced while move journal
ceph osd set noout

# change directory to where osd mounted
# refer to output of 'ceph osd tree' to see osd id
cd /var/lib/ceph/osd/ceph-0/

# stop osd and flush journal
ll && stop ceph-osd id=7 && ceph-osd -i 7 --flush-journal

# remove journal and create symlink to nvme partition
rm -f journal && ln -s /dev/nvme0n1p11 journal && ll

# make journal and start osd again
ceph-osd -i 7 --mkjournal && start ceph-osd id=7

# change directory to next osd id
# always refer to 'ceph osd tree' to see assosiated osd id in particular node
cexd ../ceph-3/

# repeat step to stop osd, flush journal until start osd again for all osd in all ceph node
# make sure no same nvme partition act as journal for more than one osd disk
# every osd must have dedicated partition as journal, one nvme partition for one osd disk

# after all osd have journal in ssd, unset noout flag
ceph osd unset noout

# monitor ceph health & status
watch ceph -s

# bechmark osd pool, make sure ceph pool can be writed without loss
rados -p volumes bench 120 write -t 8



##### === commit and split to 'initial' branch ===



##### modify default gateway for compute and ceph node
##### change to internal router CMP (192.168.101.1)
##### since MOS 5.1, we can set IP Public to controller & zabbix node only
##### Actually, compute node also doesn't need br-storage

for i in $COMP; do
	ssh node-$i "sed -i '/gateway/d' /etc/network/interfaces.d/ifcfg-br-fw-admin"
	ssh node-$i "echo 'gateway 192.168.101.1' >> /etc/network/interfaces.d/ifcfg-br-mgmt"
	ssh node-$i "route delete default && route add default gw 192.168.101.1"
done

for i in $CEPH; do
	ssh node-$i "sed -i '/gateway/d' /etc/network/interfaces.d/ifcfg-br-fw-admin"
	ssh node-$i "echo 'gateway 192.168.101.1' >> /etc/network/interfaces.d/ifcfg-br-mgmt"
	ssh node-$i "route delete default && route add default gw 192.168.101.1"
done



##### update bash to against shellshock bug in all node
##### this bug actually have no effect to MOS environment, since no bash-based CGIs are used
##### but still, better safe than sorry
##### WARNING WARNING WARNING : NEVER, EVER, do "apt-get upgrade", since it will upgrade ALL packages

for i in $ALL; do
	rsync -avz script/sources.list node-$i:/etc/apt/
	ssh node-$i "apt-get update && apt-get --only-upgrade install bash"
done



##### modify resource allocation ratio to suit our needs

for i in $CONT; do
	ssh node-$i "sed -i 's/ram_allocation_ratio=1.0/ram_allocation_ratio=1.1/g' /etc/nova/nova.conf"
	ssh node-$i "sed -i 's/cpu_allocation_ratio=8.0/cpu_allocation_ratio=4.0/g' /etc/nova/nova.conf"
	ssh node-$i "bash /root/script/restart-nova.sh"
done	



##### modify user 'nova' in compute node, so it have shell
##### this step will solve nova resize & migrate failure
##### see Mirantis Support ticket no 2948 for detail

for i in $COMP; do
	ssh node-$i "sed -i 's|/var/lib/nova:/bin/false|/var/lib/nova:/bin/bash|g' /etc/passwd"

# modify ssh config for user 'nova' in compute node, so it will not throw warning anymore
	ssh node-$i "bash /root/script/nova-resize.sh"
done



##### update oslo.messaging in controller and compute node to increase openstack service performance
##### this step will solve reconnecting log in nova, cinder and other.
##### see Mirantis Support ticket no 2950 for detail
##### make sure all openstack service can be started again successfully, :-) state

for i in $COMP; do
	ssh node-$i "dpkg -i /root/patch/python-oslo.messaging_1.3.0-fuel5.1~mira5_all.deb"
	ssh node-$i "bash /root/script/restart-all.sh"
done

for i in $CONT; do
	ssh node-$i "dpkg -i /root/patch/python-oslo.messaging_1.3.0-fuel5.1~mira5_all.deb"
	ssh node-$i "bash /root/script/restart-all.sh"
done

# restart openstack service that managed by pacemaker in primary controller
# see output of 'crm status' to make sure openstack service restarted successfully
# SORRY, this step still can't be automated

crm resource restart p_heat-engine
crm resource restart p_ceilometer-alarm-evaluator
crm resource restart p_ceilometer-agent-central
crm resource restart clone_p_neutron-metadata-agent
crm resource restart clone_p_neutron-plugin-openvswitch-agent
crm resource restart p_neutron-dhcp-agent
crm resource restart p_neutron-l3-agent



##### modify neutron value to openstack deafult
##### openstack default value will lighten neutron load compared to Mirantis value

for i in $CONT; do
	ssh node-$i "sed -i 's/dhcp_lease_duration = 120/dhcp_lease_duration = 86400/g' /etc/neutron/neutron.conf"
done

# restart neutron service that managed by pacemaker in primary controller
# see output of 'crm status' to make sure openstack service restarted successfully
# SORRY, this step still can't be automated

crm resource restart p_neutron-dhcp-agent



##### enable LBaaS in controller node
##### MAKE SURE to use package from nailgun repo

for i in $CONT; do
	rsync -avz script/sources.list.nailgun node-$i:/etc/apt/sources.list
	ssh node-$i "apt-get update && apt-get install neutron-lbaas-agent && service neutron-lbaas-agent stop"
	ssh node-$i "cp /etc/init/neutron-l3-agent.override /etc/init/neutron-lbaas-agent.override"

# add service_plugins in /etc/neutron/neutron.conf
	ssh node-$i "sed -i 's/.MeteringPlugin/.MeteringPlugin,neutron.services.loadbalancer.plugin.LoadBalancerPlugin/g' /etc/neutron/neutron.conf"

# modify /etc/neutron/lbaas_agent.ini
	ssh node-$i "sed -i '2iuse_namespaces = True' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# periodic_interval = 10/periodic_interval = 10/g' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# interface_driver = neutron./interface_driver = neutron./g' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# device_driver = neutron./device_driver = neutron./g' /etc/neutron/lbaas_agent.ini"
	ssh node-$i "sed -i 's/# user_group = nogroup/user_group = nogroup/g' /etc/neutron/lbaas_agent.ini"

# modify enable_lb in /etc/openstack-dashboard/local_settings.py to 'True' value
	ssh node-$i "sed -i 's/enable_lb': False/enable_lb': True/g' /etc/neutron/lbaas_agent.ini"

# modify /etc/apache2/conf.d/zzz_performance_tuning.conf to proper value
# so apache doesnt thow warning
	ssh node-$i "sed -i 's/6436/6425/g' /etc/apache2/conf.d/zzz_performance_tuning.conf"

# restart service in controller node
	ssh node-$i "apachectl graceful"
	ssh node-$i "bash /root/script/restart-neutron.sh"
done

# start lbaas agent on specific node only
ssh node-2 "service neutron-lbaas-agent start"



###### enable secure vnc console and restart nova in controller node

for i in $CONT; do
	rsync -avz /root/cbncloudstack node-$i:/etc/ssl
	ssh node-$i "sed -i '2issl_only=true' /etc/nova/nova.conf"
	ssh node-$i "sed -i '3icert=/etc/ssl/cbncloudstack/wildcard.crt' /etc/nova/nova.conf"
	ssh node-$i "sed -i '4ikey=/etc/ssl/cbncloudstack/wildcard.key' /etc/nova/nova.conf"
	ssh node-$i "bash /root/script/restart-nova.sh"
done
	
# update vnc setting and restart nova in compute node

for i in $COMP; do
	ssh node-$i "sed -i 's|start_guests_on_host_boot|resume_guests_state_on_host_boot|g' /etc/nova/nova.conf"
	ssh node-$i "sed -i 's|http://103.24.12.2|https://indigo.cbncloudstack.com|g' /etc/nova/nova.conf"
	ssh node-$i "bash /root/script/restart-nova.sh"
done
