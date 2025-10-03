#!/usr/bin/env bash
# Ubuntu 24.04 LTS Optimized Installer for Pelican
# This script is a refined variant of Pelican_Pouch.sh focusing solely on Ubuntu 24.04 (noble)
# Safe Bash settings
set -euo pipefail
IFS=$'\n\t'

export LANG=en_US.UTF-8

#-------------- Helper Functions --------------#
show_spinner() {
  local pid=$1 delay=0.09 i=0
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while kill -0 $pid 2>/dev/null; do
    printf " %s\r" "${spin:i++%${#spin}:1}"
    sleep $delay
  done
  
  # Check exit status and display appropriate result
  if wait $pid; then
    printf " \e[32m✓\e[0m\n"
  else
    printf " \e[31m✗\e[0m\n"
  fi
}
spinner_ok() {
  local pid=$1 delay=0.09 i=0
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while kill -0 $pid 2>/dev/null; do
    printf " %s\r" "${spin:i++%${#spin}:1}"
    sleep $delay
  done
  printf " \e[32m✓\e[0m\n"
}
spinner_fail() {
  local pid=$1 delay=0.09 i=0
  local spin='⠋⠙⠹⠸⼴⠦⠧⠇⠏'
  while kill -0 $pid 2>/dev/null; do
    printf " %s\r" "${spin:i++%${#spin}:1}"
    sleep $delay
  done
  printf " \e[31m✗\e[0m\n"
}
run_with_spinner() {
  local cmd="$1"
  local success_msg="$2"
  local error_msg="$3"
  
  eval "$cmd" >/dev/null 2>&1 &
  local pid=$!
  
  if wait $pid; then
    spinner_ok $pid
    [ -n "$success_msg" ] && okay "$success_msg"
    return 0
  else
    spinner_fail $pid
    [ -n "$error_msg" ] && error_exit "$error_msg"
    return 1
  fi
}

error_exit() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; exit 1; }
info() { echo -e "\e[34m[*]\e[0m $1"; }
okay() { echo -e "\e[32m[+]\e[0m $1"; }
warn() { echo -e "\e[33m[!]\e[0m $1"; }

require_root() { [ "$EUID" -eq 0 ] || error_exit "Please run as root (sudo)."; }

# Official Docker installation using repository method
install_docker() {
    if command -v docker >/dev/null 2>&1; then
        info "Docker already installed, skipping."
        return 0
    fi
    
    info "Installing Docker via official repository"
    
    # Add Docker's official GPG key:
    (apt-get update -y >/dev/null 2>&1) & show_spinner $!
    (apt-get install -y ca-certificates curl >/dev/null 2>&1) & show_spinner $!
    install -m 0755 -d /etc/apt/keyrings
    (curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc >/dev/null 2>&1) & show_spinner $!
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    (apt-get update -y >/dev/null 2>&1) & show_spinner $!
    (apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1) & show_spinner $!
    
    systemctl enable --now docker
    okay "Docker installed successfully."
}

#-------------- Pre-flight --------------#
require_root

UBUNTU_CODENAME=$( . /etc/os-release && echo "$VERSION_CODENAME" )
if [ "$UBUNTU_CODENAME" != "noble" ]; then
    warn "This script was tailored for Ubuntu 24.04 (noble). Detected: $UBUNTU_CODENAME. Proceeding anyway."
fi

# Parse flags
SKIP_WELCOME=false
for arg in "$@"; do
  [ "$arg" == "--skip-welcome" ] && SKIP_WELCOME=true
done

if ! $SKIP_WELCOME; then
  clear
  echo "Welcome to Pelican Pouch (Ubuntu 24.04 Edition)"; sleep 1
  echo "Fresh install only. This will install dependencies, PHP, Nginx, Pelican, Wings."; sleep 1
  echo " "
  echo -e "Developed by \e[95mzptc\e[0m | Pelican owned by \e[94mPelican Team\e[0m"; sleep 2
fi

#-------------- User Choice --------------#
echo -e "\nSelect mode:"
echo -e "  \e[32mssl\e[0m  - Domain with SSL"
echo -e "  \e[33mip\e[0m   - Plain HTTP via server IP"
echo -e "  \e[34mwings\e[0m- Install only Wings"
echo -e "  \e[35mupdate\e[0m- Update Pelican panel"
echo -e "  \e[31muninstall\e[0m - Remove Pelican"
read -rp "Choice (ssl/ip/wings/update/uninstall): " choice

