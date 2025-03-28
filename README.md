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
или

```bash
git clone https://github.com/arxipovdev/macbook.git
cd macbook
chmod +x arch_macbook_install.sh
./arch_macbook_install.sh \
    -b /dev/sda1 \          # Укажите ваш boot-раздел
    -r /dev/sda5 \          # Укажите ваш root-раздел
    -t Europe/Moscow \      # Часовой пояс
    -u andrey \             # Имя пользователя
    -p "MySecureP@ss123"    # Пароль пользователя
```
