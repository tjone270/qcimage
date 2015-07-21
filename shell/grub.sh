function grub_qcimage_cfg {
    efi_part=$(find_internal_efi)
    efi_uuid=$(uuid_from_part $efi_part)
    linux_uuid=$(uuid_from_part $LOCAL_LINUX_PART)
    windows_uuid=$(uuid_from_part $WINDOWS_PART)
    (cd /qcimage/grub
     sed -e "s,x_EFI_UUID,${efi_uuid},g" -e "s,x_LINUX_UUID,${linux_uuid},g" -e "s,x_WINDOWS_UUID,${windows_uuid},g" grub.cfg.header
     sed -e "s,x_EFI_UUID,${efi_uuid},g" -e "s,x_LINUX_UUID,${linux_uuid},g" -e "s,x_WINDOWS_UUID,${windows_uuid},g" grub.cfg.linux
     sed -e "s,x_EFI_UUID,${efi_uuid},g" -e "s,x_LINUX_UUID,${linux_uuid},g" -e "s,x_WINDOWS_UUID,${windows_uuid},g" grub.cfg.windows
     sed -e "s,x_EFI_UUID,${efi_uuid},g" -e "s,x_LINUX_UUID,${linux_uuid},g" -e "s,x_WINDOWS_UUID,${windows_uuid},g" grub.cfg.logic

    )
}

function grub_qcimage_cfg_admin {
    disk=$1
    if [ "${disk}x" == "x" ]; then
	efi_part=$(find_admin_efi)
	efi_uuid=$(uuid_from_part $efi_part)
	linux_uuid=$(uuid_from_part $ADMIN_LINUX_PART)
    else
	efi_part=${disk}1
	efi_uuid=$(uuid_from_part $efi_part)
	linux_uuid=$(uuid_from_part ${disk}2)
    fi		
    (cd /qcimage/grub
     sed -e "s,x_EFI_UUID,${efi_uuid},g" -e "s,x_LINUX_UUID,${linux_uuid},g" grub.cfg.header
     sed -e "s,x_EFI_UUID,${efi_uuid},g" -e "s,x_LINUX_UUID,${linux_uuid},g" grub.cfg.linux.admin
     sed -e "s,x_EFI_UUID,${efi_uuid},g" -e "s,x_LINUX_UUID,${linux_uuid},g" grub.cfg.logic.admin
    )
}

function uuid_from_part {
    part=$1
    blkid $part  |awk -F\" '{print $2}'
}
