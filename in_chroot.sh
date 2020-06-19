#!/bin/bash

# This is an auxiliary script that is used after chroot the base system

# Set locales
echo "[ Setting locales ]"
sed -i.bak -e 's/#es_ES.UTF-8/es_ES.UTF-8/; s/en_US.UTF-8/#en_US.UTF-8/' /etc/locale.gen
locale-gen
echo LANG=es_ES.UTF-8 > /etc/locale.conf
export LANG=es_ES.UTF-8

# Set the time zone
echo "[ Setting the time zone ]"
ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime

# Set UTC
echo "[ Installing ntp and setting UTC ]"
pacman -S ntp --noconfirm && ntpd -qg
hwclock --systohc --utc

# Set hostname
read -p "Type the hostname: " HOSTNAME
echo $HOSTNAME > /etc/hostname

echo "[ Installing WiFi support ]"
pacman -S wpa_supplicant dialog --noconfirm

# Create an initial ramdisk environment
mkinitcpio -p linux

# Set the root password
echo "[ Set root password ]"
passwd

# Install GRUB
if [[ -d /boot/efi ]]; then
  echo "[ Installing bootloader ]"
  pacman -S grub efibootmgr os-prober --noconfirm

  grub-install --target=x86_64-efi
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# Install more packages
echo "[ Installing main packages ]"
pacman -S gnome firefox tilix arandr audacity clementine code cups   \
  emacs firefox fish fwupd gdm gnome-tweaks pandoc pandoc-citeproc   \
  hledger hledger-web hplip imagemagick jupyter jupyterlab kdenlive  \
  krita nfs-utils mesa-demos networkmanager okular xournalpp git     \
  pavucontrol python-tensorflow-opt python-scikit-learn python-scipy \
  qemu r remmina ruby sane sof-firmware texlive-bibtexextra          \
  texlive-bin texlive-core texlive-fontsextra texlive-formatsextra   \
  texlive-latexextra texlive-pictures texlive-publishers             \
  texlive-science thunderbird wpa_supplicant youtube-dl              \
  --noconfirm

echo "[ Now installing AUR helper ]"
cd /tmp
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri --noconfirm
cd /

echo "[ Enabling services ]"
systemctl enable NetworkManager
systemctl enable gdm
systemctl enable org.cups.cupsd

# Set ES to wireless region
sed -i.bak -e 's/#WIRELESS_REGDOM="ES"/WIRELESS_REGDOM="ES"/' /etc/conf.d/wireless-regdom

echo "[ Creating first user ]"
sed -i.bak -e 's/# %wheel ALL=/%wheel ALL=/' /etc/sudoers
read -p "Type the username: " USERNAME
useradd -m -g users -G wheel $USERNAME
