function save_mbr {
  dd if=$INTERNAL_DISK of=$RAW_IMAGE_DIR/windows.mbr bs=512 count=1
}

function mount_windows {
    mount $WINDOWS_PART $WINDOWS_DIR
}

function umount_windows {
    umount $WINDOWS_DIR
}

function remove_windows_cruft {
    mount_windows
    for file in $WINDOWS_SHIT; do
	if [ -e $WINDOWS_DIR/$file ]; then
	    rm $WINDOWS_DIR/$file
	fi
    done
    umount_windows
}

function save_windows {
  # This function makes new windows clone images
  save_mbr
  remove_windows_cruft
  image_file=$RAW_IMAGE_DIR/windows.ntfs.img
  if [ ! -e $image_file ]; then
      echo "save_windows: No previous image, creating new one"
      ntfsclone ${WINDOWS_PART} -o $image_file
  else
      echo "save_windows: Updating existing windows image"
      # So, if we unlink the file, btrfs cannot track the
      # changes... so we jump through a hoop to only change the needed blocks
      compare_image_update_in_place ${WINDOWS_PART} ${image_file}
  fi
}

function clear_milestones {
    fs=$1
    btrfs subvolume list $fs | awk '/milestone/ {print $9}' |xargs -i btrfs subvolume delete $fs{}
}

function gen_milestone {
    snap_name=milestone_$(date +%s)
    echo $snap_name > /.milestone
    btrfs subvolume snapshot -r / ${SNAPSHOT_DIR}/$snap_name
}

function mount_client_linux {
    if [ ! "$QCIMAGE_MODE" == "admin" ]; then
	echo "Operation not valid in context $QCIMAGE_MODE: mount_client_linux"
	return 1
    fi
    if [ ! "$(get_partition_fstype ${LOCAL_LINUX_PART})" == "btrfs" ]; then
	echo "Found *unformated* local linux partition on $LOCAL_LINUX_PART, formatting" 
	mkfs.btrfs ${LOCAL_LINUX_PART}	
    fi
    mount ${LOCAL_LINUX_PART} ${LOCAL_LINUX_DIR}
    if [ ! -e ${LOCAL_LINUX_DIR}/${SNAPSHOT_DIR} ]; then
	btrfs subvolume create ${LOCAL_LINUX_DIR}/${SNAPSHOT_DIR}
    fi
}

function umount_client_linux {
    if [ ! "$QCIMAGE_MODE" == "admin" ]; then
	echo "Operation not valid in context $QCIMAGE_MODE: umount_client_linux"
	return 1
    fi
    umount ${LOCAL_LINUX_DIR}
}

function set_btrfs_default_subvol_by_name {
    fs_mountpoint=$1
    subvol_name=$2
    subvol_id=$(btrfs subvolume list ${fs_mountpoint}|awk -v subvol_name="$subvol_name" '{if ($9 == subvol_name) { print $2 }}')
    if [ ! "$subvol_id" == "" ]; then
	btrfs subvolume set-default ${subvol_id} ${fs_mountpoint}
    else
	echo "set_btrfs_default_subvol_by_name: Couldn't find subvol name = \"$subvol_name\" on mountpoint = \"$fs_mountpoint\""
    fi
}

function mount_client_btrfs_root {
    mount_client_linux
    btrfs subvolume set-default 0 ${LOCAL_LINUX_DIR}
    umount_client_linux
    mount_client_linux
}

function mount_client_def_subvol {
    umount_client_linux
    mount_client_linux
}

function client_linux_is_mounted_p {
    mountpoint=$(mount | awk -v part="$LOCAL_LINUX_PART" 'index($1, part) {print $3}')
    if [ "$mountpoint" == "${LOCAL_LINUX_DIR}" ]; then
	return 0
    else
	return 1
    fi
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
    snap_name=client_root_$(date +%s)
    snap=$SNAPSHOT_DIR/$snap_name
    ## Create a snapshot of admin linux root on admin linux
    btrfs subvolume snapshot -r / $snap
    sync
    ## Send the snapshot to the local linux as /${snap}
    btrfs send $snap | btrfs receive ${LOCAL_LINUX_DIR}/${SNAPSHOT_DIR}
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
    arch-chroot ${LOCAL_LINUX_DIR} /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg.test222
}

function clone_new_machine {
  # Restore MBR containing three paritions (reserved, windows, linux)
  dd if=${RAW_IMAGE_DIR}/windows.mbr of=${INTERNAL_DISK}
  # Rescan the MBR and create the new partition devices
  partprobe
  reload
  echo Cloning Windows main partition to ${WINDOWS_PART}
  ntfsclone $RAW_IMAGE_DIR/windows.main.ntfs.img -O ${WINDOWS_PART}
  echo Transferring Linux to ${LOCAL_LINUX_PART}
  transfer_linux_to_client
}

