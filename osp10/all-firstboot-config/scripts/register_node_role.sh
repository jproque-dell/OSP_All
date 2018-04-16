#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-register_node_role.log ; exec &> >(tee -a "${VLOG}")

# Globals
mhost=$(hostname -s)
role_file="/var/log/ospd/node_role"
role=""
index_file="/var/log/ospd/node_index"
idx="-1"
hmap_file="/var/log/ospd/node_hostnamemap"
max=2
i=0
hmap='_hostnamemap_'
snode=""
sed_fmt='-e s/\%index\%//g -e s/\%stackname\%//g'

# First see if a HostnameMap mangled my hostname (lowercase it)
if [[ -n ${hmap} ]]; then
	snode=$(echo ${hmap}|jq -r --arg myh "${mhost}" '. as $o | keys[] | select($o[.] == $myh)'|tr '[:upper:]' '[:lower:]')
	if [ "x${snode}" != "x" ]; then
		mhost="${snode}"
	fi
fi

# _CTRL_FORMAT_: {get_param: ControllerHostnameFormat}
if [ "x_CTRL_FORMAT_" != "x" ]; then
	CTRL_FORMAT="$(echo _CTRL_FORMAT_|sed ${sed_fmt})"
	echo "Controller Format: ${CTRL_FORMAT}, _CTRL_FORMAT_"
	if [[ "${mhost}" == ${CTRL_FORMAT}* ]]; then
		echo "Controller node detected..."
		role="CTRL"
		idx=$(echo "${mhost}"| sed -e "s/${CTRL_FORMAT}//")
	fi
fi

# _CMPT_FORMAT_: {get_param: ComputeHostnameFormat}
if [ "x_CMPT_FORMAT_" != "x" ]; then
	CMPT_FORMAT="$(echo _CMPT_FORMAT_|sed ${sed_fmt})"
	echo "Compute Format: ${CMPT_FORMAT}, _CMPT_FORMAT_"
	if [[ "${mhost}" == ${CMPT_FORMAT}* ]]; then
		echo "Compute node detected..."
		role="CMPT"
		idx=$(echo "${mhost}"| sed -e "s/${CMPT_FORMAT}//")
	fi
fi

# _SRIOV_FORMAT_: {get_param: ComputeSriovHostnameFormat}
if [ "x_SRIOV_FORMAT_" != "x" ]; then
	SRIOV_FORMAT="$(echo _SRIOV_FORMAT_|sed ${sed_fmt})"
	echo "SRIOV Compute Format: ${SRIOV_FORMAT}, _SRIOV_FORMAT_"
	if [[ "${mhost}" == ${SRIOV_FORMAT}* ]]; then
		echo "SRIOV Compute node detected..."
		role="SRIOV"
		idx=$(echo "${mhost}"| sed -e "s/${SRIOV_FORMAT}//")
	fi
fi

# _DPDK_FORMAT_: {get_param: ComputeDpdkHostnameFormat}
if [ "x_DPDK_FORMAT_" != "x" ]; then
	DPDK_FORMAT="$(echo _DPDK_FORMAT_|sed ${sed_fmt})"
	echo "DPDK Compute Format: ${DPDK_FORMAT}, _DPDK_FORMAT_"
	if [[ "${mhost}" == ${DPDK_FORMAT}* ]]; then
		echo "DPDK Compute node detected..."
		role="DPDK"
		idx=$(echo "${mhost}"| sed -e "s/${DPDK_FORMAT}//")
	fi
fi

# _CEPH_FORMAT_: {get_param: CephStorageHostnameFormat}
if [ "x_CEPH_FORMAT_" != "x" ]; then
	CEPH_FORMAT="$(echo _CEPH_FORMAT_|sed ${sed_fmt})"
	echo "Ceph Format: ${CEPH_FORMAT}, _CEPH_FORMAT_"
	if [[ "${mhost}" == ${CEPH_FORMAT}* ]]; then
		echo "Ceph node detected..."
		role="CEPH"
		idx=$(echo "${mhost}"| sed -e "s/${CEPH_FORMAT}//")
	fi
fi

# _SWFT_FORMAT_: {get_param: ObjectStorageHostnameFormat}
if [ "x_SWFT_FORMAT_" != "x" ]; then
	SWFT_FORMAT="$(echo _SWFT_FORMAT_|sed ${sed_fmt})"
	echo "Swift Format: ${SWFT_FORMAT}, _SWFT_FORMAT_"
	if [[ "${mhost}" == ${SWFT_FORMAT}* ]]; then
		echo "Swift node detected..."
		role="SWFT"
		idx=$(echo "${mhost}"| sed -e "s/${SWFT_FORMAT}//")
	fi
fi

# _NETWRK_FORMAT_: {get_param: NetworkerHostnameFormat}
if [ "x_NETWRK_FORMAT_" != "x" ]; then
	NETWRK_FORMAT="$(echo _NETWRK_FORMAT_|sed ${sed_fmt})"
	echo "Networker Format: ${NETWRK_FORMAT}, _NETWRK_FORMAT_"
	if [[ "${mhost}" == ${NETWRK_FORMAT}* ]]; then
		echo "Networker node detected..."
		role="NETWRK"
		idx=$(echo "${mhost}"| sed -e "s/${NETWRK_FORMAT}//")
	fi
fi

# cannot use curl -s http://169.254.169.254/latest/meta-data/instance-type here since it is not ready yet
# Let's fetch it from cloud-init
while [ ${i} -lt ${max} ]
do
	echo "Current loop: ${i} "
	ec2_type=$(grep metadata /var/lib/cloud/instance/user-data.txt|xargs -n1|grep ^http|cut -d/ -f6|cut -d- -f5)
	case "${ec2_type}" in
		"Controller"|"NovaCompute"|"ComputeSriov"|"ComputeDpdk"|"CephStorage"|"ObjectStorage"|"Networker")
			break
			;;
		*)
			i=$((i + 1))
			sleep 2s
			;;
	esac
done

# Failsafe check (In case something goes wrong above)
if [ "x${ec2_type}" = "x" ]; then
	echo "(WW) Unable to use metadata to find Role.." ; exit 1
else
	echo "(II) My ec2_type: ${ec2_type}"
	if [ "x${role}" = "x" ]; then
		case "${ec2_type}" in
			"Controller")
				echo "Controller node detected"
				role="CTRL"
			;;
			"NovaCompute")
				echo "Compute node detected"
				role="CMPT"
			;;
			"ComputeSriov")
				echo "SRIOV Compute node detected"
				role="SRIOV"
			;;
			"ComputeDpdk")
				echo "DPDK Compute node detected"
				role="DPDK"
			;;
			"CephStorage")
				echo "Ceph node detected"
				role="CEPH"
			;;
			"ObjectStorage")
				echo "Swift node detected"
				role="SWFT"
			;;
			"Networker")
				echo "Networker node detected"
				role="NETWRK"
			;;
			*)
				echo 'Not a recognized instance type! Check metadata_url /var/lib/cloud/instance/user-data.txt'
				exit 1
			;;
		esac
	else
		echo "(II) Role already set! Current role: ${role}"
	fi
fi

# Save the detected node role..
echo "(II) THIS SERVER IS A ${role}, index ${idx}"
echo "${role}" > ${role_file}
echo "${idx}" > ${index_file}
echo "${hmap}" > ${hmap_file}
