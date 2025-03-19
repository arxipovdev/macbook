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

configure_bspwm() {
    cat > ~/.config/bspwm/bspwmrc <<'EOF'
#!/bin/sh
pgrep -x sxhkd >/dev/null || sxhkd &
picom -b &
xwallpaper --zoom ~/.wallpaper.jpg &
$HOME/.config/polybar/launch.sh &
EOF
    chmod +x ~/.config/bspwm/bspwmrc
}

configure_sxhkd() {
    cat > ~/.config/sxhkd/sxhkdrc <<'EOF'
# Super/Command key (для MacBook)
super = 133

# Основные сочетания
super + Return
    kitty

super + d
    rofi -show drun

super + shift + q
    bspc node -c

# Управление окнами
super + alt + {h,j,k,l}
    bspc node -p {west,south,north,east}

super + ctrl + {h,j,k,l}
    bspc node -s {west,south,north,east}

# Рабочие столы
super + {_,shift + }{1-9,0}
    bspc {desktop -f,node -d} '^{1-9,10}'
EOF
}

configure_polybar() {
    mkdir -p ~/.config/polybar
    cat > ~/.config/polybar/config.ini <<'EOF'
[colors]
background = #2F343F
foreground = #FEFEFE
primary = #5294E2
secondary = #B8B8B8
alert = #E53935

[bar/main]
width = 100%
height = 24
radius = 0
fixed-center = true
background = ${colors.background}
foreground = ${colors.foreground}

modules-left = xworkspaces
modules-center = xwindow
modules-right = volume date

[module/xworkspaces]
type = internal/xworkspaces
pin-workspaces = false
label-active = %name%
label-active-background = ${colors.primary}
label-active-foreground = ${colors.background}
label-occupied = %name%
label-urgent = %name%!

[module/xwindow]
type = internal/xwindow
label = %title:0:50:...%

[module/volume]
type = internal/pulseaudio
format-volume = <label-volume>
label-volume = VOL %percentage%%
label-muted = 🔇 MUTED

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d%
time = %H:%M:%S
label = %date% %time%
EOF

    cat > ~/.config/polybar/launch.sh <<'EOF'
#!/bin/bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
polybar main -c ~/.config/polybar/config.ini &
EOF
    chmod +x ~/.config/polybar/launch.sh
}

### Основной процесс ###
echo -e "${GREEN}[1/4] Installing packages...${NC}"
sudo pacman -S --needed --noconfirm \
    bspwm sxhkd polybar rofi picom \
    kitty feh xorg-server xorg-xinit \
    pulseaudio pavucontrol network-manager-applet \
    ttf-fira-code ttf-font-awesome noto-fonts

echo -e "${GREEN}[2/4] Configuring BSPWM...${NC}"
mkdir -p ~/.config/{bspwm,sxhkd}
configure_bspwm
configure_sxhkd

echo -e "${GREEN}[3/4] Configuring Polybar...${NC}"
configure_polybar

echo -e "${GREEN}[4/4] Finalizing setup...${NC}"
cat > ~/.xinitrc <<'EOF'
#!/bin/sh
sxhkd &
exec bspwm
EOF

# Установка обоев по умолчанию
if [ ! -f ~/.wallpaper.jpg ]; then
    curl -sLo ~/.wallpaper.jpg https://raw.githubusercontent.com/arxipovdev/macbook/main/wallpaper.jpg
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "Start with: ${YELLOW}startx${NC}"