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
    if ! is_installed bluez || ! is_installed bluez-utils || ! is_installed blueman; then
        sudo pacman -S --needed --noconfirm bluez bluez-utils blueman
        sudo systemctl enable --now bluetooth
    else
        echo -e "${YELLOW}[~] Bluetooth packages already installed, skipping...${NC}"
    fi
}

### 2. Настройка F-клавиш ###
setup_function_keys() {
    print_step "Configuring Function Keys"
    if [ ! -f "/etc/modprobe.d/hid_apple.conf" ]; then
        echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
        sudo mkinitcpio -P
    else
        echo -e "${YELLOW}[~] Function keys already configured, skipping...${NC}"
    fi
}

### 3. Подсветка клавиатуры ###
setup_keyboard_backlight() {
    print_step "Configuring Keyboard Backlight"
    if ! is_installed kbdlight; then
        yay -S --noconfirm kbdlight
    fi
    if [ ! -f "/etc/udev/rules.d/90-kbdlight.rules" ]; then
        sudo tee /etc/udev/rules.d/90-kbdlight.rules >/dev/null <<EOF
ACTION=="add", SUBSYSTEM=="leds", RUN+="/bin/chgrp video /sys/class/leds/smc::kbd_backlight/brightness"
EOF
    else
        echo -e "${YELLOW}[~] Keyboard backlight rules already exist, skipping...${NC}"
    fi
}

### 4. Управление подсветкой экрана ###
setup_display_backlight() {
    print_step "Configuring Display Backlight"
    if ! is_installed brightnessctl; then
        sudo pacman -S --noconfirm brightnessctl
    fi
    if ! groups "$USER" | grep -q '\bvideo\b'; then
        sudo usermod -aG video "$USER"
    fi
    if [ ! -f "/etc/udev/rules.d/90-backlight.rules" ]; then
        sudo tee /etc/udev/rules.d/90-backlight.rules >/dev/null <<EOF
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
EOF
    else
        echo -e "${YELLOW}[~] Display backlight rules already exist, skipping...${NC}"
    fi
}

### 5. Управление кулером ###
setup_fan_control() {
    print_step "Configuring Fan Control"
    if ! is_installed mbpfan-git; then
        yay -S --noconfirm mbpfan-git
    fi
    if [ -f "./mbpfan.conf" ]; then
        sudo cp -v ./mbpfan.conf /etc/mbpfan.conf
        sudo systemctl enable --now mbpfan
    else
        print_error "mbpfan.conf not found in current directory!"
    fi
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
        sudo systemctl enable --now shadowsocks-libev@shadowsocks_config
    else
        print_error "shadowsocks_config.json not found!"
    fi
}

### 7. Настройка тачпада ###
setup_touchpad() {
    print_step "Configuring Touchpad (mtrack)"
    if ! is_installed xf86-input-mtrack; then
        sudo pacman -S --noconfirm xf86-input-mtrack
    fi
    
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/50-mtrack.conf >/dev/null <<EOF
Section "InputClass"
    MatchIsTouchpad "on"
    Identifier "Touchpad"
    Driver "mtrack"
    Option "Sensitivity" "0.5"
    Option "FingerLowThreshold" "1"
    Option "FingerHighThreshold" "5"
    Option "IgnoreThumb" "true"
    Option "IgnorePalm" "true"
    Option "TapButtonMask" "123"
    Option "TapFingersDown" "12"
    Option "ScrollCoastDuration" "500"
    Option "ScrollDistance" "50"
    Option "ScrollClickTime" "0"
    Option "ButtonMoveEmulate" "true"
    Option "ButtonIntegrated" "true"
    Option "ScrollUpButton" "4"
    Option "ScrollDownButton" "5"
    Option "ScrollLeftButton" "6"
    Option "ScrollRightButton" "7"
    # Three finger drag
    Option "ClickFinger3" "2"
    Option "TapButton3" "2"
    Option "Drag3Buttons" "1 2 3"
EndSection
EOF
    
    # Добавляем правило для работы в Wayland (если используется)
    if [ ! -f "/etc/udev/rules.d/99-touchpad.rules" ]; then
        sudo tee /etc/udev/rules.d/99-touchpad.rules >/dev/null <<EOF
ACTION=="add|change", SUBSYSTEM=="input", ATTR{name}=="*Touchpad*", ENV{ID_INPUT_TOUCHPAD}="1", ENV{LIBINPUT_IGNORE_DEVICE}="0"
EOF
    fi
}

### Главный процесс ###
{
    setup_bluetooth && \
    setup_function_keys && \
    setup_keyboard_backlight && \
    setup_display_backlight && \
    setup_fan_control && \
    setup_shadowsocks && \
    setup_touchpad
} || {
    print_error "Setup failed!"
    exit 1
}

echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}Reboot your system to apply all changes:${NC}"
echo -e "${YELLOW}sudo reboot${NC}"