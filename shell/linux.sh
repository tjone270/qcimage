function install_local_linux {
    mkfs.btrfs -f $LOCAL_LINUX_PART
    tmpdir=$(mktemp -d)
    mount $LOCAL_LINUX_PART $tmpdir
    mkdir $tmpdir/boot
    umount ${tmpdir} && rm -r ${tmpdir}
    mount_client_linux
    install_qcimage
    cp -an ${LOCAL_LINUX_TEMPLATE}/* $LOCAL_LINUX_DIR
    arch-chroot $LOCAL_LINUX_DIR /root/fix_boot.sh
    grub_qcimage_cfg 2>/dev/null > $LOCAL_LINUX_DIR/boot/grub/grub.cfg
}

function install_qcimage {
    qcdir=${LOCAL_LINUX_TEMPLATE}/qcimage
    cp -r /qcimage ${LOCAL_LINUX_TEMPLATE}
    ln $qcdir/linux_root/etc/profile.d/qcimage.sh ${LOCAL_LINUX_TEMPLATE}/etc/profile.d/qcimage.sh
    ln $qcdir/linux_root/etc/systemd/system/* ${LOCAL_LINUX_TEMPLATE}/etc/systemd/system
    systemctl --root /images/internal_linux enable qcimage_reset
    systemctl --root /images/internal_linux enable qcimage_reclone
}
    
