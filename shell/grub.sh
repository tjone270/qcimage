function grub_qcimage_cfg {
    efi_part=$(find_internal_efi)
    efi_uuid=$(uuid_from_part $efi_part)
    linux_uuid=$(uuid_from_part $LOCAL_LINUX_PART)
    (cd /qcimage/grub
     sed -e "s,x_INTERNAL_EFI_UUID,${efi_uuid},g" -e "s,x_INTERNAL_LINUX_UUID,${linux_uuid},g" grub.cfg.header
     sed -e "s,x_INTERNAL_EFI_UUID,${efi_uuid},g" -e "s,x_INTERNAL_LINUX_UUID,${linux_uuid},g" grub.cfg.linux
     sed -e "s,x_INTERNAL_EFI_UUID,${efi_uuid},g" -e "s,x_INTERNAL_LINUX_UUID,${linux_uuid},g" grub.cfg.windows
     sed -e "s,x_INTERNAL_EFI_UUID,${efi_uuid},g" -e "s,x_INTERNAL_LINUX_UUID,${linux_uuid},g" grub.cfg.logic

    )
}

function uuid_from_part {
    part=$1
    blkid $part  |awk -F\" '{print $2}'
}
