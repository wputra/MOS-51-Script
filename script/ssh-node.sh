#!/bin/sh

for i in $( fuel node | grep -e compute | awk '//{print $1}' ); do
echo node-$i
#rsync -avz /root/script node-$i:/root/
#rsync -avz /root/patch node-$i:/root/
#rsync -avz sources.list node-$i:/etc/apt/
#ssh node-$i "sed -i 's|/var/lib/nova:/bin/false|/var/lib/nova:/bin/bash|g' /etc/passwd"
#ssh node-$i "ssh 192.168.101.20 hostname"
#ssh node-$i "dpkg -i /root/patch/python-oslo.messaging_1.3.0-fuel5.1~mira5_all.deb"
ssh node-$i "bash /root/script/restart.sh"
#ssh node-$i "sed -i '/UserKnownHostsFile/d' /root/.ssh/config"
#ssh node-$i "sed -i '/LogLevel/d' /root/.ssh/config"
#ssh node-$i "echo 'UserKnownHostsFile=/root/.ssh/known_hosts' >> /root/.ssh/config"
#ssh node-$i "echo 'LogLevel=error' >> /root/.ssh/config"
#ssh node-$i "service nova-compute restart"
#ssh node-$i "sed -i '/gateway/d' /etc/network/interfaces.d/ifcfg-br-fw-admin"
#ssh node-$i "echo 'gateway 192.168.101.1' >> /etc/network/interfaces.d/ifcfg-br-mgmt"
#ssh node-$i "route delete default && route add default gw 192.168.101.1"
#ssh node-$i "netstat -rn"
#ssh node-$i "apt-get update && apt-get --only-upgrade install bash"
done
