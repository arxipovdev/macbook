# macbook
Macbook установка Arch linux

пример запроса установки:
```bash
curl -sL https://raw.githubusercontent.com/arxipovdev/macbook/main/arch_macbook_install.sh | sudo bash -s -- \
  -b /dev/sda1 \
  -r /dev/sda5 \
  -t Europe/Moscow \
  -p "MySecureP@ss123"
```

1. Установи шрифт JetBrains Nerd Font, лишние не нужные убери
2. Установи dunst и возми настройки в файле dunstrc
3. Установи zsh и сделай его поумолчанию для текущего пользователя
4. Установи lemurs "https://github.com/coastalwhite/lemurs" и настрой его дня bspwm
5. Настройки для bspwm возми в текущей папке из файла bspwmrc
6. Настройки для polybar возми в текущей папке из файла polybar
7. Настройки для sxhkd возми в текущей папке из файла sxhkdrc
8. Настройки для picom возми в текущей папке из файла picom
9. Настрой сам rofi в стиле everforest (у меня нет настроек) и отдельно (не в самом скрипте) напиши какие нужно добавить правки в sxhkdrc для его работы
10. Настрой разрешение экрана для macbook pro 13 2013 (2560x1600)
11. Настрой переключение раскладки клавиатуры для macbook pro 13 2013 (ru,en) по нажатию alt+space

Напиши новый скрипт полностью автоматический с установками и настройкми для macbook pro 13 2013 arch linux bspwm и назови его install-packages.sh и сделай его исполняемым, комментарии пиши на русском, а в консоль информацию выводи на англиском как в прежнем скрипте:
1. Установи и настрой yay
2. Установи oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-substring-search и настрой их
3. Установи docker и docker-compose и настрой их, сделай доступ для любого пользователя
4. Установи и настрой neovim, fzf, ripgrep, fd, lazydocker, lazygit, lazyvim
5. Установи и настрой dotnet, dotnet ef
6. Установи и настрой nvm, nodejs, npm, yarn, pnpm


Напиши новый скрипт полностью автоматический с установками и настройкми для macbook pro 13 2013 arch linux bspwm и назови его install-packages.sh и сделай его исполняемым, комментарии пиши на русском, а в консоль информацию выводи на англиском как в прежнем скрипте: