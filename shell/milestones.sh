# function clear_milestones {
#     fs=$1
#     btrfs subvolume list $fs | awk '/milestone/ {print $9}' |xargs -i btrfs subvolume delete $fs{}
# }

# function gen_milestone {
#     snap_name=milestone_$(date +%s)
#     echo $snap_name > /.milestone
#     btrfs subvolume snapshot -r / ${SNAPSHOT_DIR}/$snap_name
# }

# function milestone_present_p {
#     milestone=$1
#     fs=$2
#     for m in $(get_milestones $2); do
# 	if [ "$m" == "$milestone" ]; then
# 	    return 0
# 	fi
#     done
#     return 1
# }

# function get_newest_milestone {
#     echo $(get_milestones $@ | tail -n1)
# }

# function get_oldest_milestone {
#     echo $(get_milestones $@| head -n1)
# }

# function get_milestones {
#     fs=$1
#     if [ -z $fs ]; then
# 	fs=/
#     fi
#     btrfs subvolume list $fs/$SNAPSHOT_DIR | awk '/milestone/ { print $9 }'
# }

# function gen_milestone_server_dir {
#     if [ ! -e $MILESTONE_SRV_DIR ]; then
# 	mkdir -p $MILESTONE_SRV_DIR
#     fi
#     (cd $MILESTONE_SRV_DIR
#      target=$(get_newest_milestone)
#      echo "Newest milestone is: $target"
#      if [ -e LATEST ]; then
# 	 if [ ! $(cat LATEST) == "$target" ]; then
# 	     echo "New milestone detected, deleting deprecated files"
# 	     rm $MILESTONE_SRV_DIR/*
# 	 fi
#      fi
#      echo $target > LATEST
#      parents="$(get_milestones /) /" 
#      for parent in $parents; do
# 	 # Wankery to correct for not having a parent name for an
# 	 # initial bsend file
# 	 if [ "${parent:0:1}" == "/" ]; then
# 	     parent=${parent:1}
# 	     outfile=${target}.bsend.lzo
# 	 else
# 	     outfile=${parent}-${target}.bsend.lzo
# 	 fi
# 	 # Don't try to generate a diff between a snapshot and itself
# 	 if [ "$parent" == "$target" ]; then
# 	     continue
# 	 fi
# 	 if [ ! -e $outfile ]; then
# 	     echo "Generating $outfile"
# 	     if [ -z "$parent" ]; then
# 		 # No parent, send all the datas
# 		 btrfs send $SNAPSHOT_DIR/$target | lzop -o $outfile
# 	     else
# 		 # Diff to upgrade one snap to the next
# 		 btrfs send -p $SNAPSHOT_DIR/$parent $SNAPSHOT_DIR/$target | lzop -o $outfile
# 	     fi
# 	     md5sum -- "$outfile" >> MD5SUMS
# 	 else
# 	     echo "Found existing $outfile, skipping"
# 	 fi
#     done
#     )
# }
