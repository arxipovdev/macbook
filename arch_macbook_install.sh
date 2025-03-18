#!/bin/bash

# Скрипт для автоматической установки Arch Linux на MacBook Pro 2013
# Пример запуска: 
# curl -sL https://raw.githubusercontent.com/arxipovdev/macbook/main/arch_macbook_install.sh | sudo bash -s -- /dev/sda5 /dev/sda1 Europe/Moscow "user_password"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Проверка аргументов
if [ $# -ne 4 ]; then
  echo -e "${RED}Error: Required 4 arguments${NC}"
  echo "Usage:"
  echo "$0 <root_partition> <efi_partition> <timezone> <user_password>"
  echo "Example: $0 /dev/sda5 /dev/sda1 Europe/Moscow \"MySecureP@ss\""
  exit 1
fi

# Параметры
root_part="$1"
efi_part="$2"
timezone="$3"
user_password="$4"

# Функция для вывода заголовков
print_header() {
  echo -e "\n${GREEN}>>> $1${NC}"
}

### Начало установки ###
print_header "Mounting partitions"
umount -R /mnt 2>/dev/null
echo "Mounting root partition $root_part to /mnt"
mount "$root_part" /mnt || { echo -e "${RED}Mount failed!${NC}"; exit 1; }
mkdir -p /mnt/boot
echo "Mounting EFI partition $efi_part to /mnt/boot"
mount "$efi_part" /mnt/boot || { echo -e "${RED}EFI mount failed!${NC}"; exit 1; }

print_header "Installing base packages"
pacstrap /mnt base linux linux-firmware base-devel linux-headers \
          networkmanager network-manager-applet sudo grub efibootmgr \
          nano vim neovim ranger git curl dialog glibc || { echo -e "${RED}Pacstrap failed!${NC}"; exit 1; }

print_header "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab || { echo -e "${RED}Fstab generation failed!${NC}"; exit 1; }

### Настройка системы внутри chroot ###
print_header "Entering chroot"
arch-chroot /mnt /bin/bash -ex <<EOF || { echo -e "${RED}Chroot failed!${NC}"; exit 1; }

# Set English locale for chroot environment
export LANG=en_US.UTF-8

print_header "Setting timezone"
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

print_header "Configuring locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

print_header "Setting hostname"
echo "arch-macbook" > /etc/hostname

print_header "Creating user"
useradd -m -G wheel -s /bin/bash andrey
echo "andrey:$user_password" | chpasswd

print_header "Configuring sudo"
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

print_header "Enabling NetworkManager"
systemctl enable NetworkManager

print_header "Installing Wi-Fi drivers"
pacman -S --needed git base-devel --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
yay -S broadcom-wl --noconfirm
modprobe wl
echo "wl" > /etc/modules-load.d/broadcom-wl.conf
echo "blacklist brcmfmac" > /etc/modprobe.d/broadcom-wl.conf
echo "blacklist bcma" >> /etc/modprobe.d/broadcom-wl.conf

print_header "Updating initramfs"
mkinitcpio -P

print_header "Installing bootloader"
bootctl --path=/boot install

print_header "Creating bootloader config"
cat > /boot/loader/entries/arch.conf <<CONF
title Arch Linux MacBook
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=$root_part rw quiet i8042.nopnp=1
CONF

EOF

### Завершение ###
print_header "Unmounting partitions"
umount -R /mnt

echo -e "${GREEN}Installation complete!${NC}"
echo "Reboot with: reboot"
