function install_local_linux {
    umount_client_linux
    # Create a linux part using remaining space
    if [ ${LOCAL_LINUX_PART}x == "x" ]; then
	if make_local_linux_part; then
	    while [ ${INTERNAL_DISK}x == "x" ]; do
		INTERNAL_DISK=$(find_internal_disk)
	    done
	    while [ ${LOCAL_LINUX_PART}x == "x" ]; do
		LOCAL_LINUX_PART=$(find_local_linux)
	    done
	else
	    echo "Failed to create local linux part"
	    return 1
	fi
    fi
    # Format part
    mkfs.btrfs -f $LOCAL_LINUX_PART
    # Create a mountpoint for the ESP
    tmpdir=$(mktemp -d)
    mount $LOCAL_LINUX_PART $tmpdir
    mkdir $tmpdir/boot
    umount ${tmpdir} && rm -r ${tmpdir}
    # Mount internal_linux and internal ESP in the conventional place
    if ! mount_client_linux; then
	echo "Failed to mount client_linux partition"
	return 1
    fi
    # If a current tarball doesn't exist, generate it
    if [ ! -e $LOCAL_LINUX_TEMPLATE ]; then
	gen_linux_template
    fi
    echo "Transferring rootfs"
    tar -C ${LOCAL_LINUX_DIR} -x -f $LOCAL_LINUX_TEMPLATE
    #echo "Copying Image Files"
    #copy_images
    echo "Transferring repo"
    cp -r ${REPO_DIR} ${LOCAL_LINUX_DIR}
    echo "Installing Bootloader"
    if [ ! -e $LOCAL_LINUX_DIR/etc/os-release ]; then
	cp /etc/os-release $LOCAL_LINUX_DIR/etc/os-release
    fi
    arch-chroot $LOCAL_LINUX_DIR /root/fix_boot.sh
    grub_qcimage_cfg 2>/dev/null > $LOCAL_LINUX_DIR/boot/grub/grub.cfg
    umount_client_linux
}

function copy_images {
    mkdir ${LOCAL_LINUX_DIR}${RAW_IMAGE_DIR}
    cp -v ${RAW_IMAGE_DIR}/*{img,desc} ${LOCAL_LINUX_DIR}${RAW_IMAGE_DIR}
}

function gen_linux_template {
    tmpdir=$(mktemp -d)
    if [ -e $LOCAL_LINUX_TEMPLATE ]; then
	rm $LOCAL_LINUX_TEMPLATE
    fi
    pacstrap -c -d ${tmpdir} base git grub ntfs-3g efibootmgr ttf-dejavu mesa-libgl
    rm ${tmpdir}/var/cache/pacman/pkg/*
    install_plymouth $tmpdir
    install_qcimage $tmpdir
    tar -C $tmpdir -c -z -f $LOCAL_LINUX_TEMPLATE .
    rm -rf $tmpdir
    ## FIXME - Link in mkinitcpio.*, fix_boot.sh
}

function install_plymouth {
    tmpdir=$1
    if [ ${tmpdir}x == "x" ]; then
	echo "Error: Refusing to install plymouth on real root"
	return 1
    fi
    cp /qcimage/resources/plymouth.tar.xz $tmpdir/root
    arch-chroot $tmpdir /usr/bin/pacman --noconfirm -U /root/plymouth.tar.xz
    systemctl --root $tmpdir disable plymouth-quit.service
    systemctl --root $tmpdir disable plymouth-quit-wait.service
    rm ${tmpdir}/lib/systemd/system/plymouth-quit*
    systemctl --root $tmpdir disable getty@tty0.service
}

function install_qcimage {
    tmpdir=$1
    if [ ${tmpdir}x == "x" ]; then
	echo "Error: Refusing to install qcimage on real root"
	return 1
    fi
    cp -r /qcimage ${tmpdir}
    qclinroot=${tmpdir}/qcimage/linux_root
    ln $qclinroot/etc/profile.d/qcimage.sh ${tmpdir}/etc/profile.d/qcimage.sh
    ln $qclinroot/etc/systemd/system/* ${tmpdir}/etc/systemd/system
    rm ${tmpdir}/etc/mkinitcpio.conf
    ln $qclinroot/etc/mkinitcpio.conf ${tmpdir}/etc
    ln $qclinroot/etc/mkinitcpio.d/qcimage.preset ${tmpdir}/etc/mkinitcpio.d
    ln $qclinroot/root/fix_boot.sh ${tmpdir}/root/fix_boot.sh
    cp $qclinroot/etc/netctl/wired ${tmpdir}/etc/netctl
    cp $qclinroot/etc/netctl/interfaces/en-any ${tmpdir}/etc/netctl/interfaces
    systemctl --root $tmpdir enable qcimage_reset
    systemctl --root $tmpdir enable qcimage_reclone
    systemctl --root $tmpdir enable netctl@wired
}
    
function install_admin_linux {
    usb_disk=$1
    efi_part=${usb_disk}1
    root_part=${usb_disk}2
    if [ "${usb_disk}x" == "x" ]; then
	echo "Provide storage device path as first arguement"
	return
    fi
    if [ "$usb_disk" == "$INTERNAL_DISK" ]; then
	echo "Refusing to clobber internal disk"
	return
    fi
    if [ "$usb_disk" == "$ADMIN_DISK" ]; then
	echo "Refusing to clobber admin disk"
	return
    fi
    cat /qcimage/resources/admin_usb_gpt.desc | sfdisk $usb_disk
    partprobe
    mkfs.vfat -F32 $efi_part
    mkfs.btrfs -f $root_part
    tmp_root_mnt=$(mktemp -d)
    mount $root_part $tmp_root_mnt
    fstrim $tmp_root_mnt
    mkdir $tmp_root_mnt/boot
    tmp_snap=/rootsnap
    mount $efi_part $tmp_root_mnt/boot
    btrfs subvolume snapshot / $tmp_snap
    tar -C $tmp_snap --exclude=./images/* --exclude=./repo/* -c . | tar -C $tmp_root_mnt -x -v 
    cp -r /boot/{initramfs-linux-fallback.img,initramfs-linux.img,vmlinuz-linux} $tmp_root_mnt/boot
    cp $tmp_root_mnt/qcimage/linux_root/root/fix_boot.sh $tmp_root_mnt/root
    arch-chroot $tmp_root_mnt /root/fix_boot.sh
    grub_qcimage_cfg_admin > $tmp_root_mnt/boot/grub/grub.cfg
    mkdir -p $tmp_root_mnt/boot/EFI/boot
    cp $tmp_root_mnt/boot/EFI/grub/grubx64.efi $tmp_root_mnt/boot/EFI/boot/bootx64.efi
    umount $tmp_root_mnt/boot
    umount $tmp_root_mnt
    btrfs subvolume delete $tmp_snap
}
