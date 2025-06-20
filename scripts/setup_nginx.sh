#!/usr/bin/env bash
set -euo pipefail

# Check if DOMAIN is set
if [[ -z "${DOMAIN:-}" ]]; then
  echo "ERROR: DOMAIN is not set in .env"
  exit 1
fi


# Check if DOMAIN is set
if [[ -z "${EMAIL:-}" ]]; then
  echo "ERROR: DOMAIN is not set in .env"
  exit 1
fi

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

echo "Setting up Nginx server"

echo "Installing Nginx and Certbot"
sudo apt-get update
sudo apt-get install -y nginx python3-certbot-nginx

echo "Creating nginx config for $DOMAIN at $NGINX_CONF"

  sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    location / {
        default_type text/plain;
        return 200 'hello world! ';
    }
}
EOF

# Adding UFW rules
echo "Allowing http and https traffic through UFW"
sudo ufw allow http   # 80
sudo ufw allow https  # 443

# Enable site
echo "Enabling Nginx config: $NGINX_CONF"
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx


# Run certbot to configure SSL
echo "Requesting SSL certificate for $DOMAIN..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"