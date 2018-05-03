#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-computesriov_kernel_args.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

# Uses the role types as determined by all-firstboot-config/scripts/register_node_role.sh
# Can be extended to include other roles in the future
#

echo "(II) Tuned Cores Parameter: $TUNED_CORES"
case ${my_node_role} in
	"ComputeSriov")
		# Set grub parameters
		sed 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 $KERNEL_ARGS isolcpus=$TUNED_CORES"/g' -i /etc/default/grub ;
		grub2-mkconfig -o /etc/grub2.cfg
		dracut -f ; sync ; sync
		;;
	*)
		echo "(II) SRIOV Integration not enabled for this host, exit!"
		;;
esac
exit 0
