#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-register_node_role.log ; exec &> >(tee -a "${VLOG}")

# Globals
my_hostname=$(hostname -s)
my_node_role_file="/var/log/ospd/node_role"
my_node_role=""
my_node_index_file="/var/log/ospd/node_index"
my_node_index="-1"
max_loops=60
cur_loop=0

# _CTRL_FORMAT_: {get_param: ControllerHostnameFormat}
if [ "x_CTRL_FORMAT_" != "x" ]; then
	CTRL_FORMAT="$(echo _CTRL_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
	echo "Controller Format: ${CTRL_FORMAT}, _CTRL_FORMAT_"
	if [[ "${my_hostname}" == *${CTRL_FORMAT}* ]]; then
		echo "Controller node detected..."
		my_node_role="CTRL"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${CTRL_FORMAT}//")
	fi
fi

# _CMPT_FORMAT_: {get_param: ComputeHostnameFormat}
if [ "x_CMPT_FORMAT_" != "x" ]; then
	CMPT_FORMAT="$(echo _CMPT_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
	echo "Compute Format: ${CMPT_FORMAT}, _CMPT_FORMAT_"
	if [[ "${my_hostname}" == *${CMPT_FORMAT}* ]]; then
		echo "Controller node detected..."
		my_node_role="CMPT"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${CMPT_FORMAT}//")
	fi
fi

# _SRIOV_FORMAT_: {get_param: ComputeSriovHostnameFormat}
if [ "x_SRIOV_FORMAT_" != "x" ]; then
	SRIOV_FORMAT="$(echo _SRIOV_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
	echo "SRIOV Compute Format: ${SRIOV_FORMAT}, _SRIOV_FORMAT_"
	if [[ "${my_hostname}" == *${SRIOV_FORMAT}* ]]; then
		echo "Controller node detected..."
		my_node_role="SRIOV"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${SRIOV_FORMAT}//")
	fi
fi

# _DPDK_FORMAT_: {get_param: ComputeDpdkHostnameFormat}
if [ "x_DPDK_FORMAT_" != "x" ]; then
	DPDK_FORMAT="$(echo _DPDK_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
	echo "DPDK Compute Format: ${DPDK_FORMAT}, _DPDK_FORMAT_"
	if [[ "${my_hostname}" == *${DPDK_FORMAT}* ]]; then
		echo "Controller node detected..."
		my_node_role="DPDK"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${DPDK_FORMAT}//")
	fi
fi

# _CEPH_FORMAT_: {get_param: CephStorageHostnameFormat}
if [ "x_CEPH_FORMAT_" != "x" ]; then
	CEPH_FORMAT="$(echo _CEPH_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
	echo "Ceph Format: ${CEPH_FORMAT}, _CEPH_FORMAT_"
	if [[ "${my_hostname}" == *${CEPH_FORMAT}* ]]; then
		echo "Controller node detected..."
		my_node_role="CEPH"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${CEPH_FORMAT}//")
	fi
fi

# _SWFT_FORMAT_: {get_param: ObjectStorageHostnameFormat}
if [ "x_SWFT_FORMAT_" != "x" ]; then
	SWFT_FORMAT="$(echo _SWFT_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
	echo "Swift Format: ${SWFT_FORMAT}, _SWFT_FORMAT_"
	if [[ "${my_hostname}" == *${SWFT_FORMAT}* ]]; then
		echo "Controller node detected..."
		my_node_role="SWFT"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${SWFT_FORMAT}//")
	fi
fi
#
while [ ${cur_loop} -lt ${max_loops} ]
do
	echo "Current loop: ${cur_loop} "
	curl_role_type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type|tr '[:upper:]' '[:lower:]'|xargs)
	case "${curl_role_type}" in
		"control"|"compute"|"computesriov"|"computedpdk"|"ceph-storage"|"object-storage"|"networker")
		break
		;;
	*)
		sleep 2s
		;;
	esac
done

# Fallback routine (In case something goes wrong above)
# curl_role_type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type|tr '[:upper:]' '[:lower:]'|xargs)
echo "My curl_role_type: ${curl_role_type}"
case "${curl_role_type}" in
	"control")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Controller node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="CTRL"
		fi
	;;
        "compute")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Compute node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="CMPT"
		fi
	;;
        "computesriov")
		if [ "x${my_node_role}" = "x" ]; then
			echo "SRIOV Compute node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="SRIOV"
		fi
	;;
        "computedpdk")
		if [ "x${my_node_role}" = "x" ]; then
			echo "DPDK Compute node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="DPDK"
		fi
	;;
        "ceph-storage")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Ceph node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="CEPH"
		fi
	;;
        "object-storage")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Swift node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="SWFT"
		fi
	;;
	*)
		echo 'Not a recognized instance type! Check values returned by curl -s http://169.254.169.254/latest/meta-data/instance-type'
		my_node_role="UNKNOWN"
		my_node_index="-1"
		exit 1
	;;
esac

# Save the detected node role..
echo "${my_node_role}" > ${my_node_role_file}
echo "${my_node_index}" > ${my_node_index_file}