#-------------- Base Packages --------------#
info "Updating apt cache & installing base tools"
(apt update -y >/dev/null 2>&1) & show_spinner $!
(apt install -y ca-certificates apt-transport-https software-properties-common curl wget git unzip tar lsb-release gnupg > /dev/null 2>&1) & show_spinner $!

#-------------- Branching Operations --------------#
case "$choice" in
  update)
    info "Updating Pelican..."
    (bash -c "$(curl -fsSL https://pelican.dev/updatePanel.sh)" >/dev/null 2>&1) & show_spinner $!
    okay "Update complete."; exit 0 ;;
  uninstall)
    read -rp "Confirm uninstall Pelican? (y/N): " c; [ "${c,,}" = y ] || { warn "Canceled"; exit 0; }
    info "Removing files & services";
    rm -rf /var/www/pelican /var/lib/pelican 2>/dev/null || true
    rm -f /etc/nginx/sites-enabled/pelican.conf /etc/nginx/sites-available/pelican.conf
    systemctl disable --now pelican-queue wings 2>/dev/null || true
    rm -f /etc/systemd/system/pelican-queue.service /etc/systemd/system/wings.service
    systemctl daemon-reload
    okay "Pelican uninstalled."; exit 0 ;;
  wings)
    install_docker
    info "Installing Wings binary"
    mkdir -p /etc/pelican /var/run/wings
    ARCH=$(uname -m); [ "$ARCH" = x86_64 ] && ARCH=amd64 || ARCH=arm64
    curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_${ARCH}"
    chmod +x /usr/local/bin/wings
    cat >/etc/systemd/system/wings.service <<'EOF'
[Unit]
Description=Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pelican
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now wings
    okay "Wings installed."; exit 0 ;;
  ssl)
    read -rp "Enter domain (or 'local' / anything .local): " domain ;;
  ip)
    : ;; # handled later
  *) error_exit "Invalid choice" ;;
esac

#-------------- PHP Setup --------------#
info "Setting up PHP repositories"
# Primary: Ondrej PPA (contains multiple PHP versions). Ubuntu 24.04 may not yet have 8.4 GA—fallback logic below.
add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1 || warn "Could not add Ondrej PPA"


(apt update >/dev/null 2>&1) & show_spinner $!
PHP_TARGET=8.4
PHP_PACKAGES="php8.4 php8.4-fpm php8.4-gd php8.4-mysql php8.4-mbstring php8.4-bcmath php8.4-xml php8.4-curl php8.4-zip php8.4-intl php8.4-sqlite3"
info "Installing PHP 8.4 & extensions"
(apt install -y php8.4 php8.4-fpm php8.4-gd php8.4-mysql php8.4-mbstring php8.4-bcmath php8.4-xml php8.4-curl php8.4-zip php8.4-intl php8.4-sqlite3 >/dev/null 2>&1) & show_spinner $!

# Remove Apache if present
if dpkg -l | grep -q apache2; then
  info "Removing Apache2"
  (apt remove -y apache2 >/dev/null 2>&1) & show_spinner $!
fi

# Install Nginx & utilities
info "Installing Nginx, Composer dependencies"
(apt install -y nginx curl git unzip tar >/dev/null 2>&1) & show_spinner $!

#-------------- Pelican Panel --------------#
info "Creating application directory"
mkdir -p /var/www/pelican
info "Downloading Pelican panel"
(cd /var/www/pelican && curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | tar -xz) >/dev/null 2>&1

info "Installing Composer"
(curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer >/dev/null 2>&1) & show_spinner $!

info "Running composer install (no-dev)"
(cd /var/www/pelican && echo "yes" | sudo sudo COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader >/dev/null 2>&1) & show_spinner $!

#-------------- Nginx Config --------------#
info "Configuring Nginx"
rm -f /etc/nginx/sites-enabled/default || true

PHP_FPM_SOCK="/run/php/php${PHP_TARGET}-fpm.sock"

if [ "$choice" = "ssl" ]; then
  if [[ "$domain" == "local" || "$domain" == *.local ]]; then
     cat >/etc/nginx/sites-available/pelican.conf <<EOF
