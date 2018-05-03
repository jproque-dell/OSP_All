#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-computedpdk_set_ovs_config.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

# Uses the role types as determined by all-firstboot-config/scripts/register_node_role.sh
# Can be extended to include other roles in the future
#

echo "(II) Tuned Cores Parameter: $TUNED_CORES"
case ${my_node_role} in
	"ComputeDpdk")
		if [ -f /usr/lib/systemd/system/openvswitch-nonetwork.service ]; then
			ovs_service_path="/usr/lib/systemd/system/openvswitch-nonetwork.service"
		elif [ -f /usr/lib/systemd/system/ovs-vswitchd.service ]; then
			ovs_service_path="/usr/lib/systemd/system/ovs-vswitchd.service"
		fi

		#
		grep -q "RuntimeDirectoryMode=.*" ${ovs_service_path}
		if [ "$?" -eq 0 ]; then
			sed -i 's/RuntimeDirectoryMode=.*/RuntimeDirectoryMode=0775/' ${ovs_service_path}
		else
			echo "RuntimeDirectoryMode=0775" >> ${ovs_service_path}
		fi

		#
		grep -Fxq "Group=qemu" ${ovs_service_path}
		if [ ! "$?" -eq 0 ]; then
			echo "Group=qemu" >> ${ovs_service_path}
		fi

		#
		grep -Fxq "UMask=0002" ${ovs_service_path}
		if [ ! "$?" -eq 0 ]; then
			echo "UMask=0002" >> ${ovs_service_path}
		fi

		#
		ovs_ctl_path='/usr/share/openvswitch/scripts/ovs-ctl'
		grep -q "umask 0002 \&\& start_daemon \"\$OVS_VSWITCHD_PRIORITY\"" ${ovs_ctl_path}
		if [ ! "$?" -eq 0 ]; then
		sed -i 's/start_daemon \"\$OVS_VSWITCHD_PRIORITY.*/umask 0002 \&\& start_daemon \"$OVS_VSWITCHD_PRIORITY\" \"$OVS_VSWITCHD_WRAPPER\" \"$@\"/' ${ovs_ctl_path}
		fi
		;;
	*)
		echo "(II) DPDK Integration not enabled for this host, exit!"
		;;
esac
exit 0
