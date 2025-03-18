#!/bin/bash

# Скрипт для автоматической установки Arch Linux на MacBook Pro 2013
# Пример запуска: 
# curl -sL https://raw.githubusercontent.com/arxipovdev/macbook/main/arch_macbook_install.sh | sudo bash -s -- /dev/sda5 /dev/sda1 Europe/Moscow "user_password"

# Проверка аргументов
if [ $# -ne 4 ]; then
  echo "Использование: $0 <корневой_раздел> <efi_раздел> <часовой_пояс> <пароль>"
  echo "Пример: $0 /dev/nvme0n1p3 /dev/nvme0n1p1 Europe/Moscow \"MyPass123\""
  exit 1
fi

# Параметры
ROOT_PART="$1"
EFI_PART="$2"
TIMEZONE="$3"
PASSWORD="$4"

# Монтирование
umount -R /mnt 2>/dev/null
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

# Установка базовой системы
echo "Устанавливаем пакеты..."
pacstrap /mnt base linux linux-firmware base-devel networkmanager sudo nano git

# Настройка системы
echo "Настраиваем систему..."
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
# Часовой пояс
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Локализация
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Пользователь
useradd -m -G wheel -s /bin/bash macuser
echo "macuser:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Сеть
systemctl enable NetworkManager

# Wi-Fi
pacman -S --noconfirm broadcom-wl
echo "wl" > /etc/modules-load.d/wl.conf
echo "blacklist brcmfmac" > /etc/modprobe.d/wl.conf

# Загрузчик
bootctl --path=/boot install
echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img\noptions root=$ROOT_PART rw" > /boot/loader/entries/arch.conf
EOF

echo "Установка завершена! Перезагрузитесь командой: reboot"
