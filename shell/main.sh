#!/bin/bash


for file in $(find /qcimage/shell -name \*.sh); do
    filename=$(basename $file)
    if [ "$filename" == "main.sh" -o "${filename:0:1}" == "." ]; then
	continue
    fi
    echo "Sourcing $file"
    . $file
done

function qcimage_reclone {
    plymouth display-message --text "Recloning from image files"
    sleep 60
    #boot_windows
}

function qcimage_reset {
    plymouth display-message --text "Reseting via git"
    sleep 60
    #repo_reset
    #boot_windows
}

qcimage_settings_main

if [ $# = 1 ]; then
  # If we're being executed directly, run the right function
  qcimage_$1
fi
