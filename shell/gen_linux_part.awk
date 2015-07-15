#!/usr/bin/awk -f

BEGIN {
    start=0;
    last=0;
    last_part=0;
    size=0;
    disk=0;
}

{
    if($1 ~ /last-lba/)
	last=$2;
    if($1 ~ /^\/dev/) {
	disk=$1;
	gsub(/[0-9]/, "", disk);
	gsub(/,/, "", $6);
	gsub(/,/, "", $4);
	if ($6+$4 > start) {
	    start=(($6+$4)/2048+1)*2048;
	    size=last-start;
	}
	gsub(/[a-zA-Z\/]/, "", $1);
	last_part=$1 > last_part ? $1 : last_part;
    }
}
END {
    OFS="\n";
    printf("%s%s : start=%s, size=%s, type=%s\n", disk, last_part+1, start, size, "0FC63DAF-8483-4772-8E79-3D69D8477DE4")
}
