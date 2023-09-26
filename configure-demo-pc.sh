#!/bin/bash
NGINX_CONF_FILE="/etc/nginx/sites-available/os2display-nginx.conf"

# Print usage conditions
echo "Use this script to quickly configure a pc to run the OS2Display system"
echo "Should be run AFTER ./install.sh"
echo "Only to be used for test or evaluation purposes. Not suitable for production."
echo "The script has been tested on Ubuntu Desktop 22.04 only"
sleep 2 # Sleep for people to be able to read above information.

# Load DOMAIN from .env
source .env set
DOMAIN=$COMPOSE_SERVER_DOMAIN

# Add DOMAIN to /etc/hosts
echo "Add $DOMAIN to /etc/hosts"
sudo sed -i "/127.0.0.1 $DOMAIN/d" /etc/hosts # Remove line first
sudo sed -i "\$a 127.0.0.1 $DOMAIN" /etc/hosts # Then add the line

# Mkcert
sudo apt install libnss3-tools
echo "Install mkcert"
wget  -cO   - https://dl.filippo.io/mkcert/latest?for=linux/amd64 > mkcert
sudo mv mkcert /usr/bin/mkcert
sudo chmod +x /usr/bin/mkcert
echo "Generate locally trusted certificate and key"
mkcert -install
mkcert $DOMAIN
echo "Move certificate and key to /etc/ssl"
sudo mv *.pem /etc/ssl/

# NGINX config
printf "Copying nginx.conf.example to os2display-nginx.conf\n"
sudo cp nginx.conf.example $NGINX_CONF_FILE	
printf "Updating os2display-nginx.conf\n"
  
sudo sed -i "/server_name /c\  server_name $DOMAIN" $NGINX_CONF_FILE
sudo sed -i "/ssl_certificate /c\  ssl_certificate /etc/ssl/$DOMAIN.pem" $NGINX_CONF_FILE
sudo sed -i "/ssl_certificate_key /c\  ssl_certificate_key /etc/ssl/$DOMAIN-key.pem" $NGINX_CONF_FILE


# Enable site
sudo ln -s $NGINX_CONF_FILE /etc/nginx/sites-enabled/os2display-nginx.conf
sudo systemctl restart nginx