###############################################################Compute_Node_IP###################
#
#	        Openstack automated installation tool   2014-4
#
#	Usage:
# Install Havana Openstack on Ubuntu12.04 .
# Steps:
# 1. Config MANAGENETWORK_IP of the server which openstack will be installed on.
# 2. exec ./install.sh
# 
# Arguments:
# 
# 
# Configuration:
# 
# 
# Logs:
# 
# 	openstack-install.log
# 
####################################################################################
########################################
#
# Parameters
#
########################################
CONTROLLER_NODE_MGMT_IP=""
CONTROLLER_NODE_EXT_IP=""
NETWORK_NODE_MGMT_IP=""
NETWORK_NODE_EXT_IP=""
NETWORK_NODE_DATA_IP=""
COMPUTE_NODE_MGMT_IP=""
COMPUTE_NODE_DATA_IP=""

OPENSTACK_CREDENTIAL="password"
MYSQL_PASSWD="password"
RABBIT_PASSWD="password"

INSTALL_HOME=`pwd`
CONF_DIR="${INSTALL_HOME}/conf"

function apt() {
    apt-get -y --force-yes $@
}

function replace_params(){
	DIR=$1
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/CONTROLLER_NODE_MGMT_IP/${CONTROLLER_NODE_MGMT_IP}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/CONTROLLER_NODE_EXT_IP/${CONTROLLER_NODE_EXT_IP}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/NETWORK_NODE_MGMT_IP/${NETWORK_NODE_MGMT_IP}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/NETWORK_NODE_EXT_IP/${NETWORK_NODE_EXT_IP}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/NETWORK_NODE_DATA_IP/${NETWORK_NODE_DATA_IP}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/COMPUTE_NODE_MGMT_IP/${COMPUTE_NODE_MGMT_IP}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/COMPUTE_NODE_DATA_IP/${COMPUTE_NODE_DATA_IP}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/OPENSTACK_CREDENTIAL/${OPENSTACK_CREDENTIAL}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/MYSQL_PASSWD/${MYSQL_PASSWD}/g"
	find ${DIR} -type f -name '*' -print0 | xargs -0 sed -i "s/RABBIT_PASSWD/${RABBIT_PASSWD}/g"
}

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
########################################
#
# Common Service Configuration
#
########################################
RC_FILE="/root/openrc"

########################################
#
# Nova Configuration
#
########################################
NOVA_CONF_DIR="/etc/nova"
NOVA_LIBVIRT_TYPE="qemu"
########################################
#
# Neutron Configuration
#
########################################
NEUTRON_CONF_DIR="/etc/neutron"
########################################
#
# Cinder Configuration
#
########################################
CINDER_CONF_DIR="/etc/cinder"
CINDER_PYSICAL_VOLUME="/dev/sdb"

####################################################################################
#
# Common Installation
#
####################################################################################

common_service_install(){
	#Install tools
	#apt install python-software-properties
	#add-apt-repository cloud-archive:havana
	apt update 

	apt install ntp
	
	service ntp restart
	
	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	
	apt install python-mysqldb

        echo "export OS_TENANT_NAME=admin" > ${RC_FILE}
        echo "export OS_USERNAME=admin" >> ${RC_FILE}
        echo "export OS_PASSWORD=${OPENSTACK_CREDENTIAL}" >> ${RC_FILE}
        echo "export OS_AUTH_URL=\"http://${CONTROLLER_NODE_MGMT_IP}:5000/v2.0/\"" >> ${RC_FILE}
        echo "export OS_SERVICE_ENDPOINT=\"http://${CONTROLLER_NODE_MGMT_IP}:35357/v2.0\"" >> ${RC_FILE}
        echo "export OS_SERVICE_TOKEN=${OPENSTACK_CREDENTIAL}" >> ${RC_FILE}
        source ${RC_FILE}
}

####################################################################################
#
# Nova Installation
#
####################################################################################

nova_install(){
	apt install nova-compute nova-compute-kvm pm-utils libvirt-bin
	#apt install python-guestfs
	#dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-$(uname -r)
	replace_params ${CONF_DIR}/nova
	cp -rf ${CONF_DIR}/nova/* ${NOVA_CONF_DIR}/

	sed -i "s/\(libvirt_type *= *\).*/\1${NOVA_LIBVIRT_TYPE}/" ${NOVA_CONF_DIR}/nova-compute.conf
	
	chown -R nova:nova ${NOVA_CONF_DIR}	
	service libvirt-bin restart	
	service nova-compute restart
}

####################################################################################
#
# Neutron Installation
#
####################################################################################

neutron_install(){
	apt install neutron-common neutron-plugin-ml2 neutron-plugin-openvswitch-agent openvswitch-datapath-dkms
	replace_params ${CONF_DIR}/neutron
	cp -rf ${CONF_DIR}/neutron/* ${NEUTRON_CONF_DIR}/
	chown -R neutron:neutron ${NEUTRON_CONF_DIR}

	SERVICE_TENANT=$(keystone tenant-get service | grep " id " | get_field 2)
	sed -i "s/\(nova_admin_tenant_id *= *\).*/\1${SERVICE_TENANT}/" ${NEUTRON_CONF_DIR}/neutron.conf
	
        service openvswitch-switch restart
	ovs-vsctl add-br br-int
	service neutron-plugin-openvswitch-agent restart
}

####################################################################################
#
# Cinder Installation
#
####################################################################################

cinder_install(){
	apt install lvm2
	pvcreate ${CINDER_PYSICAL_VOLUME}
	vgcreate cinder-volumes ${CINDER_PYSICAL_VOLUME}
	apt install cinder-volume
	replace_params ${CONF_DIR}/cinder
	cp -rf ${CONF_DIR}/cinder/* ${CINDER_CONF_DIR}/
	chown -R cinder:cinder ${CINDER_CONF_DIR}	
	service cinder-volume restart
	service tgt restart
}

########################################
# Main
#    execute main process
#
########################################
common_service_install
nova_install
cinder_install
neutron_install
exit 0
