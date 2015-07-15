function save_mbr {
    sfdisk --dump $INTERNAL_DISK > /images/gpt.desc
}

function restore_mbr {
    sfdisk $INTERNAL_DISK < /images/gpt.desc
}

function transfer_linux_to_client {
    if [ ! "$QCIMAGE_MODE" == "admin" ]; then
	echo "Operation not valid in context $QCIMAGE_MODE: transfer_linux_to_client"
    fi
    if client_linux_is_mounted_p; then
	umount_client_linux
    fi
    mount_client_btrfs_root
    # Delete old root subvol
    if [ -e ${LOCAL_LINUX_DIR}/root ]; then
	btrfs subvolume delete ${LOCAL_LINUX_DIR}/root
    fi
    ## Create a snapshot of admin linux root on admin linux
    snap=$SNAPSHOT_DIR/$(get_newest_milestone /)
    ## Send the snapshot to the local linux as /${snap}
    parent=$(get_newest_snap ${LOCAL_LINUX_DIR})
    if milestone_present_p parent /; then
	btrfs send -p $parent $snap | btrfs receive ${LOCAL_LINUX_DIR}/${SNAPSHOT_DIR}
    else
	btrfs send $snap | btrfs receive ${LOCAL_LINUX_DIR}/${SNAPSHOT_DIR}
    fi
    ## Set this new local linux subvolume to be automatically mounted
    btrfs subvolume snapshot ${LOCAL_LINUX_DIR}/${snap} ${LOCAL_LINUX_DIR}/root
    set_btrfs_default_subvol_by_name ${LOCAL_LINUX_DIR} root
    ## Remount client_linux to reflect new default subvolume / root
    umount_client_linux
    mount_client_linux
    genfstab -U ${LOCAL_LINUX_DIR} > ${LOCAL_LINUX_DIR}/etc/fstab
    modify_local_linux
    configure_local_grub
}

function modify_local_linux {
    echo "FIXME: Do things to differentiate files on local linux from USB boot"
    #/bin/cp -f /qcimage/linux_root/etc/local-fstab /mnt/etc/fstab
    #/bin/cp -f /qcimage/linux_root/boot/grub2/local-grub.cfg /mnt/boot/grub2/grub.cfg
    #cp /qcimage/linux_root/boot/grub2/altcmp.mod /mnt/boot/grub2
}

function configure_local_grub {
    grub-install --target=i386-pc --debug --no-floppy --root-dir=${LOCAL_LINUX_DIR} ${INTERNAL_DISK}
    arch-chroot ${LOCAL_LINUX_DIR} /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
}

function clone_new_machine {
  # Restore MBR containing three paritions (reserved, windows, linux)
  dd if=${RAW_IMAGE_DIR}/windows.mbr of=${INTERNAL_DISK}
  # Rescan the MBR and create the new partition devices
  partprobe
  reload
  echo Cloning Windows main partition to ${WINDOWS_PART}
  ntfsclone $RAW_IMAGE_DIR/windows.ntfs.img -O ${WINDOWS_PART}
  echo Transferring Linux to ${LOCAL_LINUX_PART}
  transfer_linux_to_client
}

# function clone_admin_key {
#     dest=$1
#     if [ ! "${dest:0:5}"=="/dev/" ]; then
# 	echo "clone_admin_key: Argument does not look like a device"
#     elif [ ! "$QCIMAGE_MODE" == "admin" ]; then
# 	echo "clone_admin_key: Not available in ${QCIMAGE} mode"
#     else
# 	dd if=${ADMIN_DISK} of=$1 bs=512 count=1
# 	partprobe
# 	partclone.btrfs -b -s${ADMIN_DISK} -O${dest}
#     fi
# }

# function compare_image_update_in_place {
#     new_image=$1
#     old_image=$2 # Will be modified
#     cluster_size=$(get_ntfs_cluster_size $new_image)
#     num_clusters=$(get_ntfs_num_clusters $new_image)
#     block_size=2000 # (In clusters e.g. 1000=4M) 
#     mod_counter=0
#     for (( i=0; i < num_clusters; i+=block_size )); do
# 	if [ $(( i+block_size )) -gt $num_clusters ]; then
# 	    i=$(( num_clusters - block_size ))
# 	fi
# 	offset=$((cluster_size*i))
# 	old_md5=$(dd if=$old_image bs=$cluster_size count=$block_size skip=$offset 2>/dev/null|md5sum)
# 	new_md5=$(dd if=$new_image bs=$cluster_size count=$block_size skip=$offset 2>/dev/null|md5sum)
# 	update_interval=$(( ((num_clusters/100)/block_size) ))
# 	if [ ! $update_interval -eq 0 ]; then
# 	   if [ $(( i % $update_interval )) -eq 0 ]; then
# 	       percent=$(( i*100/num_clusters ))
# 	       mod_bytes=$(( mod_counter*cluster_size*block_size ))
# 	       echo -ne "At cluster $i/$num_clusters ($percent%);"\
# 		    "modified $mod_counter blocks ($mod_bytes bytes)\r"
# 	   fi
# 	fi
# 	if [ "$old_md5" == "$new_md5" ]; then
# 	    continue
# 	else
# 	    echo "Modified block at cluster $i (offset: $offset); updating image"
# 	    dd if=$new_image of=$old_image skip=$offset bs=$cluster_size count=1 conv=notrunc 2>/dev/null
# 	    mod_counter=$((mod_counter+1))
# 	fi
#     done
#     echo "compare_image_update_in_place: Done"
#}

function get_partition_fstype {
    part=$1
    if [ -n $part ]; then
	if [ "${part:0:5}" == "/dev/" ]; then
	    part=${part:5}
	fi
	part=$(lsblk -o NAME,FSTYPE|awk -v part="$part" 'index($0, part) {print $2}')
    fi
    echo $part
}

function get_partition_parttype {
    part=$1
    if [ -n $part ]; then
	if [ "${part:0:5}" == "/dev/" ]; then
	    part=${part:5}
	fi
	part=$(lsblk -o NAME,PARTTYPE|awk -v part="$part" 'index($0, part) {print $2}')
    fi
    echo $part
}


function find_ntfs_parts {
    echo $(find_parts_by_fstype ntfs)
}

function find_linux_parts {
    echo $(find_parts_by_parttype "0x83")
}

function find_parts_by_fstype {
    fstype=$1
    echo $(lsblk -l -f -o NAME,FSTYPE |\
		  awk -vfstype="$fstype" 'index($2, fstype) {printf("/dev/%s\n", $1)}')
}

function find_parts_by_parttype {
    parttype=$1
    echo $(lsblk -l -f -o NAME,PARTTYPE |\
		  awk -vparttype="$parttype" 'index($2, parttype) {printf("/dev/%s\n", $1)}')
}
