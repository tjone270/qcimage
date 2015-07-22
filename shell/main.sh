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
    plymouth display-message --text "Restoring GPT"
    restore_mbr
    plymouth display-message --text "Restoring EFI Partition"
    restore_efi
    plymouth display-message --text "Restoring MSR"
    restore_msr
    plymouth display-message --text "Restoring NTFS Partitions"
    restore_windows
    if [ $QCIMAGE_MODE == "admin" ]; then
	install_local_linux
    fi
    boot_windows
}

function qcimage_reset {
    plymouth display-message --text "Reseting Machine"
    repo_reset
    boot_windows
}

function qcimage_capture {
    plymouth display-message --text "Saving GPT"
    save_mbr
    plymouth display-message --text "Saving EFI"
    save_efi
    plymouth display-message --text "Saving MSR"
    save_msr
    plymouth display-message --text "Initializing Local Repo"
    repo_init
    plymouth display-message --text "Cloning NTFS"
    save_windows
    boot_windows
}

function qcimage_resize {
    resize_ntfs
    boot_windows
}

function boot_windows {
    plymouth display-message --text "Reseting Machine"
    if [ $QCIMAGE_MODE == "admin" ]; then
	grub-reboot 4
	mount_client_linux
	grub-reboot --boot-directory=/client_linux/boot "windows"
	reboot
    else
	grub-reboot "windows"
	reboot
    fi
}

qcimage_settings_main

if [ $# = 1 ]; then
  # If we're being executed directly, run the right function
  qcimage_$1
fi
