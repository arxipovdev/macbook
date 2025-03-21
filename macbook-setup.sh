#!/bin/bash
# Скрипт настройки MacBook Pro 13" 2013 (Arch Linux + BSPWM)
# Запуск: curl -sL https://example.com/macbook-setup.sh | sudo bash

### Цвета для вывода ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

### Проверка прав ###
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root!${NC}" >&2
    exit 1
fi

### Функции ###
print_step() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[!] Error:${NC} $1"; exit 1; }

### 1. Установка Bluetooth ###
setup_bluetooth() {
    print_step "Configuring Bluetooth"
    sudo pacman -S --noconfirm bluez bluez-utils blueman
    sudo systemctl enable bluetooth
}

### 2. Настройка F-клавиш ###
setup_function_keys() {
    print_step "Configuring Function Keys"
    echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
    sudo mkinitcpio -P
}

### 3. Подсветка клавиатуры ###
setup_keyboard_backlight() {
    print_step "Configuring Keyboard Backlight"
    yay -S --noconfirm kbdlight
    sudo echo "ACTION==\"add\", SUBSYSTEM==\"leds\", RUN+=\"/bin/chgrp video /sys/class/leds/smc::kbd_backlight/brightness\"" | sudo tee /etc/udev/rules.d/90-kbdlight.rules
}

### 4. Управление подсветкой экрана ###
setup_display_backlight() {
    print_step "Configuring Display Backlight"
    sudo pacman -S --noconfirm light
    sudo usermod -aG video $USER
    echo "ACTION==\"add\", SUBSYSTEM==\"backlight\", RUN+=\"/bin/chgrp video /sys/class/backlight/%k/brightness\"" | sudo tee /etc/udev/rules.d/90-backlight.rules
}

### 5. Управление кулером ###
setup_fan_control() {
    print_step "Configuring Fan Control"
    yay -S --noconfirm mbpfan-git
    [ -f ./mbpfan.conf ] && sudo cp ./mbpfan.conf /etc/
    sudo systemctl enable mbpfan
}

### 6. Настройка Shadowsocks ###
setup_shadowsocks() {
    print_step "Configuring Shadowsocks"
    sudo pacman -S --noconfirm shadowsocks-libev
    [ -f ./shadowsocks_config.json ] && sudo cp ./shadowsocks_config.json /etc/shadowsocks/
    sudo systemctl enable shadowsocks-libev@shadowsocks_config
}

### Главный процесс ###
{
    setup_bluetooth && \
    setup_function_keys && \
    setup_keyboard_backlight && \
    setup_display_backlight && \
    setup_fan_control && \
    setup_shadowsocks
} || {
    print_error "Setup failed!"
    exit 1
}

echo -e "\n${GREEN}Setup completed!${NC}"
echo -e "${YELLOW}Please reboot your system to apply changes${NC}"