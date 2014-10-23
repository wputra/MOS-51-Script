#!/bin/bash

##### modify user 'nova' in compute node, so it have shell
##### this step will solve nova resize & migrate failure
##### http://beta.cbncloudstack.com:8080/swift/v1/wasis/resize.png
##### see Mirantis Support ticket no 2948 for detail

COMP=$( fuel node | grep -e compute | awk '//{print $1}' );
for i in $COMP; do
	ssh node-$i "sed -i 's|/var/lib/nova:/bin/false|/var/lib/nova:/bin/bash|g' /etc/passwd"

# modify ssh config for user 'nova' in compute node, so it will not throw warning anymore
	ssh node-$i "bash /root/script/nova-resize.sh"
done