#!/bin/bash

# Скрипт для автоматической установки Arch Linux на MacBook Pro 2013
# Пример запуска: 
# curl -sL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/arxipovdev/macbook/main/arch_macbook_install.sh | sudo bash -s -- -b /dev/sda1 -r /dev/sda5 -t Europe/Moscow -p "MySecureP@ss123"

### Цвета для вывода ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # Сброс цвета

### Парсинг аргументов ###
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--boot-path)
        BOOT_PART="$2"
        shift; shift ;;
        -r|--root-path)
        ROOT_PART="$2"
        shift; shift ;;
        -t|--timezone)
        TIMEZONE="$2"
        shift; shift ;;
        -p|--password)
        USER_PASSWORD="$2"
        shift; shift ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

### Проверка аргументов ###
if [[ -z "$BOOT_PART" || -z "$ROOT_PART" || -z "$TIMEZONE" || -z "$USER_PASSWORD" ]]; then
    echo -e "${RED}Error: Missing required arguments!${NC}"
    echo -e "Usage: ${YELLOW}$0 -b <boot> -r <root> -t <tz> -p <pass>${NC}"
    echo -e "Example: ${YELLOW}$0 -b /dev/sda1 -r /dev/sda5 -t Europe/Moscow -p 'P@ssw0rd'${NC}"
    exit 1
fi

### Функции ###
print_step() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[!] Error:${NC} $1"; exit 1; }

### Решение проблемы с ключами ###
fix_key_issues() {
    print_step "Syncing system clock"
    timedatectl set-ntp true || print_error "Failed to sync time"
    
    print_step "Initializing package keys"
    pacman-key --init || print_error "Key initialization failed"
    pacman-key --populate archlinux || print_error "Key population failed"
    
    print_step "Updating archlinux-keyring"
    pacman -Sy --noconfirm archlinux-keyring || print_error "Keyring update failed"
}

### Основной процесс ###
fix_key_issues

print_step "Mounting partitions"
umount -R /mnt 2>/dev/null
mount "$ROOT_PART" /mnt || print_error "Mounting root failed"
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot || print_error "Mounting boot failed"

print_step "Installing base system"
pacstrap /mnt base linux linux-firmware networkmanager sudo git base-devel || print_error "Package install failed"

print_step "Generating fstab"
genfstab -U /mnt > /mnt/etc/fstab || print_error "Fstab generation failed"

print_step "Configuring system"
arch-chroot /mnt /bin/bash <<EOF
# Решение проблем с ключами внутри chroot
pacman-key --init
pacman-key --populate archlinux
pacman -Sy archlinux-keyring --noconfirm

# Основные настройки
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch-macbook" > /etc/hostname

# Пользователь
useradd -m -G wheel -s /bin/bash user
echo "user:$USER_PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Сеть
systemctl enable NetworkManager

# Wi-Fi
pacman -S --noconfirm broadcom-wl
echo -e "wl\nbrcmfmac\nbrcmutil" > /etc/modules-load.d/macbook.conf
echo "options brcmfmac roamoff=1" > /etc/modprobe.d/macbook.conf

# Загрузчик
bootctl --path=/boot install
cat > /boot/loader/entries/arch.conf <<CONF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=$ROOT_PART rw i8042.nopnp=1 pcie_ports=compat
CONF

mkinitcpio -P
EOF

print_step "Unmounting partitions"
umount -R /mnt

echo -e "${GREEN}Installation successful!${NC}"
echo -e "Reboot with: ${YELLOW}reboot${NC}"
