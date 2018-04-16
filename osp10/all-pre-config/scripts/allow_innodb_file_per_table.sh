#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/pre_deploy-allow_innodb_file_per_table.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
patch_file=/var/tmp/innodb_mysql.pp.patch

#
case ${my_node_role} in
	CTRL)
		if [ -f /usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp ]; then
cat > ${patch_file} << EOF
*** /usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp.orig	2017-11-30 18:02:58.031541005 +0000
--- /usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp	2017-11-30 18:04:06.967459344 +0000
***************
*** 73,74 ****
--- 73,75 ----
        'default-storage-engine'         => 'innodb',
+       'innodb_file_per_table'          => 'ON',
        'innodb_autoinc_lock_mode'       => '2',
EOF
			if [ -f ${patch_file} ]; then
				sudo patch -p0 < \
				${patch_file} \
				/usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp				
			fi
		fi
  ;;
esac
