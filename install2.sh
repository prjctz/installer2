#!/bin/bash

#bash <(wget -qO- https://raw.githubusercontent.com/USER/REPO/main/install.sh) --port=443 --ip=203.0.113.10 --domain=google.com --user=user

#set -euo pipefail
#set -e

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

show_help() {
  cat <<'EOF'
Использование:
  ./script.sh [ПАРАМЕТРЫ]

Параметры:
  --port=PORT         Порт прокси. По умолчанию: 443
  --ip=IP             Внешний IP сервера. По умолчанию определяется автоматически
  --domain=DOMAIN     Домен для Fake-TLS. По умолчанию: github.com
  --user=NAME         Имя пользователя прокси. По умолчанию: user
  --help              Показать эту справку

Примеры:
  ./script.sh
  ./script.sh --port=443
  ./script.sh --ip=203.0.113.10 --domain=google.com
  ./script.sh --port=8443 --ip=203.0.113.10 --domain=google.com --user=user

Примечания:
  - Параметры можно передавать в любом порядке
  - Формат параметров: только --имя=значение
  - Если параметр передан несколько раз, будет использовано последнее значение
EOF
}

show_error() {
  echo "Ошибка: $1" >&2
  echo >&2
  show_help >&2
  exit 1
}

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl
fi

FAKE_DOMAIN="github.com"
#SERVER_IP="111.222.333.444"
SERVER_IP=$(curl -fsSL https://api.ipify.org || curl -fsSL https://ifconfig.me || curl -fsSL https://checkip.amazonaws.com)
PORT=443
PROXY_USER="user"


#разбор аргументов
for arg in "$@"; do
  case "$arg" in
    --help)
      show_help
      exit 0
      ;;
    --port=*)
      PORT="${arg#*=}"
      ;;
    --ip=*)
      SERVER_IP="${arg#*=}"
      ;;
    --domain=*)
      FAKE_DOMAIN="${arg#*=}"
      ;;
    --user=*)
      PROXY_USER="${arg#*=}"
      ;;
    *)
      show_error "Неизвестный параметр: $arg"
      ;;
  esac
done

[[ -n "$PORT" ]] || show_error "Порт не может быть пустым"
[[ -n "$SERVER_IP" ]] || show_error "IP не может быть пустым"
[[ -n "$FAKE_DOMAIN" ]] || show_error "Домен не может быть пустым"
[[ -n "$PROXY_USER" ]] || show_error "Имя пользователя не может быть пустым"

echo -e "\033[1;32m"
cat << "EOF"
• ▌ ▄ ·. ▄▄▄▄▄ ▄▄▄·▄▄▄        ▐▄• ▄  ▄· ▄▌
·██ ▐███▪•██  ▐█ ▄█▀▄ █·▪      █▌█▌▪▐█▪██▌
▐█ ▌▐▌▐█· ▐█.▪ ██▀·▐▀▀▄  ▄█▀▄  ·██· ▐█▌▐█▪
██ ██▌▐█▌ ▐█▌·▐█▪·•▐█•█▌▐█▌.▐▌▪▐█·█▌ ▐█▀·.
▀▀  █▪▀▀▀ ▀▀▀ .▀   .▀  ▀ ▀█▄▀▪•▀▀ ▀▀  ▀ • 
EOF
echo -e "\033[0m"

echo -e "\033[1;32mПротестировано на Debian 12 на чистом серваке\033[0m"
echo -e "\033[1;32mУстановлю докер и в нем telemt из официального репозитория\033[0m"
echo -e "\033[1;32mУстановлю сразу все варианты прокси, выдам список в конце установки\033[0m"
echo -e "\033[1;32mОткрою локальный порт для запуска команд и дам инструкции по созданию пользователей с лимитами\033[0m"
echo -e "\033[1;31mЧтобы продолжить, нажмите Enter...\033[0m"
read && echo
#exit 1

wait_for_apt() {
  echo "Жду освобождения apt, он занят потому что сервер новый..."
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    sleep 3
  done
}

wait_for_apt
dpkg --configure -a

apt-get update && apt-get install -y curl xxd jq
apt-get install -y cron
systemctl enable --now cron
#curl -fsSL https://get.docker.com | sh
apt-get install -y docker.io
systemctl enable --now docker
docker --version
#apt install build-essential -y
#curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#source $HOME/.cargo/env

#отрубаю ipv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

