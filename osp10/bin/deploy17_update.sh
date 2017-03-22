#!/bin/bash
#
#
[ "$BASH" ] && function whence
{
	type -p "$@" 
}
#
export PATH_SCRIPT="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)"
export TOP_DIR="$(cd ${PATH_SCRIPT}/..; pwd)"
export TRIPLEO_DIR="/usr/share/openstack-tripleo-heat-templates"

source ${TOP_DIR}/pre_deploy.sh || exit 127
set -x
yes "" | openstack overcloud update stack \
-i overcloud \
--templates \
-e ${TRIPLEO_DIR}/environments/network-isolation.yaml \
-e ${TRIPLEO_DIR}/environments/storage-environment.yaml \
-e ${TOP_DIR}/net-bond-with-vlans-with-nic4.yaml \
-e ${TOP_DIR}/rhel-registration-environment.yaml \
-e ${TOP_DIR}/storage-environment.yaml \
-e ${TOP_DIR}/krynn-environment.yaml \
-e ${TOP_DIR}/extraconfig-environment.yaml \
-e ${TOP_DIR}/enable-tls.yaml \
-e ${TOP_DIR}/inject-trust-anchor.yaml \
-e ${TRIPLEO_DIR}/environments/tls-endpoints-public-ip.yaml \
-e ${TOP_DIR}/local-environment.yaml
