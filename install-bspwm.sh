#!/bin/bash
# Скрипт установки окружения BSPWM для MacBook Pro 13" 2013

### Цвета для вывода в консоль ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

### Проверка прав пользователя ###
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root!${NC}" >&2
    exit 1
fi

### Основные функции ###

# Функция установки Xorg и базовых компонентов
install_xorg() {
    echo -e "${GREEN}[1/5] Installing Xorg...${NC}"
    sudo pacman -S --needed --noconfirm xorg-server xorg-xinit xorg-xsetroot xwallpaper || return 1
}

# Функция установки окружения
install_wm() {
    echo -e "${GREEN}[2/5] Installing window manager...${NC}"
    sudo pacman -S --needed --noconfirm bspwm sxhkd polybar rofi picom kitty feh || return 1
}

# Функция установки дополнительных компонентов
install_utils() {
    echo -e "${GREEN}[3/5] Installing additional utilities...${NC}"
    sudo pacman -S --needed --noconfirm \
        thunar gvfs scrot flameshot pavucontrol \
        ttf-fira-code ttf-font-awesome noto-fonts \
        network-manager-applet || return 1
}

# Функция настройки конфигурации
configure_dotfiles() {
    echo -e "${GREEN}[4/5] Configuring dotfiles...${NC}"
    
    # Создание необходимых директорий
    mkdir -p ~/.config/{bspwm,sxhkd,polybar,rofi,kitty}

    # Базовая конфигурация BSPWM
    cat > ~/.config/bspwm/bspwmrc <<'EOF'
#!/bin/sh
picom -b &
xwallpaper --zoom ~/.wallpaper.jpg &
sxhkd &
polybar main &
EOF

    # Базовая конфигурация SXHKD
    cat > ~/.config/sxhkd/sxhkdrc <<'EOF'
super + Return
    kitty

super + d
    rofi -show drun

super + shift + q
    bspc node -c

super + {_,shift + }{1-9,0}
    bspc {desktop -f,node -d} '^{1-9,10}'
EOF

    # Настройка .xinitrc
    cat > ~/.xinitrc <<'EOF'
#!/bin/sh
sxhkd &
exec bspwm
EOF

    # Установка прав
    chmod +x ~/.config/bspwm/bspwmrc
    chmod +x ~/.xinitrc
}

# Функция завершения установки
finalize() {
    echo -e "${GREEN}[5/5] Finalizing setup...${NC}"
    # Установка дефолтных обоев
    if [ ! -f ~/.wallpaper.jpg ]; then
        curl -sLo ~/.wallpaper.jpg https://unsplash.com/photos/yC-Yzbqy7PY/download?force=true
    fi
}

### Главный процесс выполнения ###
{
    install_xorg && 
    install_wm &&
    install_utils &&
    configure_dotfiles &&
    finalize
} || {
    echo -e "${RED}Error occurred during installation!${NC}" >&2
    exit 1
}

echo -e "\n${GREEN}Installation completed successfully!${NC}"
echo -e "${YELLOW}To start the environment:${NC}"
echo -e "1. Run ${YELLOW}startx${NC}"
echo -e "2. Set wallpaper with ${YELLOW}xwallpaper --zoom ~/.wallpaper.jpg${NC}"