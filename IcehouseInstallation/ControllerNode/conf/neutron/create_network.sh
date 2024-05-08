#!/bin/bash
TENANT_NAME="openstack"
TENANT_NETWORK_NAME="openstack-net"
TENANT_SUBNET_NAME="${TENANT_NETWORK_NAME}-subnet"
TENANT_ROUTER_NAME="openstack-router"
FIXED_RANGE="NEUTRON_FIXED_RANGE"
NETWORK_GATEWAY="NEUTRON_NETWORK_GATEWAY"

PUBLIC_GATEWAY="NEUTRON_PUBLIC_GATEWAY"
PUBLIC_RANGE="NEUTRON_PUBLIC_RANGE"
PUBLIC_START="NEUTRON_PUBLIC_START"
PUBLIC_END="NEUTRON_PUBLIC_END"

TENANT_ID=$(keystone tenant-list | grep " $TENANT_NAME " | awk '{print $2}')
TENANT_NET_ID=$(neutron net-create --tenant_id $TENANT_ID $TENANT_NETWORK_NAME --provider:network_type gre --provider:segmentation_id 1 | grep " id " | awk '{print $4}')
TENANT_SUBNET_ID=$(neutron subnet-create --tenant_id $TENANT_ID --ip_version 4 --name $TENANT_SUBNET_NAME $TENANT_NET_ID $FIXED_RANGE --gateway $NETWORK_GATEWAY --dns_nameservers list=true 8.8.8.8 | grep " id " | awk '{print $4}')
ROUTER_ID=$(neutron router-create --tenant_id $TENANT_ID $TENANT_ROUTER_NAME | grep " id " | awk '{print $4}')
neutron router-interface-add $ROUTER_ID $TENANT_SUBNET_ID

neutron net-create public --router:external=True

neutron subnet-create --ip_version 4 --gateway $PUBLIC_GATEWAY public $PUBLIC_RANGE --allocation-pool start=$PUBLIC_START,end=$PUBLIC_END --disable-dhcp --name public-subnet

neutron router-gateway-set ${TENANT_ROUTER_NAME} public

