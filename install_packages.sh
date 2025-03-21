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

### 1. Установка yay ###
install_yay() {
    print_step "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
}

### 2. Настройка ZSH ###
configure_zsh() {
    print_step "Configuring ZSH..."
    # Установка ZSH
    sudo pacman -S --noconfirm zsh
    
    # Установка Oh My ZSH
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Установка плагинов
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search
    
    # Настройка .zshrc
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)/' ~/.zshrc
    echo "export PATH=\$PATH:\$HOME/.local/bin" >> ~/.zshrc
}

### 3. Установка Docker ###
install_docker() {
    print_step "Installing Docker..."
    sudo pacman -S --noconfirm docker docker-compose
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
}

### 4. Установка Neovim и инструментов ###
install_neovim() {
    print_step "Installing Neovim ecosystem..."
    sudo pacman -S --noconfirm neovim fzf ripgrep fd
    
    # Lazy tools
    yay -S --noconfirm lazydocker lazygit
    LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LazyVim/starter/main/install.sh)
}

### 5. Установка .NET ###
install_dotnet() {
    print_step "Installing .NET SDK..."
    sudo pacman -S --noconfirm dotnet-sdk
    dotnet tool install --global dotnet-ef
}

### 6. Установка Node.js ###
install_nodejs() {
    print_step "Installing Node.js tools..."
    # NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Инициализация NVM
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
    
    # Установка LTS версии
    source ~/.nvm/nvm.sh
    nvm install --lts
    
    # Менеджеры пакетов
    sudo pacman -S --noconfirm npm
    sudo npm install -g yarn pnpm
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
echo -e "${YELLOW}Please reboot your system to apply changes.${NC}"