function clone_admin_key {
    dest=$1
    if [ ! "${dest:0:5}"=="/dev/" ]; then
	echo "clone_admin_key: Argument does not look like a device"
    elif [ ! "$QCIMAGE_MODE" == "admin" ]; then
	echo "clone_admin_key: Not available in ${QCIMAGE} mode"
    else
	dd if=${ADMIN_DISK} of=$1 bs=512 count=1
	partprobe
	partclone.btrfs -b -s${ADMIN_DISK} -O${dest}
    fi
}

function sync_demos {
  rsync -v -e "ssh -o StrictHostKeyChecking=no -l $DEMOS_USER -i $DEMOS_KEY" $WINDOWS_DIR/Users/tourney-user/AppData/LocalLow/id\ Software/lan/home/baseq3/demos/* $DEMOS_USER@$DEMOS_SERVER:$DEMOS_PATH
}

function make_image_server_dir {
    dest=$1
    if [ ! -e $dest ]; then
	mkdir $dest
    fi   
}

function get_ntfs_cluster_size {
    ntfsinfo -m $WINDOWS_PART | awk '/Cluster Size:/ { print $3 }'
}

function get_ntfs_num_clusters {
    ntfsinfo -m $WINDOWS_PART | awk '/Size in Clusters:/ { print $5 }'
}

function compare_image_update_in_place {
    new_image=$1
    old_image=$2 # Will be modified
    cluster_size=$(get_ntfs_cluster_size)
    num_clusters=$(get_ntfs_num_clusters)
    block_size=2000 # (In clusters e.g. 1000=4M) 
    mod_counter=0
    for (( i=0; i < num_clusters; i+=block_size )); do
	if [ $(( i+block_size )) -gt $num_clusters ]; then
	    i=$(( num_clusters - block_size ))
	fi
	offset=$((cluster_size*i))
	old_md5=$(dd if=$old_image bs=$cluster_size count=$block_size skip=$offset 2>/dev/null|md5sum)
	new_md5=$(dd if=$new_image bs=$cluster_size count=$block_size skip=$offset 2>/dev/null|md5sum)
	if [ $(( i % ((num_clusters/100)/block_size) )) -eq 0 ]; then
	    percent=$(( i*100/num_clusters ))
	    mod_bytes=$(( mod_counter*cluster_size*block_size ))
	    echo -ne "At cluster $i/$num_clusters ($percent%);"\
		 "modified $mod_counter blocks ($mod_bytes bytes)\r"
	fi
	if [ "$old_md5" == "$new_md5" ]; then
	    continue
	else
	    echo "Modified block at cluster $i (offset: $offset); updating image"
	    dd if=$new_image of=$old_image skip=$offset bs=$cluster_size count=1 conv=notrunc 2>/dev/null
	    mod_counter=$((mod_counter+1))
	fi
    done
    echo "compare_image_update_in_place: Done"
}

function gen_btrfs_send {
    parent_snap=$1
    target_snap=$2
    outfile=${SNAPSHOT_DIR}/${parent_snap}-${target_snap}.btrsend.lzo
    btrfs send -p $parent_snap $target_snap | lzo -o $outfile
}

function get_newest_milestone {
    echo $(get_milestones | tail -n1)
}

function get_oldest_milestone {
    echo $(get_milestones | head -n1)
}

function get_milestones {
    btrfs subvolume list $SNAPSHOT_DIR | awk '/milestone/ { print $9 }'
}

function target_snap_from_bsend_file {
    filename=$1
    echo $(echo $filename | sed -n 's/^[mileston0-9_]*-\(milestone\_[0-9]*\)\.bsend\.lzo$/\1/p')
}

function gen_milestone_server_dir {
    if [ ! -e $MILESTONE_SRV_DIR ]; then
	mkdir -p $MILESTONE_SRV_DIR
    fi
    (cd $MILESTONE_SRV_DIR
     target=$(get_newest_milestone)
     echo "Newest milestone is: $target"
     if [ -e LATEST ]; then
	 if [ ! $(cat LATEST) == "$target" ]; then
	     echo "New milestone detected, deleting deprecated files"
	     rm $MILESTONE_SRV_DIR/*
	 fi
     fi
     echo $target > LATEST
     parents="$(get_milestones) /" 
     for parent in $parents; do
	 # Wankery to correct for not having a parent name for an
	 # initial bsend file
	 if [ "${parent:0:1}" == "/" ]; then
	     parent=${parent:1}
	     outfile=${target}.bsend.lzo
	 else
	     outfile=${parent}-${target}.bsend.lzo
	 fi
	 # Don't try to generate a diff between a snapshot and itself
	 if [ "$parent" == "$target" ]; then
	     continue
	 fi
	 if [ ! -e $outfile ]; then
	     echo "Generating $outfile"
	     if [ -z "$parent" ]; then
		 # No parent, send all the datas
		 btrfs send $SNAPSHOT_DIR/$target | lzop -o $outfile
	     else
		 # Diff to upgrade one snap to the next
		 btrfs send -p $SNAPSHOT_DIR/$parent $SNAPSHOT_DIR/$target | lzop -o $outfile
	     fi
	     md5sum -- "$outfile" >> MD5SUMS
	 else
	     echo "Found existing $outfile, skipping"
	 fi
    done
    )
}
