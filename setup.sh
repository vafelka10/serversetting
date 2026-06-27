#!/bin/bash

# ================================================
#   VPN Node Setup Script (Debian)
#   Порядок: обновление → curl → swap → SSH → ufw → 3x-ui
# ================================================

set -e

# --- Цвета ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# ================================================
# 1. Обновление системы
# ================================================
log "Обновление системы..."
apt update && apt upgrade -y
apt install -y curl ufw

# ================================================
# 2. Файл подкачки 3 ГБ
# ================================================
if [ ! -f /swapfile ]; then
    log "Создание swap 3GB..."
    fallocate -l 3G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    log "Swap создан."
else
    warn "Swap уже существует, пропускаю."
fi

# ================================================
# 3. Смена SSH порта
# ================================================
read -p "Введи новый SSH порт (например 2222): " SSH_PORT
 
sed -i "s/^#\?Port [0-9]*/Port $SSH_PORT/" /etc/ssh/sshd_config
 
systemctl restart ssh || systemctl restart sshd
log "SSH порт изменён на $SSH_PORT"
warn "Не закрывай текущую сессию! Проверь подключение на новом порту."

# ================================================
# 4. Настройка UFW
# ================================================
log "Настройка firewall..."
ufw allow $SSH_PORT/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
log "UFW активирован."

# ================================================
# 5. Установка 3x-ui
# ================================================
log "Установка 3x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# ================================================
# 6. Открыть порт панели в UFW
# ================================================
read -p "Введи порт панели 3x-ui который ты указал при установке: " PANEL_PORT
ufw allow $PANEL_PORT/tcp
log "Порт $PANEL_PORT открыт в UFW."

# ================================================
# Готово
# ================================================
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Установка завершена!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "SSH порт:   $SSH_PORT"
echo "Панель:     http://$(curl -s ifconfig.me):$PANEL_PORT"
echo "Swap:       $(free -h | grep Swap)"
echo ""
warn "Не забудь проверить подключение по SSH на порту $SSH_PORT"
