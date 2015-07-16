# function find_btrfs_parts {
#     disk_dev=$1
#     if [ -n "$disk_dev" ]; then
# 	disk=$INTERNAL_DISK
# 	if [ -n "$INTERNAL_DISK" ]; then
# 	    disk=$(find_internal_disk)
# 	fi
#     fi
#     echo $(find_parts_by_fstype $disk_dev btrfs)
# }   

# function gen_btrfs_send {
#     parent_snap=$1
#     target_snap=$2
#     outfile=${SNAPSHOT_DIR}/${parent_snap}-${target_snap}.btrsend.lzo
#     btrfs send -p $parent_snap $target_snap | lzo -o $outfile
# }

# function target_snap_from_bsend_file {
#     filename=$1
#     echo $(echo $filename | sed -n 's/^[mileston0-9_]*-\(milestone\_[0-9]*\)\.bsend\.lzo$/\1/p')
# }

# function set_btrfs_default_subvol_by_name {
#     fs_mountpoint=$1
#     subvol_name=$2
#     subvol_id=$(btrfs subvolume list ${fs_mountpoint}|awk -v subvol_name="$subvol_name" '{if ($9 == subvol_name) { print $2 }}')
#     if [ ! "$subvol_id" == "" ]; then
# 	btrfs subvolume set-default ${subvol_id} ${fs_mountpoint}
#     else
# 	echo "set_btrfs_default_subvol_by_name: Couldn't find subvol name = \"$subvol_name\" on mountpoint = \"$fs_mountpoint\""
#     fi
# }

# function mount_client_btrfs_root {
#     mount_client_linux
#     btrfs subvolume set-default 0 ${LOCAL_LINUX_DIR}
#     umount_client_linux
#     mount_client_linux
# }

# function mount_client_def_subvol {
#     umount_client_linux
#     mount_client_linux
# }
