#!/bin/bash
ADMIN_PASSWORD="OPENSTACK_CREDENTIAL"
export OS_SERVICE_TOKEN="OPENSTACK_CREDENTIAL"
export OS_SERVICE_ENDPOINT="http://localhost:35357/v2.0"
#
KEYSTONE_HOST="CONTROLLER_NODE_EXT_IP"
KEYSTONE_HOST_INTERNAL="CONTROLLER_NODE_MGMT_IP"
# Shortcut function to get a newly generated ID
function get_field() {
	while read data; do
		if [ "$1" -lt 0 ]; then
			field="(\$(NF$1))"
		else
			field="\$$(($1 + 1))"
		fi
		echo "$data" | awk -F'[ \t]*\\|[ \t]*' "{print $field}"
	done
}
# Users
keystone user-create --name=neutron --pass=${ADMIN_PASSWORD} --email=neutron@example.com
# Roles
# Add Roles to Users in Tenants
keystone user-role-add --user=neutron --tenant=service --role=admin
# Create services
IDENTITY_SERVICE=$(keystone service-create --name=neutron --type=network  --description="OpenStack Networking Service" | grep " id " | get_field 2)
# Create endpoints
keystone endpoint-create --service-id=$IDENTITY_SERVICE --publicurl="http://$KEYSTONE_HOST:9696" --adminurl="http://$KEYSTONE_HOST_INTERNAL:9696" --internalurl="http://$KEYSTONE_HOST_INTERNAL:9696"
