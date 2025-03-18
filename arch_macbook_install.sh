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
  echo -e "${RED}Ошибка: Необходимо указать 4 аргумента${NC}"
  echo "Пример использования:"
  echo "$0 <root_partition> <efi_partition> <timezone> <user_password>"
  echo "Пример: $0 /dev/sda5 /dev/sda1 Europe/Moscow \"MySecureP@ss\""
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
print_header "Монтирование разделов"
umount -R /mnt 2>/dev/null
echo "Монтируем корневой раздел $root_part в /mnt"
mount "$root_part" /mnt
mkdir -p /mnt/boot
echo "Монтируем EFI-раздел $efi_part в /mnt/boot"
mount "$efi_part" /mnt/boot

print_header "Установка базовых пакетов"
pacstrap /mnt base linux linux-firmware base-devel linux-headers \
          networkmanager network-manager-applet sudo grub efibootmgr \
          nano vim neovim ranger git curl dialog

print_header "Генерация fstab"
genfstab -U /mnt >> /mnt/etc/fstab

### Настройка системы внутри chroot ###
print_header "Вход в chroot-окружение"
arch-chroot /mnt /bin/bash -ex <<EOF

print_header "Настройка времени и даты"
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

print_header "Настройка локалей"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

print_header "Настройка имени хоста"
echo "arch-macbook" > /etc/hostname

print_header "Создание пользователя"
useradd -m -G wheel -s /bin/bash andrey
echo "andrey:$user_password" | chpasswd

print_header "Настройка sudo"
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

print_header "Включение NetworkManager"
systemctl enable NetworkManager

print_header "Установка Wi-Fi драйверов"
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

print_header "Обновление initramfs"
mkinitcpio -P

print_header "Установка загрузчика"
bootctl --path=/boot install

print_header "Создание конфига загрузчика"
cat > /boot/loader/entries/arch.conf <<CONF
title Arch Linux MacBook
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=$root_part rw quiet i8042.nopnp=1
CONF

EOF

### Завершение ###
print_header "Размонтирование разделов"
umount -R /mnt

echo -e "${GREEN}Установка завершена!${NC}"
echo "Перезагрузитесь командой: reboot"
