#!/bin/bash
# $Id$
set -x ; VLOG=/var/log/ospd/post_deploy-add_readonly_role_policies.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
my_node_index=$(cat /var/log/ospd/node_index)

#
set -uf -o pipefail
declare -i restart_svc=0

# This tool is used to push policies on the overcloud
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
TOP_DIR="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)/policydir"


# Create readonly role using puppet on ctrl0
case "${my_node_role}${my_node_index}" in
	"CTRL0")
		echo "Creating readonly role on Galera using Controller0..."
		/bin/puppet apply -e 'keystone_role { 'readonly':  ensure => present }'
	;;
esac

# This is needed to skip over the uuencoded payload
exit 0
