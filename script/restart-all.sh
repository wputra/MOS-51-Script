#!/bin/sh

for i in $( initctl list | grep running | grep -e nova -e cinder -e glance -e neutron -e heat -e ceilometer -e keystone | awk '//{print $1}' ); do
service $i restart
done
