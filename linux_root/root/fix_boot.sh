#!/bin/bash

grub-install --efi-directory=/boot --bootloader-id=grub --target=x86_64-efi --recheck
mkinitcpio -p qcimage
