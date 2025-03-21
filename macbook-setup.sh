#!/bin/bash
# Скрипт полной настройки MacBook Pro 13" 2013 (Arch Linux + BSPWM)
# Запуск: chmod +x macbook-setup.sh && ./macbook-setup.sh

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

is_installed() { pacman -Qs "$1" >/dev/null 2>&1; }
package_available() { pacman -Si "$1" >/dev/null 2>&1; }

### 1. Настройка Bluetooth ###
setup_bluetooth() {
    print_step "Configuring Bluetooth"
    sudo pacman -S --needed --noconfirm bluez bluez-utils blueman
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
    if ! is_installed kbdlight; then
        yay -S --noconfirm kbdlight
    fi
    sudo tee /etc/udev/rules.d/90-kbdlight.rules >/dev/null <<EOF
ACTION=="add", SUBSYSTEM=="leds", RUN+="/bin/chgrp video /sys/class/leds/smc::kbd_backlight/brightness"
EOF
}

### 4. Управление подсветкой экрана ###
setup_display_backlight() {
    print_step "Configuring Display Backlight"
    if ! is_installed light; then
        sudo pacman -S --noconfirm light
    fi
    sudo usermod -aG video "$USER"
    sudo tee /etc/udev/rules.d/90-backlight.rules >/dev/null <<EOF
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
EOF
}

### 5. Управление кулером ###
setup_fan_control() {
    print_step "Configuring Fan Control"
    if ! is_installed mbpfan-git; then
        yay -S --noconfirm mbpfan-git
    fi
    if [ -f "./mbpfan.conf" ]; then
        sudo cp -v ./mbpfan.conf /etc/mbpfan.conf
    else
        print_error "mbpfan.conf not found in current directory!"
    fi
    sudo systemctl enable mbpfan --now
}

### 6. Настройка Shadowsocks ###
setup_shadowsocks() {
    print_step "Configuring Shadowsocks"
    if ! is_installed shadowsocks-libev; then
        if package_available shadowsocks-libev; then
            sudo pacman -S --noconfirm shadowsocks-libev
        else
            yay -S --noconfirm shadowsocks-libev
        fi
    fi
    
    sudo mkdir -p /etc/shadowsocks
    if [ -f "./shadowsocks_config.json" ]; then
        sudo cp -v ./shadowsocks_config.json /etc/shadowsocks/
        sudo systemctl enable shadowsocks-libev@shadowsocks_config --now
    else
        print_error "shadowsocks_config.json not found!"
    fi
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

echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}Reboot your system to apply all changes:${NC}"
echo -e "${YELLOW}sudo reboot${NC}"