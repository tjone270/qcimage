# This file holds the tunable variables, basically everything I
# thought might conceivably change 

function qcimage_settings_main {

    DISKS=$(lsblk -o TYPE,NAME|awk '/disk/ {print $2}')
    ROOT_PART=$(mount|awk '/on \/ / {print $1}')

    # Identifies the disk inside the computer, as opposed to a USB
    # Device.
    INTERNAL_DISK=$(find_internal_disk)

    WINDOWS_PART=$(find_windows_part)
    WINDOWS_DIR=/windows
    WINDOWS_SHIT=( pagefile.sys hiberfile.sys )

    LOCAL_LINUX_TEMPLATE=/images/internal_linux.tgz
    LOCAL_LINUX_PART=$(find_local_linux)
    LOCAL_LINUX_DIR=/client_linux

    ADMIN_DISK=$(find_admin_part|sed -e 's/[0-9]//g')
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
    #MILESTONE_SRV_DIR=$SNAPSHOT_DIR/milestone_srv
    #
    RAW_IMAGE_DIR=/images
    
    REPO_DIR=/repo
    
    #SNAPSHOT_DIR=/snapshots
    
    # Rsync info for demo backup
    DEMOS_USER=demos_bak
    DEMOS_KEY=/qcimage/resources/demos_rsa
    DEMOS_SERVER=qctdu.at.quakecon.org
    DEMOS_PATH=$(get_mac_addr)/

    PATH=$PATH:/qcimage/shell
    
    export QCIMAGE_MODE INTERNAL_DISK RAW_IMAGE_DIR REPO_DIR WINDOWS_DIR SNAPSHOT_DIR LOCAL_LINUX_TEMPLATE
    export DISKS WINDOWS_PART LOCAL_LINUX_PART LOCAL_LINUX_DIR ADMIN_LINUX_PART ROOT_PART ADMIN_LINUX_DIR ADMIN_DISK PATH
}

function get_mac_addr {
    ip link | awk '/link\/ether/ {print $2}' |head -n1
}

function find_internal_disk {
    # We assume that only a windows system disk would have an MSR
    find_parts_by_parttype ebd0a0a2-b9e5-4433-87c0-68b6b72699c7|sed -e 's/[0-9]//'
}

function find_admin_part {
    # Find the first enumerated disk whose second partition is btrfs
    for disk in $DISKS; do
	first_part_dev=/dev/${disk}2
	if [ "$(get_partition_fstype $first_part_dev)" == "btrfs" ]; then
	    echo $first_part_dev
	    break
	fi
    done
}

# function find_windows_part {
#     disk_dev=$INTERNAL_DISK
#     if [ -n "$disk_dev" ]; then
# 	disk_dev=$(find_internal_disk)
#     fi
#     for part in $(find_ntfs_parts |grep $disk_dev); do
# 	tmpdir=$(mktemp -d)
# 	# Try to mount to check for /Windows directory, on failure
# 	# assume first NTFS partition. Failure usually due to being
# 	# already mounted
	
# 	if ! mount $part $tmpdir; then
# 	    #echo $part
#             #return
# 	    echo "nigga please"
# 	fi
# 	for name in WINDOWS Windows windows; do
# 	    if [ -e ${tmpdir}/$name ]; then
# 		umount ${tmpdir} && rm -r ${tmpdir}
# 		echo ${part}
# 		return 0
# 	    fi
# 	done
# 	umount ${tmpdir} && rm -r ${tmpdir}
#     done
# }

function find_local_linux {
    disk_dev=$INTERNAL_DISK
    if [ -n "$disk_dev" ]; then
	disk_dev=$(find_internal_disk)
    fi
    for part in $(find_linux_parts $disk_dev); do
	echo $part
	break
    done
}