for iface in /proc/sys/net/ipv6/conf/*/disable_ipv6; do
  echo 1 > "$iface"
done

CONF="/etc/sysctl.d/99-disable-ipv6.conf"

cat > "$CONF" <<EOF
# Disable IPv6 (managed by script)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

sysctl --system

#

echo "FAKE_DOMAIN=$FAKE_DOMAIN"
echo "SERVER_IP=$SERVER_IP"
echo "PORT=$PORT"
echo "PROXY_USER=$PROXY_USER"

SECRET=$(head -c 16 /dev/urandom | xxd -ps -c 32 | tr -d '\n')

mkdir -p /etc/telemt

cat > /etc/telemt/telemt.toml <<EOF
log_level = "normal"

[general]
use_middle_proxy = false

[general.modes]
classic = true
secure = true
tls = true

[general.links]
show = "*"

[server]
port = ${PORT}

[server.api]
enabled = true
listen = "0.0.0.0:9091"
whitelist = ["127.0.0.1/32", "::1/128", "172.16.0.0/12", "172.17.0.0/16", "172.18.0.0/16", "192.168.0.0/16"]

[censorship]
tls_domain = "${FAKE_DOMAIN}"
mask = true
tls_emulation = true
tls_front_dir = "tlsfront"

[access.users]
${PROXY_USER} = "${SECRET}"
EOF


#создаём временную директорию с рандомными цифрами
TEMP="/tmp/mtproxy_$(tr -dc '0-9' </dev/urandom | head -c 8)"
mkdir -p "$TEMP"

#не тянет слабый сервер компиляцию
#cat > "$TEMP/Dockerfile" <<'EOF'
#FROM debian:12-slim AS builder

#RUN apt-get update && apt-get install -y \
#    git curl build-essential
#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#ENV PATH="/root/.cargo/bin:${PATH}"

#WORKDIR /opt

#RUN git clone https://github.com/telemt/telemt \
# && cd telemt \
# && cargo build --release

#пересобираю в меньший размер

#FROM debian:12-slim

#RUN apt-get update && apt-get install -y ca-certificates curl \
# && rm -rf /var/lib/apt/lists/*

#WORKDIR /opt/telemt

#COPY --from=builder /opt/telemt/target/release/telemt /opt/telemt/telemt

#RUN chmod +x /opt/telemt/telemt

#CMD ["/opt/telemt/telemt", "/etc/telemt/telemt.toml"]
#EOF

cat > "$TEMP/Dockerfile" <<'EOF'
FROM debian:12-slim

RUN apt-get update && apt-get install -y ca-certificates curl wget procps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/telemt

#RUN wget -qO- "https://github.com/telemt/telemt/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz
RUN wget -qO- "https://github.com/telemt/telemt/releases/download/3.3.24/telemt-x86_64-linux-gnu.tar.gz" | tar -xz

RUN chmod +x /opt/telemt/telemt

CMD ["/opt/telemt/telemt", "/etc/telemt/telemt.toml"]
EOF


docker build -t telemt "$TEMP"

docker rm -f telemt 2>/dev/null || true

#docker run -d \
#  --name telemt \
#  --network host \
#  -e PORT="$PORT" \
#  -e PROXY_USER="$PROXY_USER" \
#  -p "$PORT:$PORT" \
#  --restart unless-stopped \
#  telemt

docker run -d \
  --name telemt \
  -p 0.0.0.0:$PORT:$PORT \
  -p 127.0.0.1:9091:9091 \
  -v /etc/telemt/telemt.toml:/etc/telemt/telemt.toml:ro \
  --restart unless-stopped \
  telemt


rm -rf "$TEMP"

echo "Ждем 10 сек"
sleep 10

docker inspect -f '{{.State.Status}}' telemt 2>/dev/null | grep -q running \
  || show_error "Докер не запустился"

#curl -s http://127.0.0.1:9091/v1/users | jq

echo "${RED}Установка завершена!${NC}"
curl -s http://127.0.0.1:9091/v1/users \
| jq -r --arg ip "$SERVER_IP" '
  [.data[].links[][]
   | select(test("server=::") | not)
   | gsub("server=[^&]+"; "server=" + $ip)
  ] | unique[]
'

echo "${GREEN}На сервере ты можешь подключить метрики, выдавать лимитированные конфиги${NC}"
echo "${GREEN}Читай доки тут: https://github.com/telemt/telemt${NC}"
echo "${GREEN}Конфиг лежит тут /etc/telemt/telemt.toml: ${NC}"
echo "${GREEN}После правок рестарт: docker restart telemt${NC}"
echo "${GREEN}Примеры запросов:${NC}"

cat <<EOF
${YELLOW}Инфа о пользователях:${NC}

curl -s http://127.0.0.1:9091/v1/users | jq

${YELLOW}Создать нового пользователя bob с лимитом:${NC}

curl -X PATCH http://127.0.0.1:9091/v1/users/bob \
  -H "Content-Type: application/json" \
  -d '{
    "max_tcp_conns": 5,
    "max_unique_ips": 2
  }'

${YELLOW}Статистика пользователя bob:${NC}

curl -s http://127.0.0.1:9091/v1/stats/bob | jq

${YELLOW}Общая статистика:${NC}

curl -s http://127.0.0.1:9091/v1/stats/summary | jq

EOF


