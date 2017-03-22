#!/bin/bash
#
set -x ; l=firstboot-opsd_create_log_dir ; VLOG=/var/log/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

#
LOG_DIR="/var/log/ospd"
case "$(hostname)" in
	*)
		/usr/bin/mkdir ${LOG_DIR} || exit 1
		/usr/bin/chown root:root ${LOG_DIR}
		/usr/bin/chmod 750 ${LOG_DIR}
	;;
esac
