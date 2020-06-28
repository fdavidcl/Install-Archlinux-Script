#!/bin/bash

# This is an auxiliary script that is used after chroot the base system
say(){ echo -e "\n\e[1m\e[33m[ $@ ]\e[m"; }

say "Setting locales"
sed -i.bak -e 's/#es_ES.UTF-8/es_ES.UTF-8/; s/en_US.UTF-8/#en_US.UTF-8/' /etc/locale.gen
locale-gen
echo LANG=es_ES.UTF-8 > /etc/locale.conf
export LANG=es_ES.UTF-8

say "Setting the time zone"
ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime

say "Installing ntp and setting UTC"
pacman -S ntp --noconfirm && ntpd -qg
hwclock --systohc --utc

read -p "Type the hostname: " HOSTNAME
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
" >> /etc/hosts

say "Installing WiFi support"
pacman -S wpa_supplicant dialog --noconfirm

say "Creating an initial ramdisk environment"
mkinitcpio -p linux

# Set the root password
say "Set root password"
passwd

# Install GRUB
if [[ -d /boot/efi ]]; then
  say "Installing bootloader"
  pacman -S grub efibootmgr os-prober --noconfirm

  grub-install --target=x86_64-efi
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# Install more packages
say "Installing main packages"
pacman -S gnome firefox tilix arandr audacity clementine code cups   \
  emacs firefox fish fwupd gdm gnome-tweaks pandoc pandoc-citeproc   \
  hledger hledger-web hplip imagemagick jupyter jupyterlab kdenlive  \
  krita nfs-utils mesa-demos networkmanager okular xournalpp git     \
  pavucontrol python-tensorflow-opt python-scikit-learn python-scipy \
  qemu r remmina ruby sane sof-firmware texlive-bibtexextra          \
  texlive-bin texlive-core texlive-fontsextra texlive-formatsextra   \
  texlive-latexextra texlive-pictures texlive-publishers obs-studio  \
  texlive-science thunderbird wpa_supplicant youtube-dl ntfs-3g      \
  systemd-swap chrome-gnome-shell                                    \
  --noconfirm

say "Replacing GNOME Terminal by Tilix"
pacman -Rc gnome-terminal --noconfirm
ln -s /usr/bin/tilix /usr/bin/gnome-terminal

say "Now installing AUR helper"
cd /tmp
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri --noconfirm
cd /

say "Installing AUR packages"

pikaur -S gnome-shell-extension-blyr \
  gnome-shell-extension-extended-gestures-git  \
  freetype2-cleartype nord-tilix nordic-theme-git obs-xdg-portal-git \
  system76-power gnome-shell-extension-dash-to-panel \
  gnome-shell-extension-workspaces-to-dock \
  --noconfirm --noedit --nodiff

say "Enabling modules"
echo "system76" > /etc/modules-load.d/system76.conf

say "Enabling services"
systemctl enable NetworkManager
systemctl enable gdm
systemctl enable org.cups.cupsd

# Set ES to wireless region
sed -i.bak -e 's/#WIRELESS_REGDOM="ES"/WIRELESS_REGDOM="ES"/' /etc/conf.d/wireless-regdom


say "Creating first user"
sed -i.bak -e 's/# %wheel ALL=/%wheel ALL=/' /etc/sudoers
read -p "Type the username: " USERNAME
useradd -m -g users -G wheel $USERNAME

say "Setting your shell"
chsh -s /usr/bin/fish fdavidcl
su $USERNAME -c "curl -L https://get.oh-my.fish | fish; omf install pure"

say "Installing Code extensions"
exts=("ACharLuk.fenix" "alexanderte.dainty-nord-vscode" "goessner.mdmath" "jebbs.markdown-extended" "ms-python.python" "Ikuyadeu.r")
for ext in "${exts[@]}"; do
  su $USERNAME -c "code --install-extension $ext"
done

say "Updating firmware"
fwupdmgr enable-remote lvfs-testing --assume-yes
fwupdmgr get-devices
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update --no-reboot-check
fwupdmgr disable-remote lvfs-testing --assume-yes

say "Saving guides and stuff for later use"

cat <<EOF
Guides on how to optimize power efficiency on laptops:

 - https://www.reddit.com/r/thinkpad/comments/alol03/tips_on_decreasing_power_consumption_under_linux/
 - https://medium.com/@amanusk/an-extensive-guide-to-optimizing-a-linux-laptop-for-battery-life-and-performance-27a7d853856c
EOF >> /home/$USERNAME/battery-guides.txt