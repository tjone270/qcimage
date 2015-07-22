## admin_linux.sh
##
## This file contains functions that operate only when client_linux
## (install on tourney local disk) is not the rootfs (e.g. booted from
## USB admin stick)

# function check_admin_linux {
#     calling_func=$1
#     if [ ! "$QCIMAGE_MODE" == "admin" ]; then
# 	echo "$calling_func: Operation not valid in context $QCIMAGE_MODE"
# 	return 1
#     fi
#     return 0
# }

function mount_client_linux {
    echo "Trying to mount internal linux"
    if [ "$LOCAL_LINUX_PART" == "$ROOT_PART" ]; then
	echo "Refusing to mount admin root on client mountpoint"
	return 1
    fi
    mount ${LOCAL_LINUX_PART} ${LOCAL_LINUX_DIR} && mount $(find_internal_efi) ${LOCAL_LINUX_DIR}/boot
}

function umount_client_linux {
    if [ ! "$QCIMAGE_MODE" == "admin" ]; then
	echo "Operation not valid in context $QCIMAGE_MODE: umount_client_linux"
	return 1
    fi
    umount ${LOCAL_LINUX_DIR}/boot
    umount ${LOCAL_LINUX_DIR}
}


function client_linux_is_mounted_p {
    mountpoint=$(mount | awk -v part="$LOCAL_LINUX_PART" 'index($1, part) {print $3}')
    if [ "$mountpoint" == "${LOCAL_LINUX_DIR}" ]; then
	return 0
    else
	return 1
    fi
}

# function transfer_linux_to_client {
#     if [ ! "$QCIMAGE_MODE" == "admin" ]; then
# 	echo "Operation not valid in context $QCIMAGE_MODE: transfer_linux_to_client"
#     fi
#     if client_linux_is_mounted_p; then
# 	umount_client_linux
#     fi
#     mount_client_btrfs_root
#     # Delete old root subvol
#     if [ -e ${LOCAL_LINUX_DIR}/root ]; then
# 	btrfs subvolume delete ${LOCAL_LINUX_DIR}/root
#     fi
#     ## Create a snapshot of admin linux root on admin linux
#     snap=$SNAPSHOT_DIR/$(get_newest_milestone /)
#     ## Send the snapshot to the local linux as /${snap}
#     parent=$(get_newest_snap ${LOCAL_LINUX_DIR})
#     if milestone_present_p parent /; then
# 	btrfs send -p $parent $snap | btrfs receive ${LOCAL_LINUX_DIR}/${SNAPSHOT_DIR}
#     else
# 	btrfs send $snap | btrfs receive ${LOCAL_LINUX_DIR}/${SNAPSHOT_DIR}
#     fi
#     ## Set this new local linux subvolume to be automatically mounted
#     btrfs subvolume snapshot ${LOCAL_LINUX_DIR}/${snap} ${LOCAL_LINUX_DIR}/root
#     set_btrfs_default_subvol_by_name ${LOCAL_LINUX_DIR} root
#     ## Remount client_linux to reflect new default subvolume / root
#     umount_client_linux
#     mount_client_linux
#     genfstab -U ${LOCAL_LINUX_DIR} > ${LOCAL_LINUX_DIR}/etc/fstab
#     modify_local_linux
#     configure_local_grub
# }
