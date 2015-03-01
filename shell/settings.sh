# This file holds the tunable variables, basically everything I
# thought might conceivably change 

function qcimage_settings_main {

    # If we have to resize Windows, this is how large it should be␘
    WINDOWS_PART_SIZE="32" # IN GB
    
    DISKS=$(lsblk -o TYPE,NAME|awk '/disk/ {print $2}')
    ROOT_PART=$(mount|awk '/on \/ / {print $1}')

    # Identifies the disk inside the computer, as opposed to a USB
    # Device.
    INTERNAL_DISK=$(find_internal_disk)

    WINDOWS_PART=$(find_windows_part)
    WINDOWS_DIR=/windows
    WINDOWS_SHIT=( pagefile.sys hiberfile.sys )
    
    LOCAL_LINUX_PART=$(find_local_linux)
    LOCAL_LINUX_DIR=/client_linux
    
    ADMIN_LINUX_PART=$(find_admin_part)
    ADMIN_LINUX_DIR=/admin_linux

    QCIMAGE_MODE=
    if [ "$ROOT_PART" == "$ADMIN_LINUX_PART" ]; then
	QCIMAGE_MODE="admin"
    elif [ "$ROOT_PART" == "$LOCAL_LINUX_PART" ]; then
	QCIMAGE_MODE="local"
    fi
    
    # Where we host bsend files, must be on subvolume to avoid inclusion
    # in future milstone snaps
    MILESTONE_SRV_DIR=$SNAPSHOT_DIR/milestone_srv
    
    RAW_IMAGE_DIR=/images
    
    REPO_DIR=/repo
    
    SNAPSHOT_DIR=/snapshots
    
    # Rsync info for demo backup
    DEMOS_USER=
    DEMOS_KEY=
    DEMOS_SERVER=
    DEMOS_PATH=

    export QCIMAGE_MODE INTERNAL_DISK RAW_IMAGE_DIR REPO_DIR WINDOWS_DIR SNAPSHOT_DIR
    export DISKS WINDOWS_PART LOCAL_LINUX_PART LOCAL_LINUX_DIR ADMIN_LINUX_PART ROOT_PART ADMIN_LINUX_DIR
}

function find_internal_disk {
    # Find the first enumerated disk that has an ntfs partition with a
    # "/Windows" folder
    for disk in $DISKS; do
	disk_dev=/dev/$disk
	for part in $(find_ntfs_parts |grep $disk_dev); do
	    tmpdir=$(mktemp -d)
	    mount $part $tmpdir
	    if [ -e ${tmpdir}/Windows ]; then
		echo ${disk_dev}
	    fi
	    umount ${tmpdir} && rm -r ${tmpdir}
	done
    done
}

function find_admin_part {
    # Find the first enumerated disk whose first partition is btrfs
    for disk in $DISKS; do
	first_part_dev=/dev/${disk}1
	if [ "$(get_partition_fstype $first_part_dev)" == "btrfs" ]; then
	    echo $first_part_dev
	    break
	fi
    done
}

function find_windows_part {
    disk_dev=$INTERNAL_DISK
    if [ -n "$disk_dev" ]; then
	disk_dev=$(find_internal_disk)
    fi
    for part in $(find_ntfs_parts |grep $disk_dev); do
	tmpdir=$(mktemp -d)
	mount $part $tmpdir
	if [ -e ${tmpdir}/Windows ]; then
	    umount ${tmpdir} && rm -r ${tmpdir}
	    echo ${part}
	    return 0
	fi
	umount ${tmpdir} && rm -r ${tmpdir}
    done
}

function find_local_linux {
    disk_dev=$INTERNAL_DISK
    if [ -n "$disk_dev" ]; then
	disk_dev=$(find_internal_disk)
    fi
    for part in $(find_linux_parts |grep $disk_dev); do
	echo $part
	break
    done
}


