#!/bin/bash

# filepath: /blawggy/Pelican-Pouch/debian.sh
# Pelican Panel Installation Script for Debian-based Systems
# Reference: https://pelican.dev/docs/panel/

export LANG=en_US.UTF-8

# Install Dependencies
sudo apt update
sudo apt install -y wget curl git tar unzip lsb-release gnupg2

clear

# Check for --skip-welcome flag
SKIP_WELCOME=false
for arg in "$@"; do
    [ "$arg" == "--skip-welcome" ] && SKIP_WELCOME=true && break
done

if [ "$SKIP_WELCOME" == false ]; then
    echo "Welcome to Pelican Pouch - Debian Edition"
    sleep 2
    echo ""
    echo "This script installs Pelican Panel on Debian-based systems"
    sleep 2
    echo "Requirements:"
    sleep 1
    echo "  • Fresh Debian/Ubuntu installation"
    echo "  • Root or sudo access"
    sleep 2
    echo ""
    echo -e "Developed by \e[95m\e[1mzptc\e[0m"
    sleep 1
    echo -e "Pelican is owned by \e[94m\e[1mPelican Team\e[0m"
    sleep 2
    clear
fi

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Spinner function
show_spinner() {
    local pid=$1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while [ "$(ps -p $pid -o pid=)" ]; do
        printf "\e[32m${spinstr:0:1}\e[0m\r"
        spinstr=${spinstr:1}${spinstr:0:1}
        sleep 0.1
    done
}

# Menu selection
echo -e "\e[32mSSL + Domain\e[0m | \e[33mHTTP + IP\e[0m | \e[34mInstall Wings\e[0m | \e[35mUpdate\e[0m | \e[31mUninstall\e[0m"
read -p "Select installation type (ssl/ip/wings/update/uninstall): " choice

case "$choice" in
    ssl)
        echo -e "\e[32mSSL with domain selected\e[0m"
        read -p "Enter domain name: " domain
        ;;
    ip)
        echo -e "\e[33mHTTP with IP selected\e[0m"
        ip=$(hostname -I | awk '{print $1}')
        echo "Using IP: $ip"
        ;;
    wings)
        echo -e "\e[34mInstalling Wings\e[0m"
        curl -fsSL get.docker.com | sh
        sudo systemctl enable --now docker
        sudo mkdir -p /etc/pelican /var/run/wings
        sudo curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$(uname -m | sed 's/x86_64/amd64/')"
        sudo chmod u+x /usr/local/bin/wings
        sudo systemctl enable --now wings
        echo -e "\e[32mWings installed successfully\e[0m"
        exit 0
        ;;
    update)
        echo -e "\e[35mUpdating Pelican\e[0m"
        bash -c "$(curl -fsSL https://pelican.dev/updatePanel.sh)"
        exit 0
        ;;
    uninstall)
        read -p "Confirm uninstall Pelican? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            sudo rm -rf /var/www/pelican
            sudo rm -f /etc/nginx/sites-enabled/pelican.conf
            sudo systemctl restart nginx
            echo -e "\e[32mPelican uninstalled\e[0m"
        fi
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# System updates
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install dependencies per official docs
echo "Installing dependencies..."
sudo apt install -y php8.4 php8.4-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,sqlite3,fpm}
sudo apt install -y nginx
sudo apt install -y curl git unzip tar
sudo apt install -y certbot python3-certbot-nginx

# Create Pelican directory
echo "Creating Pelican directory..."
sudo mkdir -p /var/www/pelican
cd /var/www/pelican

# Download Pelican Panel
echo "Downloading Pelican Panel..."
curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | sudo tar -xz

# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
cd /var/www/pelican && sudo COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# Remove Apache if present
sudo apt remove -y apache2

# Remove default Nginx config
sudo rm -f /etc/nginx/sites-enabled/default

# Configure Nginx
if [ "$choice" == "ssl" ]; then
    sudo certbot certonly --nginx -d "$domain"
    cat <<'EOF' | sudo tee /etc/nginx/sites-available/pelican.conf
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    root /var/www/pelican/public;
    index index.php;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
}
EOF
    DOMAIN="$domain"
elif [ "$choice" == "ip" ]; then
    cat <<'EOF' | sudo tee /etc/nginx/sites-available/pelican.conf
server {
    listen 80;
    server_name $IP;
    root /var/www/pelican/public;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
}
EOF
    IP="$ip"
fi

sudo ln -s /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
sudo systemctl restart nginx

# Set permissions
sudo chmod -R 755 /var/www/pelican/storage /var/www/pelican/bootstrap/cache
sudo chown -R www-data:www-data /var/www/pelican

# Environment setup
cd /var/www/pelican
sudo -u www-data php artisan p:environment:setup

# Install Docker
echo "Installing Docker..."
curl -fsSL get.docker.com | sh
sudo systemctl enable --now docker

# Install and enable Wings
echo "Installing Wings..."
sudo mkdir -p /etc/pelican /var/run/wings
sudo curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$(uname -m | sed 's/x86_64/amd64/')"
sudo chmod u+x /usr/local/bin/wings
sudo systemctl enable --now wings

# Setup cron jobs
(sudo crontab -u www-data -l 2>/dev/null; echo "* * * * * php /var/www/pelican/artisan schedule:run >> /dev/null 2>&1") | sudo crontab -u www-data -

clear
echo -e "\e[32mPelican Panel installed successfully!\e[0m"
[ "$choice" == "ssl" ] && echo "Access: https://$domain/installer" || echo "Access: http://$ip/installer"