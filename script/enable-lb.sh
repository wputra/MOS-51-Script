#!/bin/sh

sed -i "s/'enable_lb': False/'enable_lb': True/g" /etc/openstack-dashboard/local_settings.py