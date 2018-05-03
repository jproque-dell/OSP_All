#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-computedpdk_install_tuned.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

# Uses the role types as determined by all-firstboot-config/scripts/register_node_role.sh
# Can be extended to include other roles in the future
#

echo "(II) Tuned Cores Parameter: $TUNED_CORES"
case ${my_node_role} in
	"ComputeDpdk")
		# Configure tuned profile
		tuned_conf_path="/etc/tuned/cpu-partitioning-variables.conf"
		if [ -n "$TUNED_CORES" ]; then
			grep -q "^isolated_cores" $tuned_conf_path
			if [ "$?" -eq 0 ]; then
				sed -i 's/^isolated_cores=.*/isolated_cores=$TUNED_CORES/' $tuned_conf_path
			else
				echo "isolated_cores=$TUNED_CORES" >> $tuned_conf_path
			fi
			tuned-adm profile cpu-partitioning
		fi
		;;
	*)
		echo "(II) DPDK Integration not enabled for this host, exit!"
		;;
esac
exit 0
