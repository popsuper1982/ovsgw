##################################################################################
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
NEUTRON_FIXED_RANGE="192.168.0.0\/24"
NEUTRON_NETWORK_GATEWAY="192.168.0.1"
NEUTRON_PUBLIC_GATEWAY="16.158.164.1"
NEUTRON_PUBLIC_RANGE="16.158.164.0\/22"
NEUTRON_PUBLIC_START="16.158.165.250"
NEUTRON_PUBLIC_END="16.158.165.254"
OPENSTACK_CREDENTIAL="password"
RC_FILE="/root/openrc"
INSTALL_HOME=`pwd`
CONF_DIR="${INSTALL_HOME}/conf"

########################################
#
# Common Service Configuration
#
########################################
HOSTS_FILE="/etc/hosts"
MYSQL_CONF_DIR="/etc/mysql"
MYSQL_USER="root"
MYSQL_PASSWD="password"
RABBIT_PASSWD="password"
########################################
#
# Keystone Configuration
#
########################################
KEYSTONE_CONF_DIR="/etc/keystone"
KEYSTONE_INIT_FILE="${CONF_DIR}/keystone/keystone_init.sh"
########################################
#
# Glance Configuration
#
########################################

GLANCE_CONF_DIR="/etc/glance"
GLANCE_IMAGE="openstackcirros.img"
GLANCE_INIT_FILE="${CONF_DIR}/glance/glance_init.sh"
########################################
#
# Nova Configuration
#
########################################
NOVA_CONF_DIR="/etc/nova"
NOVA_INIT_FILE="${CONF_DIR}/nova/nova_init.sh"
########################################
#
# Cinder Configuration
#
########################################
CINDER_CONF_DIR="/etc/cinder"
CINDER_INIT_FILE="${CONF_DIR}/cinder/cinder_init.sh"
########################################
#
# Neutron Configuration
#
########################################

NEUTRON_CONF_DIR="/etc/neutron"
NEUTRON_INIT_FILE="${CONF_DIR}/neutron/neutron_init.sh"
NEUTRON_CREATE_NETWORK="${CONF_DIR}/neutron/create_network.sh"

########################################
#
# Horizon Configuration
#
########################################
HORIZON_CONF="/etc/openstack-dashboard/local_settings.py"


