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

function find_msr {
    sfdisk --dump $INTERNAL_DISK| awk -F: '/E3C9/ {print $1}'
}

function save_msr {
    dd if=$(find_msr) of=/images/msr.img bs=8M
}

function restore_msr {
    dd if=/images/msr.img of=$(find_msr) bs=8M
}

function save_windows {
  # This function makes new windows clone images
  save_mbr
  remove_windows_cruft
  save_msr
  for part in $(find_ntfs_parts|grep $INTERNAL_DISK); do
      echo $part
      part_num=$(expr match "$part" '[a-z]*\([0-9]*\)')
      image_file=$RAW_IMAGE_DIR/${part: -1}.ntfs.img
      if [ ! -e $image_file ]; then
	  echo "save_windows: No previous $image_file, creating new one"
	  ntfsclone $part -o $image_file
      else
	  echo "save_windows: Updating existing $image_file image"
	  # So, if we unlink the file, btrfs cannot track the
	  # changes... so we jump through a hoop to only change the needed blocks
	  compare_image_update_in_place ${part} ${image_file}
      fi
  done
}

function get_ntfs_cluster_size {
    part=$1
    if [ -z $part ]; then
	part=$WINDOWS_PART
    fi
    ntfsinfo -fm $part | awk '/Cluster Size:/ { print $3 }'
}

function get_ntfs_num_clusters {
    part=$1
    if [ -z $part ]; then
	part=$WINDOWS_PART
    fi
    ntfsinfo -fm $part | awk '/Size in Clusters:/ { print $5 }'
}

function get_ntfs_size {
    # Returns volume size in bytes
    echo $(( $(get_ntfs_cluster_size) * $(get_ntfs_num_clusters) ))
}

function resize_ntfs {
    part=$1
    if [ -n $part ]; then
	part=$WINDOWS_PART
    fi
    disk=$(expr match "$part" '\([/a-z]*\)')
    part_num=$(expr match "$part" '[/a-z]*\([0-9]*\)')
    ntfsresize -ffs $(( $(get_ntfs_size) / 2 )) $WINDOWS_PART
    start=$(parted -s $disk unit B print |awk -vpart_num="$part_num" 'match($1, part_num) {print $2 }')
    start=${start:0: -1} # Strip trailing B
    echo "Partition starts at: $start"
    echo $(get_ntfs_size)
    end=$(( $start + $(get_ntfs_size) ))
    echo $end
    cat<<EOF |parted ---pretend-input-tty $disk 
resizepart $part_num ${end}B
Yes
quit
EOF
}
