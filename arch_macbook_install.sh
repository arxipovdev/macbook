#!/bin/bash

# Скрипт для автоматической установки Arch Linux на MacBook Pro 2013
# Пример запуска: 
# curl -sL https://raw.githubusercontent.com/arxipovdev/macbook/main/arch_macbook_install.sh | sudo bash -s -- /dev/sda5 /dev/sda1 Europe/Moscow "user_password"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Error handling
set -euo pipefail

# Verify arguments
if [ $# -ne 4 ]; then
  echo -e "${RED}Error: Required 4 arguments${NC}"
  echo -e "Usage: $0 <root_partition> <efi_partition> <timezone> <user_password>"
  echo -e "Example: $0 /dev/nvme0n1p3 /dev/nvme0n1p1 Europe/Moscow \"P@ssw0rd\""
  exit 1
fi

# Parameters
ROOT_PART="$1"
EFI_PART="$2"
TIMEZONE="$3"
USER_PASSWORD="$4"

# Header function
print_header() {
  echo -e "\n${GREEN}>>> ${YELLOW}$1${NC}"
}

# Cleanup function
cleanup() {
  print_header "Cleaning up"
  umount -R /mnt 2>/dev/null || true
}

trap cleanup EXIT

### MAIN INSTALLATION PROCESS ###

print_header "Mounting partitions"
umount -R /mnt 2>/dev/null || true
mount "$ROOT_PART" /mnt || { echo -e "${RED}Root partition mount failed!${NC}"; exit 1; }
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot || { echo -e "${RED}EFI partition mount failed!${NC}"; exit 1; }

print_header "Initializing pacman keys"
arch-chroot /mnt bash -c "pacman-key --init && pacman-key --populate archlinux"
arch-chroot /mnt bash -c "timedatectl set-ntp true"
arch-chroot /mnt bash -c "pacman -Sy archlinux-keyring --noconfirm"

print_header "Installing base system"
pacstrap /mnt base linux linux-firmware base-devel linux-headers \
          networkmanager network-manager-applet sudo grub efibootmgr \
          nano vim neovim ranger git curl dialog glibc archlinux-keyring \
          dosfstools mtools || { 
          echo -e "${RED}Pacstrap failed!${NC}";
          exit 1; }

print_header "Generating fstab"
genfstab -U /mnt > /mnt/etc/fstab

print_header "Configuring system"
arch-chroot /mnt /bin/bash -ex <<EOF

# Time configuration
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "arch-macbook" > /etc/hostname

# User setup
useradd -m -G wheel -s /bin/bash andrey
echo "andrey:$USER_PASSWORD" | chpasswd

# Sudo configuration
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# NetworkManager
systemctl enable NetworkManager

# Wi-Fi drivers
pacman -S --needed git base-devel --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
yay -S broadcom-wl --noconfirm
echo "wl" > /etc/modules-load.d/broadcom-wl.conf
echo "blacklist brcmfmac" > /etc/modprobe.d/broadcom-wl.conf
echo "blacklist bcma" >> /etc/modprobe.d/broadcom-wl.conf

# Initramfs
mkinitcpio -P

# Bootloader
bootctl --path=/boot install

# Bootloader config
cat > /boot/loader/entries/arch.conf <<CONF
title Arch Linux MacBook
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=$ROOT_PART rw quiet i8042.nopnp=1 pcie_ports=compat
CONF

EOF

print_header "Installation complete!"
echo -e "${GREEN}Successfully installed! Reboot with:${NC}"
echo -e "umount -R /mnt"
echo -e "reboot"
