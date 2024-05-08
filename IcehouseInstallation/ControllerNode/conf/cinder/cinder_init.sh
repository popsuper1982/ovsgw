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
keystone user-create --name=cinder --pass=${ADMIN_PASSWORD} --email=cinder@example.com
# Roles
# Add Roles to Users in Tenants
keystone user-role-add --user=cinder --tenant=service --role=admin
# Create services
IDENTITY_SERVICE=$(keystone service-create --name=cinder --type=volume  --description="Cinder Volume Service" | grep " id " | get_field 2)
# Create endpoints
keystone endpoint-create --service-id=$IDENTITY_SERVICE --publicurl="http://$KEYSTONE_HOST:8776/v1/%(tenant_id)s" --adminurl="http://$KEYSTONE_HOST_INTERNAL:8776/v1/%(tenant_id)s" --internalurl="http://$KEYSTONE_HOST_INTERNAL:8776/v1/%(tenant_id)s"
IDENTITY_SERVICE2=$(keystone service-create --name=cinderv2 --type=volumev2  --description="Cinder Volume Service V2" | grep " id " | get_field 2)
# Create endpoints
keystone endpoint-create --service-id=$IDENTITY_SERVICE2 --publicurl="http://$KEYSTONE_HOST:8776/v2/%(tenant_id)s" --adminurl="http://$KEYSTONE_HOST_INTERNAL:8776/v2/%(tenant_id)s" --internalurl="http://$KEYSTONE_HOST_INTERNAL:8776/v2/%(tenant_id)s"