server {
    listen 80;
    server_name ${domain/localhost/127.0.0.1} $domain;
    root /var/www/pelican/public;
    index index.php;

    client_max_body_size 100m;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:${PHP_FPM_SOCK};
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
    }
}
EOF
  else
    info "Installing Certbot"
    (apt install -y certbot python3-certbot-nginx >/dev/null 2>&1) & show_spinner $!
    # Pre-create HTTP config for challenge
    cat >/etc/nginx/sites-available/pelican.conf <<EOF
server {
    listen 80;
    server_name $domain;
    root /var/www/pelican/public;
    index index.php;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php$ { fastcgi_pass unix:${PHP_FPM_SOCK}; include fastcgi_params; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; }
}
EOF
    ln -sf /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
    nginx -t && systemctl reload nginx
    certbot --nginx -d "$domain" --non-interactive --agree-tos -m admin@$domain || warn "Certbot failed; continuing with HTTP" 
    # Overwrite with hardened SSL config if cert succeeded
    if [ -f /etc/letsencrypt/live/$domain/fullchain.pem ]; then
      cat >/etc/nginx/sites-available/pelican.conf <<EOF
server_tokens off;
server { listen 80; server_name $domain; return 301 https://\$server_name\$request_uri; }
server {
  listen 443 ssl http2;
  server_name $domain;
  root /var/www/pelican/public; index index.php;
  ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
  ssl_session_cache shared:SSL:10m;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
  add_header X-Content-Type-Options nosniff;
  add_header X-Frame-Options DENY;
  add_header Referrer-Policy same-origin;
  add_header X-XSS-Protection "1; mode=block";
  add_header X-Robots-Tag none;
  client_max_body_size 100m;
  location / { try_files \$uri \$uri/ /index.php?\$query_string; }
  location ~ \.php$ { fastcgi_pass unix:${PHP_FPM_SOCK}; include fastcgi_params; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M"; }
  location ~ /\.ht { deny all; }
}
EOF
    fi
  fi
else
  # IP mode
  SERVER_IP=$(hostname -I | awk '{print $1}')
  cat >/etc/nginx/sites-available/pelican.conf <<EOF
server {
  listen 80;
  server_name $SERVER_IP;
  root /var/www/pelican/public;
  index index.php;
  client_max_body_size 100m;
  location / { try_files \$uri \$uri/ /index.php?\$query_string; }
  location ~ \.php$ { fastcgi_pass unix:${PHP_FPM_SOCK}; include fastcgi_params; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M"; }
  location ~ /\.ht { deny all; }
}
EOF
fi

ln -sf /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
nginx -t && systemctl restart nginx

#-------------- Docker & Wings --------------#
info "Installing Docker & Wings"
install_docker

mkdir -p /etc/pelican /var/run/wings
ARCH=$(uname -m); [ "$ARCH" = x86_64 ] && ARCH=amd64 || ARCH=arm64
curl -fsSL -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_${ARCH}" || error_exit "Failed downloading Wings"
chmod +x /usr/local/bin/wings

cat >/etc/systemd/system/wings.service <<'EOF'
[Unit]
Description=Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pelican
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now wings

#-------------- Application Post-Setup --------------#
info "Running Pelican environment setup"
cd /var/www/pelican || error_exit "/var/www/pelican missing"
php artisan p:environment:setup || warn "Environment setup command failed—continue manually later"

# Permissions
chown -R www-data:www-data /var/www/pelican
find /var/www/pelican/storage -type d -exec chmod 755 {} + 2>/dev/null || true
chmod -R 755 /var/www/pelican/bootstrap/cache

# Cron & queue
info "Configuring queue & scheduler"
cd /var/www/pelican || error_exit "/var/www/pelican missing"
(crontab -l -u www-data 2>/dev/null; echo "* * * * * php /var/www/pelican/artisan schedule:run >> /dev/null 2>&1") | crontab -u www-data -
echo -e "pelican-queue\nwww-data\nwww-data" | sudo php /var/www/pelican/artisan p:environment:queue-service

clear
okay "Pelican installation complete."
if [ "$choice" = "ssl" ]; then
  if [[ "$domain" == "local" || "$domain" == *.local ]]; then
    echo "Access: http://$domain/installer"
  elif [ -f /etc/letsencrypt/live/$domain/fullchain.pem ]; then
    echo "Access: https://$domain/installer"
  else
    echo "Access: http://$domain/installer (SSL failed)"
  fi
else
  echo "Access: http://$(hostname -I | awk '{print $1}')/installer"
fi
