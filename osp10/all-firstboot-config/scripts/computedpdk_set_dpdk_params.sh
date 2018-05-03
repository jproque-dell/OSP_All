#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-computedpdk_set_dpdk_params.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

# Uses the role types as determined by all-firstboot-config/scripts/register_node_role.sh
# Can be extended to include other roles in the future
#

get_mask()
{
	local list=$1
	local mask=0
	declare -a bm
	max_idx=0
	for core in $(echo $list | sed 's/,/ /g')
	do
		index=$(($core/32))
		bm[$index]=0
		if [ $max_idx -lt $index ]; then
			max_idx=$(($index))
		fi
	done
	for ((i=$max_idx;i>=0;i--));
	do
		bm[$i]=0
	done

	for core in $(echo $list | sed 's/,/ /g')
	do
		index=$(($core/32))
		temp=$((1<<$(($core % 32))))
		bm[$index]=$((${bm[$index]} | $temp))
	done

	printf -v mask "%x" "${bm[$max_idx]}"
	for ((i=$max_idx-1;i>=0;i--));
	do
		printf -v hex "%08x" "${bm[$i]}"
		mask+=$hex
	done
	printf "%s" "$mask"
}


echo "(II) Tuned Cores Parameter: $TUNED_CORES"
case ${my_node_role} in
	"ComputeDpdk")
		pmd_cpu_mask=$( get_mask $PMD_CORES )
		host_cpu_mask=$( get_mask $LCORE_LIST )
		socket_mem=$(echo $SOCKET_MEMORY | sed s/\'//g )
		ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
		ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem=$socket_mem
		ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=$pmd_cpu_mask
		ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=$host_cpu_mask
		;;
	*)
		echo "(II) DPDK Integration not enabled for this host, exit!"
		;;
esac
exit 0
