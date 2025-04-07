#!/bin/bash

# Ensure script uses UTF-8 encoding
export LANG=en_US.UTF-8

# Clear Console
clear

# Display Welcome Message
echo "Welcome to Pelican Pouch"
sleep 2
echo " "
echo "This script will install Pelican on your server"
sleep 2
echo " "
echo "Please note that this script is meant for fresh installations only"
sleep 2
echo " "
echo "Please make sure you have the following ready:"
sleep 2
echo "A Compatible server"
sleep 2
echo "Domain name pointing to this server's IP address"
sleep 2
echo "Installed sudo package"
sleep 2
echo " "
echo "Ensure that your dns records are configured correctly before running script"
sleep 2
echo " "
echo -e "Developed by \e[95m\e[1mzptc]\e[0m"
sleep 2
echo " "
echo -e "Pelican is owned by \e[94m\e[1mPelican Team\e[0m"
sleep 2
echo " "
sleep 3
clear

# Function to show a spinner with color
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr
    if echo -e "\u280B" | grep -q "."; then
        spinstr=".oO0"  # Braille spinner
    else
        spinstr='|/-\' # ASCII spinner fallback
    fi
    local color="\e[32m" # Green color
    local reset="\e[0m"  # Reset color

    while [ "$(ps -p $pid -o pid=)" ]; do
        local temp=${spinstr#?}
        printf "${color} [%c]  ${reset}\r" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "    \r"
}

# Check if script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Collect inputs at the beginning
echo -e "\e[32mSSL and Domain\e[0m, \e[31mHTTP and IP\e[0m, \e[34mInstall Wings\e[0m, or \e[35mUpdate Pelican\e[0m"
read -p "Do you want to use SSL with a domain name, use an IP address via HTTP, install Wings, or update Pelican? (ssl/ip/wings/update): " choice
if [ "$choice" == "ssl" ]; then
    echo -e "\e[32mYou selected SSL with a domain name.\e[0m"
    read -p "Enter your domain name (or type 'local' for a local domain or '.tld' for an internal domain): " domain
    if [ "$domain" == "local" ]; then
        domain="localhost"
        echo -e "\e[33mUsing 'localhost' as the domain name for local setup.\e[0m"
    elif [[ "$domain" == *".local" ]]; then
        echo -e "\e[33mUsing '$domain' as the internal domain name.\e[0m"
        
    fi
elif [ "$choice" == "ip" ]; then
    echo -e "\e[31mYou selected HTTP with an IP address.\e[0m"
elif [ "$choice" == "wings" ]; then
    echo -e "\e[34mYou selected to install Wings.\e[0m"
    echo "Installing Docker..."
    curl -sSL https://get.docker.com/ | CHANNEL=stable sudo sh
    sudo systemctl enable --now docker
    echo "Installing Wings..."
    sudo mkdir -p /etc/pelican /var/run/wings
    sudo curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    sudo chmod u+x /usr/local/bin/wings
    echo "Daemonizing Wings..."
    cat <<EOF | sudo tee /etc/systemd/system/wings.service
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
    sudo systemctl enable --now wings
    echo -e "\e[32mWings has been successfully installed and daemonized.\e[0m"
    exit 0
