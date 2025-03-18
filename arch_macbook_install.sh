#!/bin/bash

# Скрипт для автоматической установки Arch Linux на MacBook Pro 2013
# Пример запуска: 
# curl -sL https://raw.githubusercontent.com/arxipovdev/macbook/main/arch_macbook_install.sh | sudo bash -s -- /dev/sda5 /dev/sda1 Europe/Moscow "user_password"

#!/bin/bash

# Скрипт автоматической установки Arch Linux на MacBook Pro 2013
# Использование:
# curl -sL https://example.com/installer.sh | sudo bash -s -- /dev/nvme0n1p3 /dev/nvme0n1p1 Europe/Moscow "пароль"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # Сброс цвета

# Обработка ошибок
set -euo pipefail

# Проверка аргументов
if [ $# -ne 4 ]; then
  echo -e "${RED}Ошибка: Необходимо указать 4 аргумента${NC}"
  echo "Порядок аргументов:"
  echo "$0 <корневой_раздел> <efi_раздел> <часовой_пояс> <пароль_пользователя>"
  echo "Пример: $0 /dev/nvme0n1p3 /dev/nvme0n1p1 Europe/Moscow \"MyPassword123\""
  exit 1
fi

# Параметры
ROOT_PART="$1"
EFI_PART="$2"
TIMEZONE="$3"
USER_PASSWORD="$4"

# Функция для вывода заголовков
print_header() {
  echo -e "\n${GREEN}>>> ${YELLOW}$1${NC}"
}

# Функция очистки
cleanup() {
  print_header "Очистка"
  umount -R /mnt 2>/dev/null || true
}

trap cleanup EXIT

### Основной процесс установки ###

loadkeys ru
setfont cyr-sun16

print_header "Монтирование разделов"
umount -R /mnt 2>/dev/null || true
mount "$ROOT_PART" /mnt || { echo -e "${RED}Ошибка монтирования корневого раздела!${NC}"; exit 1; }
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot || { echo -e "${RED}Ошибка монтирования EFI раздела!${NC}"; exit 1; }

print_header "Монтирование системных разделов"
mkdir -p /mnt/{proc,sys,dev}
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /dev /mnt/dev

print_header "Инициализация ключей Pacman"
arch-chroot /mnt /bin/bash -c "pacman-key --init && pacman-key --populate archlinux"
arch-chroot /mnt /bin/bash -c "pacman -Sy archlinux-keyring --noconfirm"

print_header "Установка базовой системы"
pacstrap /mnt base linux linux-firmware base-devel linux-headers \
          networkmanager network-manager-applet sudo efibootmgr \
          nano vim git curl dialog dosfstools mtools || { 
          echo -e "${RED}Ошибка установки пакетов!${NC}";
          exit 1; }

print_header "Создание fstab"
genfstab -U /mnt > /mnt/etc/fstab

print_header "Настройка системы"
arch-chroot /mnt /bin/bash -ex <<EOF

# Настройка времени
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# Локализация
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Имя хоста
echo "arch-macbook" > /etc/hostname

# Создание пользователя
useradd -m -G wheel -s /bin/bash andrey
echo "andrey:$USER_PASSWORD" | chpasswd

# Настройка sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Включение NetworkManager
systemctl enable NetworkManager

# Установка Wi-Fi драйверов
pacman -S --noconfirm --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
yay -S --noconfirm broadcom-wl
echo "wl" > /etc/modules-load.d/broadcom-wl.conf
echo "blacklist brcmfmac" > /etc/modprobe.d/broadcom-wl.conf
echo "blacklist bcma" >> /etc/modprobe.d/broadcom-wl.conf

# Обновление initramfs
mkinitcpio -P

# Установка загрузчика
bootctl --path=/boot install

# Конфиг загрузчика
cat > /boot/loader/entries/arch.conf <<CONF
title Arch Linux MacBook
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=$ROOT_PART rw quiet i8042.nopnp=1 pcie_ports=compat
CONF

EOF

print_header "Установка завершена!"
echo -e "${GREEN}Система успешно установлена!${NC}"
echo -e "Выполните перезагрузку:"
echo -e "umount -R /mnt"
echo -e "reboot"
