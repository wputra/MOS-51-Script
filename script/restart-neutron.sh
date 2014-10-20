#!/bin/sh

for i in $( initctl list | grep running | grep -e neutron | awk '//{print $1}' ); do
service $i restart
done
