# This file holds the tunable variables, basically everything I
# thought might conceivably change 

DISKS=$(lsblk -o TYPE,NAME|awk '/disk/ {print $2}')
INTERNAL_DISK=
WINDOWS_PART=
WINDOWS_SHIT=( pagefile.sys hiberfile.sys )
LOCAL_LINUX_PART=
LOCAL_LINUX_DIR=/client_linux
ADMIN_LINUX_PART=
ROOT_PART=$(mount|awk '/on \/ / {print $1}')
#PLAYER_DISK=/dev/sdb1
RAW_IMAGE_DIR=/images
#PLAYER_DIR=/joueur
WINDOWS_DIR=/windows
REPO_DIR=/repo
SNAPSHOT_DIR=/snapshots
QCIMAGE_MODE=

# Where we host bsend files, must be on subvolume to avoid inclusion
# in future milstone snaps
MILESTONE_SRV_DIR=$SNAPSHOT_DIR/milestone_srv

# Rsync info for demo backup
DEMOS_USER=
DEMOS_KEY=
DEMOS_SERVER=
DEMOS_PATH=

#HANDLE=
#GUID=
#DIFF=

#function init_player_settings {
#    if [ ! -e $PLAYER_DIR/.qcimage ]; then
#	HANDLE=`cat $WINDOWS_DIR/.qcimage/handle`
#	GUID=`cat $WINDOWS_DIR/.qcimage/guid`
#	DIFF=${PLAYER_DIR}/.qcimage/diff
#    else
#	# The absence of the directory indicates image creation
#	HANDLE=`cat ${PLAYER_DIR}/.qcimage/handle`
#	GUID=`cat ${PLAYER_DIR}/.qcimage/guid`
#	DIFF=${PLAYER_DIR}/.qcimage/diff
#    fi
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

function find_internal_disk {
    # Find the first enumerated disk whose first partition is ntfs and
    # contains a "Windows" folder.
    for disk in $DISKS; do
	disk_dev=/dev/$disk
	first_part_fstype=$(get_partition_fstype ${disk_dev}1)
	echo "Checking $disk @ $disk_dev, type $first_part_fstype"
	if [ "${first_part_fstype}" == "ntfs" ]; then
	    tmpdir=$(mktemp -d)
	    mount ${disk_dev}1 ${tmpdir}
	    if [ -e ${tmpdir}/Windows ]; then
		INTERNAL_DISK=${disk_dev}
		WINDOWS_PART=${INTERNAL_DISK}1
		LOCAL_LINUX_PART=${INTERNAL_DISK}2
	    fi
	    umount ${tmpdir} && rm -r ${tmpdir}
	fi
    done
}

function detect_mode {
    if [ "$ROOT_PART" == "$LOCAL_LINUX_PART" ]; then
	# We're booted from the linux on the internal disk
	QCIMAGE_MODE="local"
    else
	QCIMAGE_MODE="admin"
	ADMIN_LINUX_PART=$ROOT_PART
    fi
}

detect_mode
find_internal_disk
export QCIMAGE_MODE INTERNAL_DISK RAW_IMAGE_DIR REPO_DIR WINDOWS_DIR SNAPSHOT_DIR
export DISKS WINDOWS_PART LOCAL_LINUX_PART ADMIN_LINUX_PART ROOT_PART
