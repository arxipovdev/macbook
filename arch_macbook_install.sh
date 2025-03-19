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
        shift
        shift
        ;;
        -r|--root-path)
        ROOT_PART="$2"
        shift
        shift
        ;;
        -t|--timezone)
        TIMEZONE="$2"
        shift
        shift
        ;;
        -p|--password)
        USER_PASSWORD="$2"
        shift
        shift
        ;;
        *)
        echo -e "${RED}Unknown option: $1${NC}"
        exit 1
        ;;
    esac
done

### Проверка обязательных аргументов ###
if [[ -z "$BOOT_PART" || -z "$ROOT_PART" || -z "$TIMEZONE" || -z "$USER_PASSWORD" ]]; then
    echo -e "${RED}Error: Missing required arguments!${NC}"
    echo -e "Usage: ${YELLOW}$0 \\"
    echo -e "  -b|--boot-path <boot_partition> \\"
    echo -e "  -r|--root-path <root_partition> \\"
    echo -e "  -t|--timezone <timezone> \\"
    echo -e "  -p|--password <user_password>${NC}"
    echo -e "Example: ${YELLOW}$0 -b /dev/sda1 -r /dev/sda5 -t Europe/Moscow -p 'MyPass123'${NC}"
    exit 1
fi

### Функции вывода ###
print_step() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[!] Error:${NC} $1"
    exit 1
}

### Основной процесс ###
print_step "Mounting partitions"
umount -R /mnt 2>/dev/null
mount "$ROOT_PART" /mnt || print_error "Failed to mount root partition"
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot || print_error "Failed to mount boot partition"

print_step "Initializing package keys"
arch-chroot /mnt pacman-key --init 2>/dev/null
arch-chroot /mnt pacman-key --populate archlinux 2>/dev/null
arch-chroot /mnt pacman -Sy archlinux-keyring --noconfirm

print_step "Installing base system"
pacstrap /mnt base linux linux-firmware networkmanager sudo nano git base-devel || print_error "Package installation failed"

print_step "Generating fstab"
genfstab -U /mnt > /mnt/etc/fstab

print_step "Configuring system"
arch-chroot /mnt /bin/bash <<EOF
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc
echo "arch-macbook" > /etc/hostname
useradd -m -G wheel -s /bin/bash user
echo "user:$USER_PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
systemctl enable NetworkManager

echo "Installing WiFi drivers..."
pacman -S --noconfirm broadcom-wl
echo "wl" > /etc/modules-load.d/wl.conf
echo "blacklist brcmfmac" > /etc/modprobe.d/wl.conf

echo "Installing bootloader..."
bootctl --path=/boot install
cat > /boot/loader/entries/arch.conf <<CONF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=$ROOT_PART rw
CONF

mkinitcpio -P
EOF

print_step "Unmounting partitions"
umount -R /mnt

echo -e "${GREEN}Installation complete!${NC}"
echo -e "Reboot with: ${YELLOW}reboot${NC}"
