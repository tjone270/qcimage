#!/bin/bash

grub-install --efi-directory=/boot --bootloader-id=grub --target=x86_64-efi --recheck
mkinitcpio -p qcimage
cp /boot/EFI/grub/grubx64.efi /boot/EFI/boot/bootx64.efi
