function install_local_linux {
    mkfs.btrfs -f $LOCAL_LINUX_PART
    tmpdir=$(mktemp -d)
    mount $LOCAL_LINUX_PART $tmpdir
    mkdir $tmpdir/boot
    umount ${tmpdir} && rm -r ${tmpdir}
    mount_client_linux
    cp -an ${LOCAL_LINUX_TEMPLATE}/* $LOCAL_LINUX_DIR
    arch-chroot $LOCAL_LINUX_DIR /root/fix_boot.sh
    grub_qcimage_cfg 2>/dev/null > $LOCAL_LINUX_DIR/boot/grub/grub.cfg
}

