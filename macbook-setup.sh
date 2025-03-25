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
    print_step "Configuring Touchpad"
    
    # Установка libinput (рекомендуемый драйвер)
    if ! is_installed xf86-input-libinput; then
        sudo pacman -S --noconfirm xf86-input-libinput
    fi

    # Создание конфигурационного файла жестов
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/40-libinput.conf >/dev/null <<EOF
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    
    # Basic settings
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "AccelSpeed" "0.5"
    
    # Multi-finger gestures
    Option "ClickMethod" "clickfinger"
    Option "DisableWhileTyping" "true"
    
    # Three-finger drag (emulate middle button)
    Option "ScrollMethod" "two-finger"
    Option "HorizontalScrolling" "on"
    Option "TapButton3" "2"
EndSection
EOF

    # Настройка жестов через touchegg (для Wayland/X11)
    if ! is_installed touchegg; then
        yay -S --noconfirm touchegg
    fi
    
    mkdir -p ~/.config/touchegg
    tee ~/.config/touchegg/touchegg.conf >/dev/null <<EOF
<touchégg>
    <settings>
        <property name="animation_delay">150</property>
        <property name="action_delay">0</property>
    </settings>

    <application name="All">
        <gesture type="SWIPE" fingers="3" direction="UP">
            <action type="SEND_KEYS">Control+Alt+Up</action>
        </gesture>
        
        <gesture type="SWIPE" fingers="3" direction="DOWN">
            <action type="SEND_KEYS">Control+Alt+Down</action>
        </gesture>
        
        <gesture type="SWIPE" fingers="4" direction="LEFT">
            <action type="SEND_KEYS">Super+Left</action>
        </gesture>
        
        <gesture type="SWIPE" fingers="4" direction="RIGHT">
            <action type="SEND_KEYS">Super+Right</action>
        </gesture>
        
        <gesture type="PINCH" fingers="2" direction="IN">
            <action type="SEND_KEYS">Control+minus</action>
        </gesture>
        
        <gesture type="PINCH" fingers="2" direction="OUT">
            <action type="SEND_KEYS">Control+plus</action>
        </gesture>
    </application>
</touchégg>
EOF

    systemctl --user enable touchegg --now
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