elif [ "$choice" == "update" ]; then
    echo -e "\e[35mYou selected to update Pelican.\e[0m"
    cd /var/www/pelican
    php artisan down
    echo "Updating Pelican..."
    (sudo curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | sudo tar -xzv > /dev/null 2>&1) & show_spinner $!
    (sudo chmod -R 755 storage/* bootstrap/cache > /dev/null 2>&1) & show_spinner $!
    (sudo COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader > /dev/null 2>&1) & show_spinner $!
    (php artisan view:clear && php artisan config:clear > /dev/null 2>&1) & show_spinner $!
    (php artisan filament:optimize > /dev/null 2>&1) & show_spinner $!
    (php artisan migrate --seed --force > /dev/null 2>&1) & show_spinner $!
    (sudo chown -R www-data:www-data /var/www/pelican > /dev/null 2>&1) & show_spinner $!
    (php artisan queue:restart > /dev/null 2>&1) & show_spinner $!
    (sudo php artisan up > /dev/null 2>&1) & show_spinner $!
    echo -e "\e[32mPelican has been successfully updated.\e[0m"
    exit 0
else
    echo -e "\e[31mInvalid choice. Exiting.\e[0m"
    exit 1
fi

# Detect if package manager is yum or apt-get
if command -v yum &> /dev/null; then
    PACKAGE_MANAGER="yum"
elif command -v apt-get &> /dev/null; then
    PACKAGE_MANAGER="apt-get"
else
    echo "Neither yum nor apt-get found"
    exit 1
fi

# Install PHP and required extensions
echo "Installing PHP and required extensions"
if [ "$PACKAGE_MANAGER" == "yum" ]; then
    (sudo yum install -y epel-release > /dev/null 2>&1) & show_spinner $!
    (sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm > /dev/null 2>&1) & show_spinner $!
    (sudo yum install -y yum-utils > /dev/null 2>&1) & show_spinner $!
    (sudo yum-config-manager --enable remi-php83 > /dev/null 2>&1) & show_spinner $!
    (sudo yum install -y php php-gd php-mysql php-mbstring php-bcmath php-xml php-curl php-zip php-intl php-sqlite3 php-fpm > /dev/null 2>&1) & show_spinner $!
    (sudo yum install -y curl git unzip tar > /dev/null 2>&1) & show_spinner $!
    (sudo yum install -y nginx > /dev/null 2>&1) & show_spinner $!
    (sudo yum update -y > /dev/null 2>&1) & show_spinner $!
elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
    (sudo apt update > /dev/null 2>&1) & show_spinner $!
    (sudo apt install -y ca-certificates apt-transport-https software-properties-common wget > /dev/null 2>&1) & show_spinner $!
    (wget -qO - https://packages.sury.org/php/apt.gpg | sudo tee /etc/apt/trusted.gpg.d/sury-php.gpg > /dev/null 2>&1) & show_spinner $!
    (echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list > /dev/null 2>&1) & show_spinner $!
    (sudo apt-get update > /dev/null 2>&1) & show_spinner $!
    (sudo apt-get install -y php8.3 php8.3-gd php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl php8.3-zip php8.3-intl php8.3-sqlite3 php8.3-fpm > /dev/null 2>&1) & show_spinner $!
    (sudo apt-get install -y curl git unzip tar > /dev/null 2>&1) & show_spinner $!
    (sudo apt-get install -y nginx > /dev/null 2>&1) & show_spinner $!
else
    echo "Neither yum nor apt-get found"
    exit 1
fi
clear

# Create Pelican directory
echo "Creating Pelican directory..."
(sudo mkdir -p /var/www/pelican > /dev/null 2>&1) & show_spinner $!
clear

# Install Pelican inside the Pelican directory
echo "Installing Pelican..."
(cd /var/www/pelican && curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | sudo tar -xzv > /dev/null 2>&1) & show_spinner $!
clear

# Install Docker with Docker Compose Plugin
echo "Installing Composer..."
(curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1) & show_spinner $!
(cd /var/www/pelican && echo "yes" | sudo composer install --no-dev --optimize-autoloader > /dev/null 2>&1) & show_spinner $!
clear

# Check if apache2 is installed and remove it
echo "Checking and removing Apache2 if installed..."
if [ "$PACKAGE_MANAGER" == "yum" ]; then
    (yum list installed "httpd" &> /dev/null && sudo yum remove -y httpd > /dev/null 2>&1) & show_spinner $!
elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
    (dpkg -l | grep -q apache2 && sudo apt-get remove -y apache2 > /dev/null 2>&1) & show_spinner $!
fi
clear

# Remove Default Nginx Configuration
echo "Removing default Nginx configuration..."
(sudo rm /etc/nginx/sites-enabled/default > /dev/null 2>&1) & show_spinner $!
clear

# Install Certbot and configure SSL if chosen
if [ "$choice" == "ssl" ]; then
    echo "Installing Certbot and configuring SSL..."
    if [ "$PACKAGE_MANAGER" == "yum" ]; then
        (sudo yum install -y certbot python3-certbot-nginx > /dev/null 2>&1) & show_spinner $!
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        (sudo apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1) & show_spinner $!
    fi
    (sudo certbot --nginx -d $domain > /dev/null 2>&1) & show_spinner $!
    cat <<EOF | sudo tee /etc/nginx/sites-available/pelican.conf
server_tokens off;

server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    root /var/www/pelican/public;
    index index.php;

    access_log /var/log/nginx/pelican.app-access.log;
    error_log  /var/log/nginx/pelican.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
elif [ "$choice" == "ip" ]; then
    ip=$(hostname -I | awk '{print $1}')
    cat <<EOF | sudo tee /etc/nginx/sites-available/pelican.conf
server {
    listen 80;
    server_name $ip;

    root /var/www/pelican/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pelican.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
else
    echo "Invalid choice. Exiting."
    exit 1
fi
clear

# Enable Configuration
echo "Enabling Nginx configuration..."
(sudo ln -s /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf > /dev/null 2>&1) & show_spinner $!
clear

# Restart Nginx
echo "Restarting Nginx..."
(sudo systemctl restart nginx > /dev/null 2>&1) & show_spinner $!
clear

# Install Docker
curl -sSL https://get.docker.com/ | CHANNEL=stable sudo sh
sudo systemctl enable --now docker
sleep 2
clear

# Create .env file and generate key
# Navigate to the Pelican directory and run the command
cd /var/www/pelican
php artisan p:environment:setup
clear

# Setting permissions
sudo chmod -R 755 storage/* bootstrap/cache/
sudo chown -R www-data:www-data /var/www/pelican
clear

# Restart Nginx
echo "Restarting Nginx..."
(sudo systemctl restart nginx > /dev/null 2>&1) & show_spinner $!
clear

# Installing Wings
sudo mkdir -p /etc/pelican /var/run/wings
sudo curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
sudo chmod u+x /usr/local/bin/wings
clear

# Daemonize Wings
cat <<EOF | sudo tee /etc/systemd/system/wings.service
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
clear

# Enable Wings Service
sudo systemctl enable --now wings
clear

# Automatically enter queue workers and crontab
(crontab -l -u www-data 2>/dev/null; echo "* * * * * php /var/www/pelican/artisan schedule:run >> /dev/null 2>&1") | crontab -u www-data -

echo -e "pelican-queue\nwww-data\nwww-data" | sudo php /var/www/pelican/artisan p:environment:queue-service

# Clear console and display success message alongside website URL
clear
echo "Pelican has been successfully installed."
if [ "$choice" == "ssl" ]; then
    echo "You can access your website at https://$domain/installer"
elif [ "$choice" == "ip" ]; then
    echo "You can access your website at http://$ip/installer"
fi
