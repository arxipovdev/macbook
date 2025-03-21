#!/bin/bash
# Скрипт для автоматической установки пакетов и инструментов на MacBook Pro 13" 2013 (Arch Linux + BSPWM)

### Цвета для вывода в консоль ###
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

is_installed() {
    pacman -Qs "$1" >/dev/null 2>&1
}

is_aur_installed() {
    yay -Qs "$1" >/dev/null 2>&1
}

### 1. Установка yay ###
install_yay() {
    print_step "Installing yay (AUR helper)..."
    if ! is_installed yay; then
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/yay
    fi
}

### 2. Настройка ZSH ###
configure_zsh() {
    print_step "Configuring ZSH..."
    
    if ! is_installed zsh; then
        sudo pacman -S --noconfirm zsh
    fi
    
    # Oh My ZSH
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Плагины
    plugins_dir=~/.oh-my-zsh/custom/plugins
    mkdir -p "$plugins_dir"
    
    [ ! -d "$plugins_dir/zsh-autosuggestions" ] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    
    [ ! -d "$plugins_dir/zsh-syntax-highlighting" ] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
    
    [ ! -d "$plugins_dir/zsh-history-substring-search" ] && \
        git clone https://github.com/zsh-users/zsh-history-substring-search "$plugins_dir/zsh-history-substring-search"

    # Конфиг
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)/' ~/.zshrc
}

### 3. Установка Docker ###
install_docker() {
    print_step "Configuring Docker..."
    
    if ! is_installed docker; then
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl enable docker
        sudo usermod -aG docker "$USER"
    fi
}

### 4. Установка Neovim и инструментов ###
install_neovim() {
    print_step "Setting up Neovim ecosystem..."
    
    # Основные пакеты
    for pkg in neovim fzf ripgrep fd; do
        if ! is_installed "$pkg"; then
            sudo pacman -S --noconfirm "$pkg"
        fi
    done

    # AUR-пакеты
    for aur_pkg in lazydocker lazygit; do
        if ! is_aur_installed "$aur_pkg"; then
            yay -S --noconfirm "$aur_pkg"
        fi
    done

    # LazyVim с проверкой
    if [ ! -d ~/.config/nvim ]; then
        LV_BRANCH='release-1.3/neovim-0.9'
        INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/LazyVim/starter/main/install.sh"
        
        # Проверка доступности скрипта
        if curl -fsSL --output /dev/null --silent --head --fail "$INSTALL_SCRIPT_URL"; then
            bash <(curl -fsSL "$INSTALL_SCRIPT_URL")
        else
            print_error "LazyVim install script not found! Trying alternative method..."
            git clone https://github.com/LazyVim/starter ~/.config/nvim
            rm -rf ~/.config/nvim/.git
        fi
    fi
}

### 5. Установка .NET ###
install_dotnet() {
    print_step "Installing .NET SDK..."
    
    if ! is_installed dotnet-sdk; then
        sudo pacman -S --noconfirm dotnet-sdk
        dotnet tool install --global dotnet-ef
    fi
}

### 6. Установка Node.js ###
install_nodejs() {
    print_step "Configuring Node.js environment..."
    
    # NVM
    if [ ! -d ~/.nvm ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
    fi

    # Node.js LTS
    if ! command -v node &>/dev/null; then
        source ~/.nvm/nvm.sh
        nvm install --lts
    fi

    # Менеджеры пакетов
    for pkg in npm yarn pnpm; do
        if ! is_installed "$pkg"; then
            sudo pacman -S --noconfirm npm
            sudo npm install -g yarn pnpm
            break
        fi
    done
}

### Главный процесс ###
{
    install_yay && \
    configure_zsh && \
    install_docker && \
    install_neovim && \
    install_dotnet && \
    install_nodejs
} || {
    print_error "Installation failed!"
    exit 1
}

echo -e "\n${GREEN}Installation completed successfully!${NC}"
echo -e "${YELLOW}Please reboot your system and run:${NC}"
echo -e "${YELLOW}source ~/.zshrc${NC}"