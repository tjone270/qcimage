function install_local_linux {
    umount_client_linux
    # Create a linux part using remaining space
    if [ ${LOCAL_LINUX_PART}x == "x" ]; then
	make_local_linux_part
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
    systemctl --root $tmpdir enable qcimage_reset
    systemctl --root $tmpdir enable qcimage_reclone
}
    
