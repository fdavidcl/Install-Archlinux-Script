#!/usr/bin/env bash

say(){ echo -e "\n\e[1m\e[36m[ $@ ]\e[m"; }

if [[ $# -ne 2 ]]; then
cat <<EOF
========================================================

  Arch Linux Installer

--------------------------------------------------------
  Usage:
  Please specify the partition to use as root (/)
    ./install.sh /dev/sdXY
    ./install.sh /dev/nvmeXnYpZ
  This partition will be FORMATTED as Btrfs
========================================================

EOF
exit 1
fi

cat <<EOF
========================================================

  Arch Linux Installer

--------------------------------------------------------
  Based on analca3's script.
  Steps:
    1. Use ES locale with US keyboard
    2. Partition GPT disk
    3. Use OSL mirror to download packages

--------------------------------------------------------
  Please connect to the Internet before running this
  script.
========================================================

Disclaimer: this script could potentially break your 
system. It is provided without any warranty that it 
will do anything useful. Continue only if you know 
what you're doing.

EOF

read -p "Continue? (y/n) " RESPONSE

while [ "${RESPONSE,,}" != "y" ] && [ "${RESPONSE,,}" != "n" ]; do
  echo "Please answer y or n"
  read -p "Continue? (y/n) " RESPONSE
done

if [ "${RESPONSE,,}" == "n" ]; then
  exit 0
fi

# Set locale and generate it/them
say "Setting ES locale"
sed -i.bak -e 's/#es_ES.UTF-8/es_ES.UTF-8/; s/en_US.UTF-8/#en_US.UTF-8/' /etc/locale.gen
locale-gen
export LANG=es_ES.UTF-8


read -p "You have chosen to format $1 as root. THIS WILL ERASE YOUR DATA.\nContinue? (y/n) " RESPONSE

while [ "${RESPONSE,,}" != "y" ] && [ "${RESPONSE,,}" != "n" ]; do
  echo "Please answer y or n"
  read -p "Continue? (y/n) " RESPONSE
done

if [ "${RESPONSE,,}" == "n" ]; then
  exit 0
fi

mkfs.btrfs $1

# Mount the partitions
say "Mounting root partition"
mount $1 /mnt
# unset mountpoints[$ROOT]

say "Checking UEFI support"
installgrub=1

(ls /sys/firmware/efi/efivars > /dev/null) || (
  installgrub=0
  echo "UEFI not supported. This script will not install a bootloader."
)
if [[ $installgrub -eq 1 ]]; then
  efi=$(lsblk -o NAME,PARTTYPENAME -l | grep "EFI System" | cut -d" " -f1)

  read -p "/dev/$efi was detected as EFI System Partition. Mount in /boot/efi? (y/n)" RESPONSE

  while [ "${RESPONSE,,}" != "y" ] && [ "${RESPONSE,,}" != "n" ]; do
    echo "Please answer y or n"
    read -p "Continue? (y/n) " RESPONSE
  done

  if [ "${RESPONSE,,}" == "n" ]; then
    echo "Bootloader will not be installed"
    installgrub=0
  fi

  if [[ $installgrub -eq 1 ]]; then
    mount /dev/$efi /mnt/boot/efi
  fi
fi

# Select a mirror and update pacman database
say "Selecting the OSL mirror"
sed -i.bak '1iServer = http://osl.ugr.es/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist

say "Updating pacman database"
pacman -Syy

# Install the base system
say "Installing your system"
pacstrap -i /mnt base base-devel linux linux-firmware --noconfirm

# Generate an fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Download chroot script
wget https://github.com/fdavidcl/Install-Archlinux-Script/raw/master/in_chroot.sh -O /mnt/in_chroot.sh

# Chroot and configure
arch-chroot /mnt /bin/bash -c "chmod u+x in_chroot.sh && ./in_chroot.sh"

# Umount all partitions
umount -R /mnt

echo "Voilá! Reboot your system and enjoy Archlinux!"
