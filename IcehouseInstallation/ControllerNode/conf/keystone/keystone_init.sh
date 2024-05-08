#!/bin/bash
ADMIN_PASSWORD="OPENSTACK_CREDENTIAL"
DEMO_PASSWORD="OPENSTACK_CREDENTIAL"
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
# Tenants
ADMIN_TENANT=$(keystone tenant-create --name=admin | grep " id " | get_field 2)
DEMO_TENANT=$(keystone tenant-create --name=openstack | grep " id " | get_field 2)
SERVICE_TENANT=$(keystone tenant-create --name=service | grep " id " | get_field 2)
# Users
ADMIN_USER=$(keystone user-create --name=admin --pass="$ADMIN_PASSWORD" --email=admin@domain.com | grep " id " | get_field 2)
DEMO_USER=$(keystone user-create --name=openstack --pass="$DEMO_PASSWORD" --email=openstack@domain.com --tenant-id=$DEMO_TENANT | grep " id " | get_field 2)
# Roles
ADMIN_ROLE=$(keystone role-create --name=admin | grep " id " | get_field 2)
#MEMBER_ROLE=$(keystone role-create --name=Member | grep " id " | get_field 2)
# Add Roles to Users in Tenants
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $ADMIN_TENANT
keystone user-role-add --tenant-id $DEMO_TENANT --user-id $DEMO_USER --role-id $ADMIN_ROLE
# Create services
IDENTITY_SERVICE=$(keystone service-create --name=keystone --type=identity --description='OpenStack Identity' | grep " id " | get_field 2)
# Create endpoints
keystone endpoint-create --service-id=$IDENTITY_SERVICE --publicurl="http://$KEYSTONE_HOST:5000/v2.0" --adminurl="http://$KEYSTONE_HOST_INTERNAL:35357/v2.0" --internalurl="http://$KEYSTONE_HOST_INTERNAL:5000/v2.0"
