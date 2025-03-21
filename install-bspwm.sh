#!/bin/bash
# Скрипт установки окружения BSPWM для MacBook Pro 13" 2013

### Цвета ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

### Проверка прав ###
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root!${NC}" >&2
    exit 1
fi

### Конфигурационные файлы ###

install_packages() {
    echo -e "${GREEN}[1/8] Installing packages...${NC}"
    sudo pacman -S --needed --noconfirm \
        bspwm sxhkd polybar rofi picom dunst \
        kitty feh xorg-server xorg-xinit zsh \
        pulseaudio pavucontrol network-manager-applet \
        ttf-jetbrains-mono-nerd xorg-xrandr
}

configure_fonts() {
    echo -e "${GREEN}[2/8] Configuring fonts...${NC}"
    fc-cache -fv
}

configure_zsh() {
    echo -e "${GREEN}[3/8] Configuring ZSH...${NC}"
    chsh -s /bin/zsh $USER
}

install_lemurs() {
    echo -e "${GREEN}[3/9] Installing Lemurs...${NC}"
    sudo pacman -S --noconfirm lemurs
    sudo systemctl enable lemurs.service
}

copy_configs() {
    echo -e "${GREEN}[5/8] Copying configs...${NC}"
    
    # Создание директорий
    mkdir -p ~/.config/{bspwm,sxhkd,polybar,rofi,picom,dunst}

    # Копирование конфигов из текущей директории
    cp ./bspwmrc ~/.config/bspwm/
    cp ./sxhkdrc ~/.config/sxhkd/
    cp ./polybar/* ~/.config/polybar/
    cp ./picom.conf ~/.config/picom/
    cp ./dunstrc ~/.config/dunst/
    # Копирование картинки для обоев
    cp ./wallpaper.jpg ~/.wallpaper.jpg

    chmod +x ~/.config/bspwm/bspwmrc
}

configure_rofi() {
    echo -e "${GREEN}[6/8] Configuring Rofi...${NC}"
    mkdir -p ~/.config/rofi
    cat > ~/.config/rofi/config.rasi <<'EOF'
configuration {
    modi: "drun";
    font: "JetBrains Nerd Font 12";
    theme: "everforest";
}

@theme "everforest" {
    colors {
        background: #2B3339;
        foreground: #D3C6AA;
        accent: #7FBBB3;
        urgent: #E67E80;
    }
}
EOF
}

configure_display() {
    echo -e "${GREEN}[7/8] Configuring display...${NC}"
    cat >> ~/.xinitrc <<'EOF'

# Установка разрешения
xrandr --output eDP-1 --mode 2560x1600

# Переключение раскладки
setxkbmap -layout us,ru -option grp:alt_space_toggle
EOF
}

finalize() {
    echo -e "${GREEN}[8/8] Finalizing setup...${NC}"
    cat > ~/.xinitrc <<'EOF'
#!/bin/sh
sxhkd &
dunst &
exec bspwm
EOF

    # Установка обоев по умолчанию
    if [ ! -f ~/.wallpaper.jpg ]; then
        curl -sLo ~/.wallpaper.jpg https://example.com/default-wallpaper.jpg
    fi
}

### Главный процесс ###
install_packages && \
configure_fonts && \
configure_zsh && \
install_lemurs && \
copy_configs && \
configure_rofi && \
configure_display && \
finalize

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "Start with: ${YELLOW}startx${NC}"