function apt() {
    sudo apt-get -y --force-yes $@
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

function replace_network_params(){
	sed -i "s/NEUTRON_FIXED_RANGE/${NEUTRON_FIXED_RANGE}/g" ${NEUTRON_CREATE_NETWORK}
	sed -i "s/NEUTRON_NETWORK_GATEWAY/${NEUTRON_NETWORK_GATEWAY}/g" ${NEUTRON_CREATE_NETWORK}
	sed -i "s/NEUTRON_PUBLIC_GATEWAY/${NEUTRON_PUBLIC_GATEWAY}/g" ${NEUTRON_CREATE_NETWORK}
	sed -i "s/NEUTRON_PUBLIC_RANGE/${NEUTRON_PUBLIC_RANGE}/g" ${NEUTRON_CREATE_NETWORK}
	sed -i "s/NEUTRON_PUBLIC_START/${NEUTRON_PUBLIC_START}/g" ${NEUTRON_CREATE_NETWORK}
	sed -i "s/NEUTRON_PUBLIC_END/${NEUTRON_PUBLIC_END}/g" ${NEUTRON_CREATE_NETWORK}
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
####################################################################################
#
# Common Installation
#
####################################################################################
common_service_install(){
	#Install tools Icehouse is in the main repository for 14.04 - this step is not required.
	#apt install python-software-properties
	#add-apt-repository cloud-archive:icehouse
	apt update 
	
	apt install ntp
	
	service ntp restart

	sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
	
	apt install python-mysqldb mysql-server
	
	mysqladmin -u${MYSQL_USER} password ${MYSQL_PASSWD}
	#sed -i 's/127.0.0.1/0.0.0.0/g' ${MYSQL_CONF_FILE}
	cp -rf ${CONF_DIR}/mysql/* ${MYSQL_CONF_DIR}/
	
	service mysql restart
	mysql_install_db
	mysql_secure_installation
	mysql -u${MYSQL_USER} -p${MYSQL_PASSWD} <<EOF
SET GLOBAL max_connect_errors=10000;
EOF
	
	apt install rabbitmq-server
	sleep 30

	service rabbitmq-server restart
	sleep 30

	rabbitmqctl change_password guest ${RABBIT_PASSWD}
}

####################################################################################
#
# Keystone Installation
#
####################################################################################

keystone_install(){
	apt install keystone python-keystone python-keystoneclient
	replace_params ${CONF_DIR}/keystone
	cp -rf ${CONF_DIR}/keystone/* ${KEYSTONE_CONF_DIR}/
	chown -R keystone:keystone ${KEYSTONE_CONF_DIR}	

	service keystone restart

	mysql -u${MYSQL_USER} -p${MYSQL_PASSWD} <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${MYSQL_PASSWD}';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${MYSQL_PASSWD}';
FLUSH PRIVILEGES;
EOF

	keystone-manage db_sync
	
	echo "export OS_TENANT_NAME=admin" > ${RC_FILE}
	echo "export OS_USERNAME=admin" >> ${RC_FILE}
	echo "export OS_PASSWORD=${OPENSTACK_CREDENTIAL}" >> ${RC_FILE}
	echo "export OS_AUTH_URL=\"http://localhost:5000/v2.0/\"" >> ${RC_FILE}
	echo "export OS_SERVICE_ENDPOINT=\"http://localhost:35357/v2.0\"" >> ${RC_FILE}
	echo "export OS_SERVICE_TOKEN=${OPENSTACK_CREDENTIAL}" >> ${RC_FILE}
	source ${RC_FILE}

	chmod 740 ${KEYSTONE_INIT_FILE}
	${KEYSTONE_INIT_FILE}
}

####################################################################################
#
# Glance Installation
#
####################################################################################

glance_install(){
	apt install glance glance-api glance-registry python-glanceclient glance-common
	replace_params ${CONF_DIR}/glance
	cp -rf ${CONF_DIR}/glance/* ${GLANCE_CONF_DIR}/
        chown -R glance:glance ${GLANCE_CONF_DIR}	

	mysql -u${MYSQL_USER} -p${MYSQL_PASSWD} <<EOF
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${MYSQL_PASSWD}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${MYSQL_PASSWD}';
FLUSH PRIVILEGES;
EOF
	service glance-api restart 
	service glance-registry restart
	
	glance-manage db_sync
	
	chmod 740 ${GLANCE_INIT_FILE}
	${GLANCE_INIT_FILE}
	
	service glance-api restart 
	service glance-registry restart

	glance image-create --is-public=true --disk-format=qcow2 --container-format=bare --name="Cirros" < ${GLANCE_IMAGE}
}

####################################################################################
#
# Nova Installation
#
####################################################################################

nova_install(){
	apt install nova-novncproxy novnc nova-api nova-ajax-console-proxy nova-cert nova-conductor   nova-consoleauth nova-doc nova-scheduler python-novaclient
	replace_params ${CONF_DIR}/nova
	cp -rf ${CONF_DIR}/nova/* ${NOVA_CONF_DIR}/
        chown -R nova:nova ${NOVA_CONF_DIR}

	mysql -u${MYSQL_USER} -p${MYSQL_PASSWD} <<EOF
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${MYSQL_PASSWD}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${MYSQL_PASSWD}';
FLUSH PRIVILEGES;
EOF

	service nova-api restart
	service nova-cert restart
	service nova-consoleauth restart
	service nova-scheduler restart
	service nova-conductor restart
	service nova-novncproxy restart

	nova-manage db sync
	
	chmod 740 ${NOVA_INIT_FILE}
	${NOVA_INIT_FILE}
	
	service nova-api restart
	service nova-cert restart
	service nova-consoleauth restart
	service nova-scheduler restart
	service nova-conductor restart
	service nova-novncproxy restart
}

####################################################################################
#
# Cinder Installation
#
####################################################################################

cinder_install(){
	apt install cinder-api cinder-scheduler
	replace_params ${CONF_DIR}/cinder
	cp -rf ${CONF_DIR}/cinder/* ${CINDER_CONF_DIR}/
        chown -R cinder:cinder ${CINDER_CONF_DIR}	

	mysql -u${MYSQL_USER} -p${MYSQL_PASSWD} <<EOF
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '${MYSQL_PASSWD}';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '${MYSQL_PASSWD}';
FLUSH PRIVILEGES;
EOF

	service cinder-scheduler restart
	service cinder-api restart
	cinder-manage db sync
	
	chmod 740 ${CINDER_INIT_FILE}
	${CINDER_INIT_FILE}
	
	service cinder-api restart
	service cinder-scheduler restart
}

####################################################################################
#
# Neutron Installation
#
####################################################################################
neutron_install(){
	apt install neutron-server neutron-plugin-ml2
	replace_params ${CONF_DIR}/neutron
	cp -rf ${CONF_DIR}/neutron/* ${NEUTRON_CONF_DIR}/
	chown -R neutron:neutron ${NEUTRON_CONF_DIR}
	
	SERVICE_TENANT=$(keystone tenant-get service | grep " id " | get_field 2)
	sed -i "s/\(nova_admin_tenant_id *= *\).*/\1${SERVICE_TENANT}/" ${NEUTRON_CONF_DIR}/neutron.conf
	
	mysql -u${MYSQL_USER} -p${MYSQL_PASSWD} <<EOF
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '${MYSQL_PASSWD}';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '${MYSQL_PASSWD}';
FLUSH PRIVILEGES;
EOF

	
	chmod 740 ${NEUTRON_INIT_FILE}
	${NEUTRON_INIT_FILE}
	
	service nova-api restart
	service nova-scheduler restart
	service nova-conductor restart
	service neutron-server restart

	sleep 30
	replace_network_params
	chmod 740 ${NEUTRON_CREATE_NETWORK}
	${NEUTRON_CREATE_NETWORK}

}

####################################################################################
#
# Horizon Installation
#
####################################################################################

horizon_install(){
	apt install apache2 memcached libapache2-mod-wsgi openstack-dashboard
	apt remove --purge openstack-dashboard-ubuntu-theme
	sed -i "s/\(OPENSTACK_HOST *= *\).*/\1\"${CONTROLLER_NODE_MGMT_IP}\"/" ${HORIZON_CONF}
}

########################################
# Main
#    execute main process
#
########################################

common_service_install
keystone_install
glance_install
nova_install
cinder_install
neutron_install
horizon_install
exit 0
