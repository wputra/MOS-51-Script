#!/bin/bash

##### increase worker for keystone, cinder, heat and ceilometer
##### and then restart the associated service 

CONT=$( fuel node | grep -e controller | awk '//{print $1}' );
for i in $CONT; do
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