#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-register_node_role.log ; exec &> >(tee -a "${VLOG}")

# Globals
my_hostname=$(hostname -s)
my_node_role_file="/var/log/ospd/node_role"
my_node_role="UNKNOWN"
my_node_index_file="/var/log/ospd/node_index"
my_node_index="-1"

# _CTRL_FORMAT_: {get_param: ControllerHostnameFormat}
CTRL_FORMAT="$(echo _CTRL_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"

# _CMPT_FORMAT_: {get_param: ComputeHostnameFormat}
CMPT_FORMAT="$(echo _CMPT_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"

# _SRIOV_FORMAT_: {get_param: ComputeSriovHostnameFormat}
SRIOV_FORMAT="$(echo _SRIOV_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"

# _DPDK_FORMAT_: {get_param: ComputeDpdkHostnameFormat}
DPDK_FORMAT="$(echo _DPDK_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"

# _CEPH_FORMAT_: {get_param: CephStorageHostnameFormat}
CEPH_FORMAT="$(echo _CEPH_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"

# _SWFT_FORMAT_: {get_param: ObjectStorageHostnameFormat}
SWFT_FORMAT="$(echo _SWFT_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"

#
echo "Controller Format: ${CTRL_FORMAT}, _CTRL_FORMAT_"
echo "Compute Format: ${CMPT_FORMAT}, _CMPT_FORMAT_"
echo "Ceph Format: ${CEPH_FORMAT}, _CEPH_FORMAT_"
echo "Swift Format: ${SWFT_FORMAT}, _SWFT_FORMAT_"

# Determine node type
case ${my_hostname} in
        *${CTRL_FORMAT}*)
		echo "Controller node detected..."
		my_node_role="CTRL"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${CTRL_FORMAT}//")
	;;
        *${CMPT_FORMAT}*)
		echo "Compute node detected..."
		my_node_role="CMPT"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${CMPT_FORMAT}//")
	;;
        *${SRIOV_FORMAT}*)
		echo "SRIOV Compute node detected..."
		my_node_role="SRIOV"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${SRIOV_FORMAT}//")
	;;
        *${DPDK_FORMAT}*)
		echo "DPDK Compute node detected..."
		my_node_role="DPDK"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${DPDK_FORMAT}//")
	;;
        *${CEPH_FORMAT}*)
		echo "Ceph node detected..."
		my_node_role="CEPH"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${CEPH_FORMAT}//")
	;;
        *${SWFT_FORMAT}*)
		echo "Swift node detected..."
		my_node_role="SWFT"
		my_node_index=$(echo "${my_hostname}"| sed -e "s/${SWFT_FORMAT}//")
	;;
	*)
		echo 'Not a recognized host pattern! Check the sed regexps above and/or force *_FORMAT=\"<format>\" values'
	;;
esac

# Fallback routine (In case something goes wrong above)
curl_role_type=$(printf "%s\n" $(curl -s http://169.254.169.254/latest/meta-data/instance-type)|tr '[:upper:]' '[:lower:]')
echo "My curl_role_type: ${curl_role_type}"
case "${curl_role_type}" in
	"control")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Controller node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="CTRL"
			my_node_index="XYZ"
		fi
	;;
        "compute")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Compute node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="CMPT"
			my_node_index="XYZ"
		fi
	;;
        "computesriov")
		if [ "x${my_node_role}" = "x" ]; then
			echo "SRIOV Compute node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="SRIOV"
			my_node_index="XYZ"
		fi
	;;
        "computedpdk")
		if [ "x${my_node_role}" = "x" ]; then
			echo "DPDK Compute node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="DPDK"
			my_node_index="XYZ"
		fi
	;;
        "ceph-storage")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Ceph node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="CEPH"
			my_node_index="XYZ"
		fi
	;;
        "object-storage")
		if [ "x${my_node_role}" = "x" ]; then
			echo "Swift node detected (curl http://169.254.169.254/.../instance-type)"
			my_node_role="SWFT"
			my_node_index="XYZ"
		fi
	;;
	*)
		echo 'Not a recognized instance type! Check values returned by curl -s http://169.254.169.254/latest/meta-data/instance-type'
	;;
esac

# Save the detected node role..
echo "${my_node_role}" > ${my_node_role_file}
echo "${my_node_index}" > ${my_node_index_file}
